"""
MOCK CIBIL score lookup for hackathon demo purposes only.

Real CIBIL bureau access requires a paid commercial API (TransUnion CIBIL) that
this team does not have. This module hardcodes exactly 4 PAN numbers to fixed
illustrative scores to demonstrate where a real bureau integration would plug
into the pipeline.

In production, this file would be replaced by a secure HTTP client calling the
TransUnion CIBIL Connect API or equivalent bureau endpoint.
"""

# Realistic-looking but entirely fictional PAN numbers.
# Standard PAN format: 5 uppercase letters + 4 digits + 1 uppercase letter.
MOCK_CIBIL_LOOKUP = {
    "ABCPK1234L": {"score": 780, "band": "Excellent"},
    "DGHPM5678R": {"score": 650, "band": "Fair"},
    "JKLPV9012N": {"score": 540, "band": "Poor"},
    "XYZPD3456Q": {"score": 300, "band": "Very Poor / No History"},
}


def get_mock_cibil(pan_number: str) -> dict:
    """
    Look up a mock CIBIL score for the given PAN number.

    Returns:
        dict with keys: score (int|None), band (str), is_mock_data (bool).
        If the PAN is not in our demo dataset, score is None.
    """
    cleaned = pan_number.strip().upper() if pan_number else ""
    result = MOCK_CIBIL_LOOKUP.get(cleaned)
    if result is None:
        return {
            "score": None,
            "band": "Not Found (Demo dataset only covers 4 test PANs)",
            "is_mock_data": True,
        }
    return {**result, "is_mock_data": True}
