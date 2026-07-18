"""
Stage 2 — Transaction velocity check.

Flags bursts of transactions in a short window — a common laundering /
invoice-mill pattern (many similar-value transactions pushed through fast
to stay under manual review thresholds).
"""
from datetime import datetime
from app.config import settings


def velocity_check(transactions: list[dict]) -> dict:
    """
    transactions: list of {"timestamp": ISO8601 str, "amount": float}
    Returns fixed signal dict; sliding-window max count within
    VELOCITY_WINDOW_HOURS.
    """
    if len(transactions) < 2:
        return {
            "check": "transaction_velocity",
            "applicable": False,
            "reason": "fewer than 2 transactions",
            "flagged": False,
        }

    parsed = []
    for t in transactions:
        try:
            parsed.append({"ts": datetime.fromisoformat(t["timestamp"]), "amount": t["amount"]})
        except ValueError:
            pass
            
    parsed = sorted(parsed, key=lambda x: x["ts"])

    if len(parsed) < 2:
        return {
            "check": "transaction_velocity",
            "applicable": False,
            "reason": "fewer than 2 valid transactions with parseable dates",
            "flagged": False,
        }

    window_seconds = settings.VELOCITY_WINDOW_HOURS * 3600
    max_count_in_window = 1
    worst_window_start = parsed[0]["ts"]

    left = 0
    for right in range(len(parsed)):
        while (parsed[right]["ts"] - parsed[left]["ts"]).total_seconds() > window_seconds:
            left += 1
        count = right - left + 1
        if count > max_count_in_window:
            max_count_in_window = count
            worst_window_start = parsed[left]["ts"]

    flagged = max_count_in_window > settings.VELOCITY_MAX_TXNS_PER_WINDOW

    return {
        "check": "transaction_velocity",
        "applicable": True,
        "window_hours": settings.VELOCITY_WINDOW_HOURS,
        "max_transactions_in_window": max_count_in_window,
        "threshold": settings.VELOCITY_MAX_TXNS_PER_WINDOW,
        "worst_window_start": worst_window_start.isoformat(),
        "total_transactions": len(parsed),
        "flagged": flagged,
        "severity": "high" if max_count_in_window > settings.VELOCITY_MAX_TXNS_PER_WINDOW * 2 else ("medium" if flagged else "low"),
    }
