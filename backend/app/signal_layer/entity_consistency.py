"""
Stage 2 — Entity consistency check across documents.

Compares entity fields (business name, GSTIN, PAN, address) extracted by
Gemma's Stage 1 extraction agent across multiple documents in the same
case. Pure string/exact-match comparison — deterministic and reproducible.
Gemma extracted the fields; this module just diffs them.
"""
import difflib


FIELDS_TO_CHECK = ["business_name", "gstin", "pan", "address"]


def _similarity(a: str, b: str) -> float:
    if not a or not b:
        return 0.0
    return difflib.SequenceMatcher(None, a.strip().lower(), b.strip().lower()).ratio()


def entity_consistency_check(documents: list[dict]) -> dict:
    """
    documents: list of {"doc_type": str, "extracted_entities": {field: value}}
    (extracted_entities comes from Stage 1 Gemma extraction agent output)
    """
    if len(documents) < 2:
        return {
            "check": "entity_consistency",
            "applicable": False,
            "reason": "fewer than 2 documents, nothing to cross-check",
            "flagged": False,
        }

    mismatches = []
    for field in FIELDS_TO_CHECK:
        values = [
            (doc.get("document_type", "unknown"), doc.get("extracted_entities", {}).get(field))
            for doc in documents
            if doc.get("extracted_entities", {}).get(field)
        ]
        if len(values) < 2:
            continue

        base_doc, base_val = values[0]
        for doc_type, val in values[1:]:
            sim = _similarity(base_val, val)
            # exact fields like GSTIN/PAN should match exactly; names/addresses
            # tolerate minor formatting drift
            exact_field = field in ("gstin", "pan")
            threshold = 1.0 if exact_field else 0.85
            if sim < threshold:
                mismatches.append({
                    "field": field,
                    "document_a": base_doc,
                    "value_a": base_val,
                    "document_b": doc_type,
                    "value_b": val,
                    "similarity": round(sim, 2),
                })

    flagged = len(mismatches) > 0

    return {
        "check": "entity_consistency",
        "applicable": True,
        "documents_compared": len(documents),
        "fields_checked": FIELDS_TO_CHECK,
        "mismatches": mismatches,
        "flagged": flagged,
        "severity": "high" if any(m["field"] in ("gstin", "pan") for m in mismatches) else ("medium" if flagged else "low"),
    }
