import requests

payload = {
    "documents": [
        {
            "amounts": [8900 + (day * 15) for day in range(1, 32)],
            "transactions": []
        }
    ],
    "business_context": "Electronics supplier, Mumbai, high volume."
}

try:
    resp = requests.post("http://localhost:8000/api/v1/score", json=payload)
    if resp.status_code == 200:
        data = resp.json()
        print("Score:", data.get("score"))
        for sig in data.get("signals", []):
            if sig.get("check") == "benfords_law":
                print(f"Benford's Law Flagged: {sig.get('flagged')} (Chi-Square: {sig.get('chi_square')})")
    else:
        print("Error:", resp.text)
except Exception as e:
    print("Failed:", e)
