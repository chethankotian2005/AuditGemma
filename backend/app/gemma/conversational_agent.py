"""
Stage 4 — Gemma Conversational Audit Agent.

Officer chats with Gemma about a flagged case: "Why is this flagged?",
"What would change your assessment?" — grounded in the same extracted
data + signals + Stage 3 score/narrative. Thinking Mode ON: officer
questions require real multi-step reasoning, and ~3-15s latency is
acceptable in a back-and-forth chat (unlike the live extraction pipeline).

This is the single most demo-able feature per the spec — designed to
survive an unscripted judge question live.
"""
from app.gemma.client import gemma_client

CONVO_SYSTEM_PROMPT = """You are AuditGemma's conversational audit agent. A compliance officer
is questioning your risk assessment of an SME loan case. Answer in plain, short, direct language.
Omit raw numeric values (like chi-square or z-scores) unless explicitly requested by the officer.
You must answer ONLY using the grounded case data provided below — the extracted documents, 
deterministic signals, and your own prior score/narrative. If the officer asks something not answerable 
from this data, say so plainly rather than speculating. Be direct, and be willing to say "that would change my assessment" 
if the officer raises a genuinely new consideration. Keep your response short (under 80 words)."""

CONVO_PROMPT_TEMPLATE = """CASE CONTEXT (grounding — do not exceed this):

EXTRACTED DOCUMENTS:
{extracted_documents}

DETERMINISTIC SIGNALS:
{signals}

PRIOR SCORE & NARRATIVE:
{score_result}

CONVERSATION HISTORY:
{conversation_history}

OFFICER'S NEW QUESTION:
{question}

Answer the officer's question, grounded strictly in the case context above."""


async def ask(
    extracted_documents: dict,
    signals: dict,
    score_result: dict,
    question: str,
    conversation_history: list[dict] | None = None,
) -> str:
    history_str = "\n".join(
        f"{turn['role']}: {turn['content']}" for turn in (conversation_history or [])
    ) or "(start of conversation)"

    prompt = CONVO_PROMPT_TEMPLATE.format(
        extracted_documents=extracted_documents,
        signals=signals,
        score_result=score_result,
        conversation_history=history_str,
        question=question,
    )
    # NOTE: thinking=True allows for reasoning on genuinely novel questions. 
    # If conversation speed is still a problem, consider testing with thinking=False.
    return await gemma_client.generate(
        prompt=prompt, thinking=True, system=CONVO_SYSTEM_PROMPT, options={"num_predict": 150}
    )
