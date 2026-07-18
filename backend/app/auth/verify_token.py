from fastapi import Depends, HTTPException, Request
from fastapi.security import HTTPBearer, HTTPAuthorizationCredentials
import firebase_admin.auth

security = HTTPBearer()

async def verify_token(request: Request, credentials: HTTPAuthorizationCredentials = Depends(security)):
    """
    Verifies the Firebase ID token in the Authorization header.
    Raises 401 if missing, invalid, or expired.
    Attaches the decoded uid to request.state.uid for downstream logging.
    """
    token = credentials.credentials
    try:
        # Allow 60s of clock drift between the mobile device and the Docker container
        decoded_token = firebase_admin.auth.verify_id_token(token, clock_skew_seconds=60)
        # Attach user info to request state so downstream handlers can log who did what
        request.state.uid = decoded_token.get("uid")
        request.state.email = decoded_token.get("email")
        return decoded_token
    except Exception as e:
        import traceback
        traceback.print_exc()
        print(f"Token verification failed with Exception: {type(e).__name__}: {e}")
        raise HTTPException(
            status_code=401,
            detail=f"Invalid or expired authentication token: {e}"
        )
