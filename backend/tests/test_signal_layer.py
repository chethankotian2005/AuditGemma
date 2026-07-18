"""
Run with: pytest tests/ -v
These require no Gemma/Ollama — pure deterministic logic, fast to iterate on.
"""
import sys
import os
sys.path.insert(0, os.path.dirname(os.path.dirname(os.path.abspath(__file__))))

from app.signal_layer.benford import benford_check
from app.signal_layer.velocity import velocity_check
from app.signal_layer.threshold import threshold_anomaly_check
from app.signal_layer.entity_consistency import entity_consistency_check


def test_benford_insufficient_sample():
    result = benford_check([100.0, 200.0])
    assert result["applicable"] is False


def test_benford_natural_distribution_not_flagged():
    # Rough Benford-following set: lots of leading 1s and 2s
    amounts = [round(100 * (1.05 ** i), 2) for i in range(1, 50)]
    result = benford_check(amounts)
    assert result["applicable"] is True
    assert "chi_square" in result


def test_benford_fabricated_distribution_flagged():
    # All leading digit 9 — wildly non-Benford
    amounts = [9000.0 + i for i in range(40)]
    result = benford_check(amounts)
    assert result["flagged"] is True


def test_velocity_burst_flagged():
    from datetime import datetime, timedelta
    base = datetime(2026, 7, 1, 9, 0, 0)
    txns = [
        {"timestamp": (base + timedelta(minutes=i * 10)).isoformat(), "amount": 5000}
        for i in range(12)
    ]
    result = velocity_check(txns)
    assert result["flagged"] is True


def test_velocity_normal_not_flagged():
    from datetime import datetime, timedelta
    base = datetime(2026, 7, 1, 9, 0, 0)
    txns = [
        {"timestamp": (base + timedelta(days=i * 3)).isoformat(), "amount": 5000}
        for i in range(5)
    ]
    result = velocity_check(txns)
    assert result["flagged"] is False


def test_threshold_outlier_detected():
    amounts = [1000, 1050, 980, 1020, 1010, 50000]  # 50000 is a clear outlier
    result = threshold_anomaly_check(amounts)
    assert result["flagged"] is True
    assert result["outlier_count"] >= 1


def test_entity_consistency_gstin_mismatch_flagged():
    docs = [
        {"doc_type": "invoice", "extracted_entities": {"gstin": "29ABCDE1234F1Z5", "business_name": "Sharma Textiles"}},
        {"doc_type": "kyc", "extracted_entities": {"gstin": "29ABCDE1234F1Z9", "business_name": "Sharma Textiles"}},
    ]
    result = entity_consistency_check(docs)
    assert result["flagged"] is True
    assert result["severity"] == "high"


def test_entity_consistency_matching_not_flagged():
    docs = [
        {"doc_type": "invoice", "extracted_entities": {"gstin": "29ABCDE1234F1Z5", "business_name": "Sharma Textiles Pvt Ltd"}},
        {"doc_type": "kyc", "extracted_entities": {"gstin": "29ABCDE1234F1Z5", "business_name": "Sharma Textiles Pvt. Ltd."}},
    ]
    result = entity_consistency_check(docs)
    assert result["flagged"] is False
