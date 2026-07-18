"""
Stage 2 — Deterministic Signal Layer aggregator.

Runs all fixed, reproducible statistical checks and packages a single
signals dict. This is what gets handed to Stage 3's Gemma reasoning agent —
Gemma never re-derives these numbers, it reasons over them. That split is
the reproducibility story: "our signal layer is fixed; Gemma reasons over
fixed inputs."
"""
from app.signal_layer.benford import benford_check
from app.signal_layer.velocity import velocity_check
from app.signal_layer.threshold import threshold_anomaly_check
from app.signal_layer.entity_consistency import entity_consistency_check


def run_signal_layer(case_data: dict) -> dict:
    """
    case_data expected shape:
    {
        "amounts": [float, ...],                 # all invoice/txn amounts in the case
        "transactions": [{"timestamp": iso, "amount": float}, ...],
        "documents": [{"doc_type": str, "extracted_entities": {...}}, ...],  # from Stage 1
    }
    """
    amounts = case_data.get("amounts", [])
    transactions = case_data.get("transactions", [])
    documents = case_data.get("documents", [])

    signals = {
        "benfords_law": benford_check(amounts),
        "transaction_velocity": velocity_check(transactions),
        "threshold_anomaly": threshold_anomaly_check(amounts),
        "entity_consistency": entity_consistency_check(documents),
    }

    flagged_checks = [name for name, result in signals.items() if result.get("flagged")]

    return {
        "signals": signals,
        "flagged_check_count": len(flagged_checks),
        "flagged_checks": flagged_checks,
    }
