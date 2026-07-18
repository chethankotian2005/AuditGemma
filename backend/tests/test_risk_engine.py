import pytest
from app.scoring.risk_engine import compute_score, determine_confidence_and_action, BASE_SCORE

def test_clean_score():
    signals = {
        "benfords_law": {"flagged": False},
        "transaction_velocity": {"flagged": False},
        "entity_consistency": {"flagged": False}
    }
    result = compute_score(signals)
    assert result["algorithmic_score"] == 100
    assert len(result["deductions"]) == 0

def test_single_high_severity():
    signals = {
        "entity_consistency": {
            "flagged": True,
            "severity": "high",
            "mismatches": [{"field": "gstin", "document_a": "invoice", "document_b": "kyc"}]
        }
    }
    # High severity = 30, entity consistency weight = 1.5 -> penalty = 45
    # Score = 100 - 45 = 55
    result = compute_score(signals)
    assert result["algorithmic_score"] == 55
    assert len(result["deductions"]) == 1
    assert result["deductions"][0]["penalty"] == 45

def test_multiple_penalties():
    signals = {
        "entity_consistency": {
            "flagged": True,
            "severity": "medium", # medium = 15, weight 1.5 -> 22 (int of 22.5)
        },
        "transaction_velocity": {
            "flagged": True,
            "severity": "high", # high = 30, weight 1.0 -> 30
        }
    }
    result = compute_score(signals)
    assert result["algorithmic_score"] == 100 - 22 - 30 # 48
    assert len(result["deductions"]) == 2

def test_clamping():
    # Force negative score
    signals = {
        "entity_consistency": {"flagged": True, "severity": "high"}, # 45
        "transaction_velocity": {"flagged": True, "severity": "high"}, # 30
        "benfords_law": {"flagged": True, "severity": "high"}, # 30
        "threshold_anomaly": {"flagged": True, "severity": "high"} # 30
    }
    result = compute_score(signals)
    assert result["algorithmic_score"] == 0 # 100 - 135 clamped to 0

def test_determine_confidence_and_action():
    assert determine_confidence_and_action(100) == {"confidence": "high", "recommended_action": "approve"}
    assert determine_confidence_and_action(80) == {"confidence": "high", "recommended_action": "approve"}
    assert determine_confidence_and_action(79) == {"confidence": "moderate", "recommended_action": "human_review"}
    assert determine_confidence_and_action(50) == {"confidence": "moderate", "recommended_action": "human_review"}
    assert determine_confidence_and_action(49) == {"confidence": "high", "recommended_action": "escalate"}
    assert determine_confidence_and_action(0) == {"confidence": "high", "recommended_action": "escalate"}
