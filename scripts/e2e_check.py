import os
import sys
import time
import requests
from dotenv import load_dotenv

load_dotenv()

# Assuming default FastAPI port
BASE_URL = "http://localhost:8000/api/v1"
SAMPLE_IMAGE = "../sample_data/case_4_borderline_invoice.png"

def print_status(step, status, message=""):
    color = "\033[92m" if status == "PASS" else "\033[91m"
    reset = "\033[0m"
    print(f"[{color}{status}{reset}] {step} {message}")

def get_test_token():
    api_key = os.getenv("FIREBASE_API_KEY") or os.getenv("NEXT_PUBLIC_FIREBASE_API_KEY")
    email = os.getenv("TEST_USER_EMAIL")
    password = os.getenv("TEST_USER_PASSWORD")

    if not all([api_key, email, password]):
        print_status("AUTH", "FAIL", "- Missing FIREBASE_API_KEY, TEST_USER_EMAIL, or TEST_USER_PASSWORD in .env")
        sys.exit(1)
        
    url = f"https://identitytoolkit.googleapis.com/v1/accounts:signInWithPassword?key={api_key}"
    payload = {
        "email": email,
        "password": password,
        "returnSecureToken": True
    }
    
    try:
        resp = requests.post(url, json=payload)
        resp.raise_for_status()
        return resp.json()["idToken"]
    except Exception as e:
        print_status("AUTH", "FAIL", f"- Failed to authenticate test user: {e}")
        if 'resp' in locals() and hasattr(resp, 'text'):
            print(resp.text)
        sys.exit(1)

def run_e2e():
    print("==================================================")
    print("   AuditGemma End-to-End Environment Check")
    print("==================================================\n")

    print("Authenticating test user...")
    token = get_test_token()
    auth_headers = {"Authorization": f"Bearer {token}"}
    print_status("AUTH", "PASS", "- Obtained Firebase ID token\n")

    # Check if sample image exists
    img_path = os.path.join(os.path.dirname(__file__), SAMPLE_IMAGE)
    if not os.path.exists(img_path):
        print_status("PRE-FLIGHT", "FAIL", f"- Sample image not found at {img_path}")
        sys.exit(1)

    # STEP 1: EXTRACT
    print("Running Stage 1 (Extraction)...")
    extracted_doc = None
    try:
        with open(img_path, 'rb') as f:
            files = {'file': ('invoice.png', f, 'image/png')}
            resp = requests.post(f"{BASE_URL}/extract", files=files)
            
        if resp.status_code == 200:
            extracted_doc = resp.json()
            if "amounts" in extracted_doc:
                print_status("STEP 1: /extract", "PASS")
            else:
                print_status("STEP 1: /extract", "FAIL", "- Missing 'amounts' in response JSON")
                sys.exit(1)
        else:
            print_status("STEP 1: /extract", "FAIL", f"- HTTP {resp.status_code}: {resp.text}")
            sys.exit(1)
    except requests.exceptions.ConnectionError:
        print_status("STEP 1: /extract", "FAIL", "- Connection refused. Is the backend running on port 8000?")
        sys.exit(1)

    # STEP 2: SCORE
    print("\nRunning Stage 2 & 3 (Scoring and Reasoning)...")
    case_id = None
    try:
        payload = {
            "documents": [extracted_doc],
            "business_context": "Seasonal Agro-exporter, Kerala, Q4 seasonal equipment buying expected."
        }
        resp = requests.post(f"{BASE_URL}/score", json=payload, headers=auth_headers)
        
        if resp.status_code == 200:
            score_data = resp.json()
            if "case_id" in score_data and "score" in score_data:
                case_id = score_data["case_id"]
                print_status("STEP 2: /score  ", "PASS", f"- Generated Case ID: {case_id}")
            else:
                print_status("STEP 2: /score  ", "FAIL", "- Missing 'case_id' or 'score' in response")
                sys.exit(1)
        else:
            print_status("STEP 2: /score  ", "FAIL", f"- HTTP {resp.status_code}: {resp.text}")
            sys.exit(1)
    except Exception as e:
        print_status("STEP 2: /score  ", "FAIL", f"- Exception: {str(e)}")
        sys.exit(1)

    # STEP 3: CONVERSE
    print("\nRunning Stage 4 (Conversational Agent)...")
    try:
        payload = {
            "case_id": case_id,
            "question": "Can you explain why the MAD outlier signal was flagged here?",
            "conversation_history": []
        }
        resp = requests.post(f"{BASE_URL}/converse", json=payload, headers=auth_headers)
        
        if resp.status_code == 200:
            conv_data = resp.json()
            if "answer" in conv_data:
                print_status("STEP 3: /converse", "PASS", f"- Gemma Answered: '{conv_data['answer'][:50]}...'")
            else:
                print_status("STEP 3: /converse", "FAIL", "- Missing 'answer' in response")
                sys.exit(1)
        else:
            print_status("STEP 3: /converse", "FAIL", f"- HTTP {resp.status_code}: {resp.text}")
            sys.exit(1)
    except Exception as e:
        print_status("STEP 3: /converse", "FAIL", f"- Exception: {str(e)}")
        sys.exit(1)

    print("\n==================================================")
    print("✅ All systems go! The pipeline is fully operational.")
    print("==================================================")

if __name__ == "__main__":
    run_e2e()
