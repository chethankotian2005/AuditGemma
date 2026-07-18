"""
Firestore and FCM client wrapper.
Replaces the in-memory CASE_STORE with a persistent database.
"""
import firebase_admin
from firebase_admin import credentials, firestore, messaging
from app.config import settings
import logging

logger = logging.getLogger(__name__)

# Initialize Firebase App
_db = None
if settings.FIREBASE_SERVICE_ACCOUNT_PATH:
    try:
        cred = credentials.Certificate(settings.FIREBASE_SERVICE_ACCOUNT_PATH)
        firebase_admin.initialize_app(cred)
        _db = firestore.client()
        logger.info("Firebase initialized successfully.")
    except Exception as e:
        logger.error(f"Failed to initialize Firebase: {e}")
else:
    logger.warning("FIREBASE_SERVICE_ACCOUNT_PATH not set. Initializing Firebase for token verification only (no Firestore).")
    try:
        import google.auth.credentials
        from firebase_admin import credentials as fa_credentials
        
        class DummyGoogleCred(google.auth.credentials.Credentials):
            def refresh(self, request): pass
            
        class DummyFirebaseCred(fa_credentials.Base):
            def get_credential(self): return DummyGoogleCred()
            
        firebase_admin.initialize_app(
            credential=DummyFirebaseCred(), 
            options={"projectId": settings.FIREBASE_PROJECT_ID}
        )
    except Exception as e:
        logger.error(f"Failed to initialize Firebase for token verification: {e}")

def get_db():
    return _db

_LOCAL_STORE = {}
_LOCAL_AUDIT_LOG = []

def save_case(case_id: str, data: dict):
    """Save a new case to Firestore or local memory."""
    db = get_db()
    if db:
        db.collection("cases").document(case_id).set(data)
    else:
        logger.warning(f"Firestore not initialized. Saving case {case_id} to in-memory store.")
        _LOCAL_STORE[case_id] = data

def get_case(case_id: str) -> dict:
    """Retrieve a case from Firestore or local memory."""
    db = get_db()
    if db:
        doc = db.collection("cases").document(case_id).get()
        if doc.exists:
            return doc.to_dict()
        return None
    else:
        return _LOCAL_STORE.get(case_id)

def list_cases() -> list:
    """List all cases from Firestore or local memory."""
    db = get_db()
    cases = []
    if db:
        docs = db.collection("cases").stream()
        for doc in docs:
            case_data = doc.to_dict()
            cases.append({
                "case_id": doc.id,
                "status": case_data.get("status"),
                "score": case_data.get("score_result", {}).get("score")
            })
    else:
        for cid, case_data in _LOCAL_STORE.items():
            cases.append({
                "case_id": cid,
                "status": case_data.get("status"),
                "score": case_data.get("score_result", {}).get("score")
            })
    return cases

def update_case_status(case_id: str, status: str, updated_at: str):
    """Update the status of an existing case."""
    db = get_db()
    if db:
        db.collection("cases").document(case_id).update({
            "status": status,
            "updated_at": updated_at
        })
    elif case_id in _LOCAL_STORE:
        _LOCAL_STORE[case_id]["status"] = status
        _LOCAL_STORE[case_id]["updated_at"] = updated_at

def append_audit_log(case_id: str, officer_uid: str, action: str, previous_status: str, new_status: str, timestamp: str):
    """Append a log entry to the audit_log collection."""
    db = get_db()
    log_entry = {
        "case_id": case_id,
        "officer_uid": officer_uid,
        "action": action,
        "previous_status": previous_status,
        "new_status": new_status,
        "timestamp": timestamp
    }
    if db:
        db.collection("audit_log").add(log_entry)
    else:
        _LOCAL_AUDIT_LOG.append(log_entry)

def get_audit_log(case_id: str) -> list:
    """Retrieve the audit log for a specific case, ordered by timestamp."""
    db = get_db()
    logs = []
    if db:
        docs = db.collection("audit_log").where("case_id", "==", case_id).order_by("timestamp").stream()
        for doc in docs:
            logs.append(doc.to_dict())
    else:
        logs = [log for log in _LOCAL_AUDIT_LOG if log["case_id"] == case_id]
        logs.sort(key=lambda x: x["timestamp"])
    return logs

def send_new_case_notification(case_id: str, score: int):
    """Send an FCM push notification to the 'officer_alerts' topic."""
    if not get_db():
        return
    
    try:
        message = messaging.Message(
            notification=messaging.Notification(
                title="New Case Assigned",
                body=f"Case {case_id[:8]} is ready for review. Score: {score}"
            ),
            data={
                "case_id": case_id,
                "type": "new_case"
            },
            topic="officer_alerts"
        )
        response = messaging.send(message)
        logger.info(f"Successfully sent FCM message: {response}")
    except Exception as e:
        logger.error(f"Failed to send FCM message: {e}")
