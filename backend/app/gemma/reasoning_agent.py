"""
Stage 3 — Gemma Reasoning & Contextual Adjustment Agent.

Gemma's role is restricted: it no longer invents the score. Instead, it:
  1. Explains the deterministic score (generate_narrative)
  2. Proposes a bounded contextual adjustment based on the business context (propose_contextual_adjustment)
"""
from app.gemma.client import gemma_client
import json

NARRATIVE_SYSTEM_PROMPT = """You are writing the human-readable risk narrative for an RBI-compliant
audit trail. Write for a compliance officer who needs to make a fast decision, not a data scientist 
auditing the statistics. Lead with the CONCLUSION and the plain-English reason, not the raw numeric values. 
The score has already been computed by a deterministic algorithm from fixed signals. 
Your job is to explain, in plain language, why each deduction happened and how it applies to this specific business context. 
Do not propose a different score in this narrative. Keep the full response under 80 words."""

NARRATIVE_PROMPT_TEMPLATE = """Given this algorithmic scoring result and the underlying signals, write a short, 3-part audit-grade risk narrative:
- One sentence: what's the bottom line (the conclusion).
- 2-3 short sentences: the plain-language reasons, referencing WHAT was found. Do NOT include exact numbers (chi-square, z-scores) in the narrative prose.
- One sentence: what this means for the recommended action.
Keep the full response under 80 words.

ALGORITHMIC SCORE SUMMARY:
{algorithmic_breakdown}

DETERMINISTIC SIGNALS:
{signals}

BUSINESS CONTEXT:
{business_context}

Write the narrative following the 3-part structure exactly."""


ADJUSTMENT_SYSTEM_PROMPT = """You are a risk adjustment engine. 
A deterministic algorithm has assigned a base score based on fixed signals.
You may propose ONE adjustment to the algorithmic score based strictly on the BUSINESS CONTEXT provided.
For example, a transaction burst might be normal for a seasonal retailer near festival season, justifying a softer penalty.
Output strict JSON only, in this exact format:
{
  "adjustment": integer,
  "justification": "string explaining the adjustment"
}
The adjustment should be between -10 and +10. If no adjustment is warranted, output 0.
"""

ADJUSTMENT_PROMPT_TEMPLATE = """Evaluate the business context against the penalized signals and propose an adjustment.

ALGORITHMIC SCORE SUMMARY:
{algorithmic_breakdown}

BUSINESS CONTEXT:
{business_context}

Output strict JSON:
{{
  "adjustment": integer,
  "justification": "string"
}}"""


async def generate_narrative(algorithmic_breakdown: dict, signals: dict, business_context: str) -> str:
    prompt = NARRATIVE_PROMPT_TEMPLATE.format(
        algorithmic_breakdown=json.dumps(algorithmic_breakdown, indent=2),
        signals=json.dumps(signals, indent=2),
        business_context=business_context or "Not provided",
    )
    # thinking=False: the score is deterministic, no need for deep reasoning
    return await gemma_client.generate(
        prompt=prompt, thinking=False, system=NARRATIVE_SYSTEM_PROMPT, options={"num_predict": 150}
    )


async def propose_contextual_adjustment(algorithmic_breakdown: dict, business_context: str) -> dict:
    prompt = ADJUSTMENT_PROMPT_TEMPLATE.format(
        algorithmic_breakdown=json.dumps(algorithmic_breakdown, indent=2),
        business_context=business_context or "Not provided",
    )
    try:
        result = await gemma_client.generate_json(
            prompt=prompt, thinking=False, system=ADJUSTMENT_SYSTEM_PROMPT
        )
        return {
            "adjustment": int(result.get("adjustment", 0)),
            "justification": str(result.get("justification", "No justification provided."))
        }
    except Exception:
        # Fallback if Gemma fails or returns non-JSON
        return {"adjustment": 0, "justification": "Failed to parse adjustment from AI."}


async def run_stage3(algorithmic_breakdown: dict, signals: dict, business_context: str = "") -> dict:
    from app.scoring.risk_engine import determine_confidence_and_action
    
    # 1. Generate the explanation narrative
    narrative = await generate_narrative(algorithmic_breakdown, signals, business_context)
    
    # 2. Ask Gemma for a contextual adjustment
    adj_result = await propose_contextual_adjustment(algorithmic_breakdown, business_context)
    
    # 3. Enforce hard clamp on the adjustment [-10, 10]
    raw_adj = adj_result.get("adjustment", 0)
    clamped_adj = max(-10, min(10, raw_adj))
    justification = adj_result.get("justification", "")
    
    if clamped_adj == 0 and not justification.strip():
        justification = "No contextual adjustment warranted."
        
    # 4. Compute final score
    base_algorithmic = algorithmic_breakdown["algorithmic_score"]
    final_score = max(0, min(100, base_algorithmic + clamped_adj))
    
    # 5. Compute confidence and action from deterministic thresholds
    action_dict = determine_confidence_and_action(final_score)
    
    return {
        "algorithmic_score": base_algorithmic,
        "deductions": algorithmic_breakdown.get("deductions", []),
        "gemma_adjustment": clamped_adj,
        "gemma_adjustment_justification": justification,
        "final_score": final_score,
        "score": final_score,
        "confidence": action_dict["confidence"],
        "recommended_action": action_dict["recommended_action"],
        "reasoning_narrative": narrative,
        "flagged_reasons": [d["reason"] for d in algorithmic_breakdown.get("deductions", [])]
    }
