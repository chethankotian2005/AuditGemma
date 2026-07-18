"""
Stage 2 — Threshold / anomaly check using a robust modified z-score
(median + MAD, not mean + stdev).

A naive mean/stdev z-score is skewed by the very outliers it's trying to
detect — one huge amount inflates the stdev enough to hide itself. The
modified z-score (Iglewicz & Hoya, standard in fraud detection) uses the
median and median absolute deviation instead, which stay stable even with
extreme outliers present.
"""
import statistics
from app.config import settings

MAD_CONSTANT = 0.6745  # makes MAD comparable to stdev under normality assumption


def threshold_anomaly_check(amounts: list[float]) -> dict:
    if len(amounts) < 3:
        return {
            "check": "threshold_zscore",
            "applicable": False,
            "reason": "fewer than 3 amounts, insufficient for baseline",
            "flagged": False,
        }

    median = statistics.median(amounts)
    abs_deviations = [abs(a - median) for a in amounts]
    mad = statistics.median(abs_deviations)

    if mad == 0:
        # Fall back to a tiny epsilon based on mean absolute deviation so we don't
        # divide by zero when most values are identical but a few aren't.
        mad = statistics.mean(abs_deviations) or 1e-9

    outliers = []
    for amt in amounts:
        modified_z = MAD_CONSTANT * (amt - median) / mad
        if abs(modified_z) > settings.ZSCORE_ANOMALY_THRESHOLD:
            outliers.append({"amount": amt, "modified_z_score": round(modified_z, 2)})

    flagged = len(outliers) > 0

    return {
        "check": "threshold_zscore",
        "applicable": True,
        "median": round(median, 2),
        "mad": round(mad, 2),
        "zscore_threshold": settings.ZSCORE_ANOMALY_THRESHOLD,
        "outliers": outliers,
        "outlier_count": len(outliers),
        "flagged": flagged,
        "severity": "high" if len(outliers) > 2 else ("medium" if flagged else "low"),
    }
