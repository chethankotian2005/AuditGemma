"""
Stage 1 — Gemma Extraction Agent.

Reads a raw document (image, via Gemma's native vision) and extracts
structured fields directly. Thinking Mode OFF — rigid JSON output degrades
under Thinking Mode, and we need fast, clean structure here, not a
reasoning trace.

Document extraction uses Gemma's native vision only — no separate OCR
dependency required.
"""
from app.gemma.client import gemma_client

EXTRACTION_SYSTEM_PROMPT = """You are a document extraction engine for an Indian NBFC/SME lending
compliance pipeline. You read invoices, GST filings, bank statements, and KYC documents
and extract structured fields ONLY. Do not assess risk or make judgments — that happens
in a later stage. Output strict JSON only, no prose, no markdown fences."""

EXTRACTION_PROMPT_TEMPLATE = """Extract the following fields from this document. If a field is not
present or not legible, use null. If you notice any internal inconsistency within THIS
single document (e.g. total doesn't match line items, date looks altered), list it in
inconsistency_flags — do not speculate about fraud, just note the mechanical inconsistency.

Return this exact JSON shape:
{{
  "document_type": "invoice | gst_filing | bank_statement | kyc",
  "extracted_entities": {{
    "business_name": string or null,
    "gstin": string or null,
    "pan": string or null,
    "address": string or null
  }},
  "amounts": [list of numeric amounts found, as floats],
  "transactions": [
    {{"timestamp": "ISO8601 string", "amount": float, "description": string}}
  ],
  "dates": [list of ISO8601 date strings found in the document],
  "inconsistency_flags": [list of strings describing mechanical inconsistencies found],
  "extraction_confidence": "high | medium | low"
}}"""


async def extract_document(image_bytes: bytes) -> dict:
    image_b64 = gemma_client.image_to_base64(image_bytes)
    return await gemma_client.generate_json(
        prompt=EXTRACTION_PROMPT_TEMPLATE,
        thinking=False,
        image_base64=image_b64,
        system=EXTRACTION_SYSTEM_PROMPT,
    )
