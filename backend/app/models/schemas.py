from pydantic import BaseModel, Field
from typing import Literal


class ExtractionResponse(BaseModel):
    document_type: str
    extracted_entities: dict
    amounts: list[float]
    transactions: list[dict]
    dates: list[str]
    inconsistency_flags: list[str]
    extraction_confidence: str


class CaseScoreRequest(BaseModel):
    documents: list[dict] = Field(..., description="List of Stage 1 extraction outputs for this case")
    business_context: str = Field(default="", description="Free-text business type/context, e.g. 'textile wholesaler, seasonal Q4 spike expected'")
    pan_number: str = Field(default="", description="Applicant's self-declared PAN for mock CIBIL bureau lookup (separate from any PAN extracted from documents)")


class CaseScoreResponse(BaseModel):
    case_id: str
    algorithmic_score: int
    deductions: list[dict]
    gemma_adjustment: int
    gemma_adjustment_justification: str
    final_score: int
    score: int  # duplicate of final_score for backwards compatibility
    confidence: Literal["high", "moderate", "low"]
    flagged_reasons: list[str]
    recommended_action: Literal["approve", "escalate", "request_documents", "human_review"]
    reasoning_narrative: str
    signals: dict
    # Mock CIBIL bureau data (hackathon demo only — not a real bureau integration)
    cibil_score: int | None = None
    cibil_band: str = ""
    is_mock_data: bool = True


class ConversationTurn(BaseModel):
    role: Literal["officer", "gemma"]
    content: str


class ConversationRequest(BaseModel):
    case_id: str
    question: str
    conversation_history: list[ConversationTurn] = []


class ConversationResponse(BaseModel):
    answer: str


class CaseStatus(BaseModel):
    case_id: str
    status: Literal["pending", "approved", "escalated", "requires_documents", "rejected"]
    score: int | None = None
    updated_at: str


class CaseStatusUpdateRequest(BaseModel):
    status: Literal["pending", "approved", "escalated", "requires_documents", "rejected"]
    reason: str | None = None


class CaseDetailResponse(BaseModel):
    case_id: str
    status: str
    updated_at: str
    rejection_reason: str | None = None
    documents: list[dict]
    algorithmic_score: int
    deductions: list[dict]
    gemma_adjustment: int
    gemma_adjustment_justification: str
    final_score: int
    score: int
    confidence: Literal["high", "moderate", "low"]
    flagged_reasons: list[str]
    recommended_action: Literal["approve", "escalate", "request_documents", "human_review"]
    reasoning_narrative: str
    signals: dict
    # Mock CIBIL bureau data (hackathon demo only — not a real bureau integration)
    pan_number: str = ""
    cibil_score: int | None = None
    cibil_band: str = ""
    is_mock_data: bool = True
