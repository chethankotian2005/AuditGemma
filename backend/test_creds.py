import firebase_admin
from firebase_admin import auth, credentials
import google.auth.credentials

class MockCreds(google.auth.credentials.Credentials):
    def refresh(self, request):
        pass

firebase_admin.initialize_app(MockCreds(), options={'projectId': 'auditgemma-ca1bb'})
try:
    auth.verify_id_token('test_token')
except Exception as e:
    print(f"Exception: {type(e).__name__}: {e}")
