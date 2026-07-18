"""
Stage 2 — Benford's Law check.

Naturally occurring financial datasets (invoice amounts, transaction values)
follow a logarithmic leading-digit distribution: digit 1 appears ~30.1% of
the time, digit 9 only ~4.6%. Fabricated/manipulated figures tend to deviate
because humans pick "rounder" or more uniformly distributed numbers.

This is a fixed, reproducible statistical check — no training, no model
drift. Gemma reasons over the output; it does not compute it.
"""
import math
from app.config import settings

# Expected Benford distribution for leading digits 1-9
BENFORD_EXPECTED = {d: math.log10(1 + 1 / d) for d in range(1, 10)}


def _leading_digit(value: float) -> int | None:
    value = abs(value)
    if value < 1:
        # normalize e.g. 0.0456 -> 4
        while value < 1 and value > 0:
            value *= 10
    s = str(value).lstrip("0.").replace(".", "")
    return int(s[0]) if s and s[0] != "0" else None


def benford_check(amounts: list[float]) -> dict:
    """
    Returns a fixed, reproducible signal dict for Gemma to reason over.
    Does NOT make a fraud determination itself — that's Stage 3's job.
    """
    n = len(amounts)
    if n < settings.BENFORD_MIN_SAMPLE_SIZE:
        return {
            "check": "benfords_law",
            "applicable": False,
            "reason": f"sample_size={n} below minimum {settings.BENFORD_MIN_SAMPLE_SIZE} "
                      f"for statistical validity",
            "chi_square": None,
            "flagged": False,
        }

    digit_counts = {d: 0 for d in range(1, 10)}
    for amt in amounts:
        d = _leading_digit(amt)
        if d:
            digit_counts[d] += 1

    chi_square = 0.0
    observed_pct = {}
    for d in range(1, 10):
        expected_count = BENFORD_EXPECTED[d] * n
        observed_count = digit_counts[d]
        observed_pct[d] = round(observed_count / n, 4)
        if expected_count > 0:
            chi_square += ((observed_count - expected_count) ** 2) / expected_count

    flagged = chi_square > settings.BENFORD_CHI_SQUARE_ALERT

    return {
        "check": "benfords_law",
        "applicable": True,
        "sample_size": n,
        "chi_square": round(chi_square, 3),
        "chi_square_critical_value": settings.BENFORD_CHI_SQUARE_ALERT,
        "observed_leading_digit_distribution": observed_pct,
        "expected_leading_digit_distribution": {d: round(v, 4) for d, v in BENFORD_EXPECTED.items()},
        "flagged": flagged,
        "severity": "high" if chi_square > settings.BENFORD_CHI_SQUARE_ALERT * 1.5 else ("medium" if flagged else "low"),
    }
