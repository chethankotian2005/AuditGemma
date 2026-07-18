"""
API routes — the four-stage pipeline exposed as endpoints.

Flow for a full case:
  POST /extract          (Stage 1, per document, called once per uploaded file)
  POST /score             (Stage 2 signal layer + Stage 3 Gemma reasoning, called once per case)
  POST /converse           (Stage 4, called per officer question)

Case state (documents, scores, status) is stored in Firestore.
"""
from fastapi import APIRouter, UploadFile, File, HTTPException, Depends
from datetime import datetime, timezone
import uuid

from app.gemma.extraction_agent import extract_document
from app.gemma.reasoning_agent import run_stage3
from app.gemma.conversational_agent import ask as gemma_ask
from app.signal_layer import run_signal_layer
from app.scoring.risk_engine import compute_score
from app.models.schemas import (
    CaseScoreRequest, CaseScoreResponse, ConversationRequest,
    ConversationResponse, CaseStatus, CaseStatusUpdateRequest, CaseDetailResponse
)
from app.db.firestore_client import (
    save_case, get_case as db_get_case, list_cases as db_list_cases, 
    update_case_status as db_update_case_status, send_new_case_notification,
    append_audit_log, get_audit_log
)
from app.auth.verify_token import verify_token

router = APIRouter()


@router.post("/extract")
async def extract(file: UploadFile = File(...)):
    """
    Stage 1: Gemma extraction agent for a single uploaded document.
    Document extraction uses Gemma's native vision only — no separate OCR dependency required.
    TODO: /extract is intentionally left unauthenticated to allow SME applicants 
    to upload without being on the Officer's Firebase tenant. Consider adding SME-specific auth later.
    """
    image_bytes = await file.read()
    try:
        result = await extract_document(image_bytes)
    except Exception as e:
        raise HTTPException(status_code=502, detail=f"Gemma extraction failed: {e}")
    return result


@router.post("/score", response_model=CaseScoreResponse)
async def score(request: CaseScoreRequest, auth_token: dict = Depends(verify_token)):
    """
    Stage 2 (deterministic signals) + Stage 3 (Gemma reasoning/scoring + narrative).
    `documents` should be a list of Stage 1 /extract outputs already collected for this case.
    """
    if not request.documents:
        raise HTTPException(status_code=400, detail="Cannot score a case with zero documents.")

    all_amounts = [amt for doc in request.documents for amt in doc.get("amounts", [])]
    all_transactions = [txn for doc in request.documents for txn in doc.get("transactions", [])]

    case_data = {
        "amounts": all_amounts,
        "transactions": all_transactions,
        "documents": request.documents,
    }
    signal_result = run_signal_layer(case_data)
    
    # Deterministic scoring
    algorithmic_breakdown = compute_score(signal_result["signals"])

    try:
        stage3_result = await run_stage3(
            algorithmic_breakdown=algorithmic_breakdown,
            signals=signal_result["signals"],
            business_context=request.business_context,
        )
    except Exception as e:
        raise HTTPException(status_code=502, detail=f"Gemma reasoning failed: {e}")

    case_id = str(uuid.uuid4())
    case_record = {
        "documents": request.documents,
        "signals": signal_result["signals"],
        "score_result": stage3_result,
        "status": "pending",
        "updated_at": datetime.now(timezone.utc).isoformat(),
    }
    
    save_case(case_id, case_record)
    send_new_case_notification(case_id, stage3_result["score"])

    return CaseScoreResponse(
        case_id=case_id,
        algorithmic_score=stage3_result["algorithmic_score"],
        deductions=stage3_result["deductions"],
        gemma_adjustment=stage3_result["gemma_adjustment"],
        gemma_adjustment_justification=stage3_result["gemma_adjustment_justification"],
        final_score=stage3_result["final_score"],
        score=stage3_result["score"],
        confidence=stage3_result["confidence"],
        flagged_reasons=stage3_result["flagged_reasons"],
        recommended_action=stage3_result["recommended_action"],
        reasoning_narrative=stage3_result["reasoning_narrative"],
        signals=signal_result["signals"],
    )


@router.post("/converse", response_model=ConversationResponse)
async def converse(request: ConversationRequest, auth_token: dict = Depends(verify_token)):
    """Stage 4: conversational audit agent, grounded in a stored case."""
    case = db_get_case(request.case_id)
    if not case:
        raise HTTPException(status_code=404, detail="case_id not found")

    history = [{"role": t.role, "content": t.content} for t in request.conversation_history]
    try:
        answer = await gemma_ask(
            extracted_documents=case.get("documents", []),
            signals=case.get("signals", {}),
            score_result=case.get("score_result", {}),
            question=request.question,
            conversation_history=history,
        )
    except Exception as e:
        raise HTTPException(status_code=502, detail=f"Gemma conversation failed: {e}")

    return ConversationResponse(answer=answer)


@router.get("/case/{case_id}", response_model=CaseDetailResponse)
async def get_case(case_id: str, auth_token: dict = Depends(verify_token)):
    case = db_get_case(case_id)
    if not case:
        raise HTTPException(status_code=404, detail="case_id not found")
    
    sr = case.get("score_result", {})
    return CaseDetailResponse(
        case_id=case_id,
        status=case.get("status", "pending"),
        updated_at=case.get("updated_at", ""),
        rejection_reason=case.get("rejection_reason"),
        documents=case.get("documents", []),
        algorithmic_score=sr.get("algorithmic_score", 0),
        deductions=sr.get("deductions", []),
        gemma_adjustment=sr.get("gemma_adjustment", 0),
        gemma_adjustment_justification=sr.get("gemma_adjustment_justification", ""),
        final_score=sr.get("final_score", 0),
        score=sr.get("score", 0),
        confidence=sr.get("confidence", "low"),
        flagged_reasons=sr.get("flagged_reasons", []),
        recommended_action=sr.get("recommended_action", "human_review"),
        reasoning_narrative=sr.get("reasoning_narrative", ""),
        signals=case.get("signals", {}),
    )


@router.patch("/case/{case_id}/status")
async def update_case_status(case_id: str, request: CaseStatusUpdateRequest, auth_token: dict = Depends(verify_token)):
    """Officer swipe action: approve / escalate / request_documents / reject."""
    case = db_get_case(case_id)
    if not case:
        raise HTTPException(status_code=404, detail="case_id not found")
        
    if request.status == "rejected" and not request.reason:
        raise HTTPException(status_code=400, detail="Rejection reason is required.")
        
    updated_at = datetime.now(timezone.utc).isoformat()
    previous_status = case.get("status", "pending")
    officer_uid = auth_token.get("uid", "unknown")
    
    # Audit trail
    if previous_status != request.status:
        action_text = f"Changed status to {request.status}"
        if request.reason:
            action_text += f" (Reason: {request.reason})"
            
        append_audit_log(
            case_id=case_id,
            officer_uid=officer_uid,
            action=action_text,
            previous_status=previous_status,
            new_status=request.status,
            timestamp=updated_at
        )

    db_update_case_status(case_id, request.status, updated_at, request.reason)
    return {"case_id": case_id, "status": request.status}

@router.get("/case/{case_id}/audit_log")
async def get_case_audit_log(case_id: str, auth_token: dict = Depends(verify_token)):
    """Fetch the audit trail for a specific case."""
    case = db_get_case(case_id)
    if not case:
        raise HTTPException(status_code=404, detail="case_id not found")
    
    return get_audit_log(case_id)


@router.get("/cases")
async def list_cases(auth_token: dict = Depends(verify_token)):
    """Officer web dashboard case queue."""
    return db_list_cases()
