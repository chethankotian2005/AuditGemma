// =============================================================================
// AuditGemma Officer Dashboard — TypeScript type definitions
// Matches the backend Pydantic schemas exactly (fixed contract, do not modify)
// =============================================================================

/** Signal results from Stage 2 deterministic layer */
export interface Signals {
  benfords_law: {
    chi_squared: number;
    p_value: number;
    conformity: string; // e.g. "acceptable", "suspicious", "non-conforming"
    digit_distribution?: Record<string, number>;
  };
  transaction_velocity: {
    rate_per_day: number;
    spike_detected: boolean;
    spike_ratio?: number;
  };
  threshold_zscore: {
    median: number;
    mad: number;
    outliers: Array<{
      amount: number;
      zscore: number;
    }>;
    has_anomalies: boolean;
  };
  entity_consistency: {
    consistent: boolean;
    mismatches: string[];
    entities_found: Record<string, string[]>;
  };
}

/** Item returned by GET /cases */
export interface CaseListItem {
  case_id: string;
  status: CaseStatusValue;
  score: number;
}

/** Response from GET /case/{id} */
export interface CaseDetail {
  case_id: string;
  status: CaseStatusValue;
  updated_at: string;
  documents: any[];
  algorithmic_score: number;
  deductions: Array<{
    check: string;
    severity: string;
    penalty: number;
    reason: string;
  }>;
  gemma_adjustment: number;
  gemma_adjustment_justification: string;
  final_score: number;
  score: number;
  confidence: "high" | "moderate" | "low";
  flagged_reasons: string[];
  recommended_action:
    | "approve"
    | "escalate"
    | "request_documents"
    | "human_review";
  reasoning_narrative: string;
  signals: Signals;
}

/** Full response from POST /score — contains everything needed for the detail page */
export interface CaseScoreResponse {
  case_id: string;
  algorithmic_score: number;
  deductions: Array<{
    check: string;
    severity: string;
    penalty: number;
    reason: string;
  }>;
  gemma_adjustment: number;
  gemma_adjustment_justification: string;
  final_score: number;
  score: number;
  confidence: "high" | "moderate" | "low";
  flagged_reasons: string[];
  recommended_action:
    | "approve"
    | "escalate"
    | "request_documents"
    | "human_review";
  reasoning_narrative: string;
  signals: Signals;
}

/** An entry in the officer audit trail */
export interface AuditLogEntry {
  case_id: string;
  officer_uid: string;
  action: string;
  previous_status: string;
  new_status: string;
  timestamp: string;
}

/** A single turn in the conversation with the Stage 4 agent */
export interface ConversationTurn {
  role: "officer" | "gemma";
  content: string;
}

/** Request body for POST /converse */
export interface ConversationRequest {
  case_id: string;
  question: string;
  conversation_history: ConversationTurn[];
}

/** Response from POST /converse */
export interface ConversationResponse {
  answer: string;
}

/** Valid case status values */
export type CaseStatusValue =
  | "pending"
  | "approved"
  | "escalated"
  | "requires_documents";

/** API error shape */
export interface ApiError {
  status: number;
  detail: string;
}
