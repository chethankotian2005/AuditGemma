// =============================================================================
// AuditGemma API client — typed fetch wrappers around the fixed backend contract
// =============================================================================

import type {
  CaseListItem,
  CaseDetail,
  CaseScoreResponse,
  ConversationTurn,
  AuditLogEntry,
} from "./types";

import { auth } from "./firebase";

const BASE_URL =
  process.env.NEXT_PUBLIC_API_URL ?? "http://localhost:8000/api/v1";

class ApiError extends Error {
  constructor(
    public status: number,
    public detail: string,
  ) {
    super(`API Error ${status}: ${detail}`);
    this.name = "ApiError";
  }
}

async function apiFetch<T>(
  path: string,
  options?: RequestInit,
): Promise<T> {
  const url = `${BASE_URL}${path}`;
  
  let headers: Record<string, string> = {
    "Content-Type": "application/json",
  };

  const user = auth.currentUser;
  if (user) {
    const token = await user.getIdToken();
    headers["Authorization"] = `Bearer ${token}`;
  }

  if (options?.headers) {
    headers = { ...headers, ...(options.headers as Record<string, string>) };
  }

  const res = await fetch(url, {
    ...options,
    headers,
  });

  if (!res.ok) {
    let detail = res.statusText;
    try {
      const body = await res.json();
      detail = body.detail ?? JSON.stringify(body);
    } catch {
      // keep statusText
    }
    throw new ApiError(res.status, detail);
  }

  // Handle 204 No Content
  if (res.status === 204) return undefined as T;

  return res.json() as Promise<T>;
}

// ---------------------------------------------------------------------------
// GET /cases
// ---------------------------------------------------------------------------
export async function getCases(): Promise<CaseListItem[]> {
  return apiFetch<CaseListItem[]>("/cases");
}

// ---------------------------------------------------------------------------
// GET /case/{id}
// ---------------------------------------------------------------------------
export async function getCase(id: string): Promise<CaseDetail> {
  return apiFetch<CaseDetail>(`/case/${encodeURIComponent(id)}`);
}

// ---------------------------------------------------------------------------
// GET /case/{id}/audit_log
// ---------------------------------------------------------------------------
export async function getAuditLog(id: string): Promise<AuditLogEntry[]> {
  return apiFetch<AuditLogEntry[]>(`/case/${encodeURIComponent(id)}/audit_log`);
}

// ---------------------------------------------------------------------------
// PATCH /case/{id}/status?status=...
// ---------------------------------------------------------------------------
export async function updateCaseStatus(
  id: string,
  status: string,
): Promise<{ case_id: string; status: string }> {
  return apiFetch(`/case/${encodeURIComponent(id)}/status?status=${encodeURIComponent(status)}`, {
    method: "PATCH",
  });
}

// ---------------------------------------------------------------------------
// POST /converse
// ---------------------------------------------------------------------------
export async function converse(
  caseId: string,
  question: string,
  history: ConversationTurn[],
): Promise<string> {
  const res = await apiFetch<{ answer: string }>("/converse", {
    method: "POST",
    body: JSON.stringify({
      case_id: caseId,
      question,
      conversation_history: history,
    }),
  });
  return res.answer;
}

// ---------------------------------------------------------------------------
// POST /score (used by upstream scoring flows, not directly by the dashboard
// case queue, but needed if we add a "score new case" flow)
// ---------------------------------------------------------------------------
export async function scoreCase(
  documents: Record<string, unknown>[],
  businessContext: string,
): Promise<CaseScoreResponse> {
  return apiFetch<CaseScoreResponse>("/score", {
    method: "POST",
    body: JSON.stringify({
      documents,
      business_context: businessContext,
    }),
  });
}

export { ApiError };
