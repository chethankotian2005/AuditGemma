import requests

BASE_URL = "http://localhost:8000/api/v1"

def test_rejection():
    print("Testing GET /cases without a token...")
    resp = requests.get(f"{BASE_URL}/cases")
    
    if resp.status_code == 403:
        print("[PASS] Received 403 Forbidden (missing credentials)")
    elif resp.status_code == 401:
        print("[PASS] Received 401 Unauthorized")
    else:
        print(f"[FAIL] Expected 401 or 403, got {resp.status_code}: {resp.text}")

    print("\nTesting POST /score with invalid token...")
    headers = {"Authorization": "Bearer not_a_real_token"}
    payload = {"documents": [], "business_context": "test"}
    resp = requests.post(f"{BASE_URL}/score", json=payload, headers=headers)
    
    if resp.status_code == 401:
        print("[PASS] Received 401 Unauthorized (invalid token)")
    else:
        print(f"[FAIL] Expected 401, got {resp.status_code}: {resp.text}")

if __name__ == "__main__":
    test_rejection()
