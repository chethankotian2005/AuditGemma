import requests

cases_resp = requests.get("http://localhost:8000/api/v1/cases")
cases = cases_resp.json()
if cases:
    case_id = cases[0]["case_id"]
    print("Testing on case:", case_id)
    url = f"http://localhost:8000/api/v1/case/{case_id}/status"
    
    # Try rejecting without reason
    resp1 = requests.patch(url, json={"status": "rejected"})
    print("Without reason:", resp1.status_code, resp1.json())
    
    # Try rejecting with reason
    resp2 = requests.patch(url, json={"status": "rejected", "reason": "Test rejection"})
    print("With reason:", resp2.status_code, resp2.json())
    
    # Fetch case detail
    detail_resp = requests.get(f"http://localhost:8000/api/v1/case/{case_id}")
    print("Detail rejection reason:", detail_resp.json().get("rejection_reason"))
else:
    print("No cases found")
