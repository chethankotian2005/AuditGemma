import firebase_admin
from firebase_admin import auth, credentials
import google.auth.credentials

class DummyGoogleCred(google.auth.credentials.Credentials):
    def refresh(self, request):
        pass

class DummyFirebaseCred(credentials.Base):
    def get_credential(self):
        return DummyGoogleCred()

app = firebase_admin.initialize_app(credential=DummyFirebaseCred(), options={'projectId': 'auditgemma-ca1bb'}, name='test_dummy_app2')

try:
    auth.verify_id_token('test', app=app)
except Exception as e:
    print("Exception type:", type(e).__name__)
    print("Exception msg:", e)
