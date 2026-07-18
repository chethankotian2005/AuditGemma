"use client";

import { useEffect, useState, useCallback, use } from "react";
import Link from "next/link";
import {
  ArrowLeft,
  CheckCircle2,
  AlertTriangle,
  FileText,
  Loader2,
  FileImage,
  ShieldAlert,
  BookOpen,
} from "lucide-react";
import { getCase, updateCaseStatus, getAuditLog, ApiError } from "@/lib/api";
import { useAuth } from "@/context/AuthContext";
import { useCaseData } from "@/context/CaseDataContext";
import type { CaseDetail, CaseScoreResponse, ConversationTurn, AuditLogEntry } from "@/lib/types";
import ScoreGradient from "@/components/ScoreGradient";
import ConfidenceBadge from "@/components/ConfidenceBadge";
import StatusBadge from "@/components/StatusBadge";
import SkeletonLoader from "@/components/SkeletonLoader";
import SignalCard from "@/components/SignalCard";
import ReasoningNarrative from "@/components/ReasoningNarrative";
import ChatPanel from "@/components/ChatPanel";
import ReportExport from "@/components/ReportExport";

interface PageProps {
  params: Promise<{ id: string }>;
}

export default function CaseDetailPage({ params }: PageProps) {
  const { id } = use(params);
  const { logout } = useAuth();
  const { getCachedCase } = useCaseData();

  const [caseDetail, setCaseDetail] = useState<CaseDetail | null>(null);
  const [auditLog, setAuditLog] = useState<AuditLogEntry[]>([]);
  const [loading, setLoading] = useState(true);
  const [error, setError] = useState<string | null>(null);

  // Action states
  const [actionLoading, setActionLoading] = useState<string | null>(null);
  const [confirmAction, setConfirmAction] = useState<string | null>(null);
  const [actionSuccess, setActionSuccess] = useState<string | null>(null);

  // Conversation history (for PDF export)
  const [conversationHistory, setConversationHistory] = useState<ConversationTurn[]>([]);

  // Full cached data from CaseScoreResponse
  const cachedData: CaseScoreResponse | null = getCachedCase(id);

  const fetchCase = useCallback(async () => {
    setLoading(true);
    setError(null);
    try {
      const [data, auditData] = await Promise.all([
        getCase(id),
        getAuditLog(id)
      ]);
      setCaseDetail(data);
      setAuditLog(auditData);
    } catch (err) {
      if (err instanceof ApiError && (err.status === 401 || err.status === 403)) {
        logout("session_expired");
        return;
      }
      setError(err instanceof Error ? err.message : "Failed to fetch case");
    } finally {
      setLoading(false);
    }
  }, [id]);

  useEffect(() => {
    fetchCase();
  }, [fetchCase]);

  const handleAction = async (status: string) => {
    setConfirmAction(null);
    setActionLoading(status);
    try {
      await updateCaseStatus(id, status);
      setActionSuccess(status);
      // Refresh case data
      await fetchCase();
      setTimeout(() => setActionSuccess(null), 2000);
    } catch (err) {
      setError(
        err instanceof Error ? err.message : "Failed to update status",
      );
    } finally {
      setActionLoading(null);
    }
  };

  const score = cachedData?.score ?? caseDetail?.score ?? null;
  const hasFullData = cachedData !== null;

  return (
    <div className="page-container">
      {/* Back link */}
      <Link href="/" className="back-link">
        <ArrowLeft size={14} />
        Back to Case Queue
      </Link>

      {/* Page header */}
      <div className="page-header">
        <div>
          <h1 className="page-title" style={{ display: "flex", alignItems: "center", gap: "12px" }}>
            Case {id.slice(0, 8)}…
            {caseDetail && <StatusBadge status={caseDetail.status} />}
          </h1>
          <p className="page-subtitle">
            {caseDetail?.updated_at
              ? `Last updated: ${new Date(caseDetail.updated_at).toLocaleString("en-IN")}`
              : "Loading…"}
          </p>
        </div>
        {hasFullData && (
          <ReportExport
            caseData={cachedData}
            conversationHistory={conversationHistory}
            auditLog={auditLog}
          />
        )}
      </div>

      {/* Error state */}
      {error && (
        <div className="chat-error" style={{ marginBottom: "16px" }}>
          <p>{error}</p>
          <button onClick={fetchCase} className="chat-error-dismiss">
            Retry
          </button>
        </div>
      )}

      {loading ? (
        <div className="stagger-children" style={{ display: "flex", flexDirection: "column", gap: "16px" }}>
          <SkeletonLoader variant="card" count={3} />
        </div>
      ) : !hasFullData ? (
        /* Reduced view — only basic data from GET /case/{id} */
        <div>
          <div className="no-data-notice">
            <ShieldAlert size={32} style={{ margin: "0 auto 12px", color: "var(--text-muted)" }} />
            <h3>Limited View</h3>
            <p>
              Full case details (reasoning narrative, signals, flagged reasons) are
              available when cases are scored through the dashboard.
            </p>
            <p>
              Basic case information is shown below from the backend.
            </p>
          </div>

          {score !== null && (
            <div className="panel-card" style={{ marginBottom: "24px" }}>
              <div className="panel-card-header">Risk Score</div>
              <ScoreGradient score={score} variant="bar" animate />
            </div>
          )}

          {/* Officer actions — always available */}
          <div className="officer-actions">
            <ActionButton
              label="Approve"
              status="approved"
              icon={<CheckCircle2 size={16} />}
              className="officer-btn-approve"
              loading={actionLoading}
              success={actionSuccess}
              onClick={() => setConfirmAction("approved")}
            />
            <ActionButton
              label="Escalate"
              status="escalated"
              icon={<AlertTriangle size={16} />}
              className="officer-btn-escalate"
              loading={actionLoading}
              success={actionSuccess}
              onClick={() => setConfirmAction("escalated")}
            />
            <ActionButton
              label="Request Documents"
              status="requires_documents"
              icon={<FileText size={16} />}
              className="officer-btn-request-docs"
              loading={actionLoading}
              success={actionSuccess}
              onClick={() => setConfirmAction("requires_documents")}
            />
          </div>

          {/* Chat — always available if the backend has this case */}
          <ChatPanel caseId={id} />
        </div>
      ) : (
        /* Full view — cached CaseScoreResponse available */
        <div className="animate-fade-in">
          {/* Two-column layout */}
          <div className="case-detail-grid">
            {/* Left — Document Viewer */}
            <div className="doc-viewer">
              <div className="doc-viewer-header">
                <h3>
                  <FileImage size={16} style={{ display: "inline", marginRight: "6px", verticalAlign: "-2px" }} />
                  Documents
                </h3>
                <span>Uploaded files</span>
              </div>
              <div className="doc-placeholder">
                <FileImage size={48} className="doc-placeholder-icon" />
                <p className="doc-placeholder-title">
                  Document Viewer
                </p>
                <p className="doc-placeholder-hint">
                  Uploaded invoices, GST filings, bank statements, and KYC
                  documents will render here when document serving is enabled.
                </p>
              </div>
            </div>

            {/* Right — Reasoning Transparency Panel */}
            <div className="reasoning-panel stagger-children">
              {/* Score Hero */}
              <div className="panel-card">
                <div className="panel-card-header">Risk Assessment</div>
                <div className="score-hero">
                  <div className="score-hero-bar">
                    <ScoreGradient
                      score={cachedData.score}
                      variant="bar"
                      animate
                    />
                  </div>
                  <div className="score-hero-badges">
                    <ConfidenceBadge confidence={cachedData.confidence} />
                    <StatusBadge status={caseDetail?.status ?? "pending"} />
                  </div>
                </div>
              </div>

              {/* Score Breakdown (Deterministic logic + Gemma Adjustment) */}
              <div className="panel-card">
                <div className="panel-card-header">Score Breakdown</div>
                <div style={{ fontSize: "14px", marginTop: "12px" }}>
                  <div style={{ display: "flex", justifyContent: "space-between", paddingBottom: "8px", borderBottom: "1px solid var(--border-color)", fontWeight: "600" }}>
                    <span>Base Score</span>
                    <span>100</span>
                  </div>
                  {cachedData.deductions?.length > 0 ? (
                    cachedData.deductions.map((deduction, i) => (
                      <div key={i} style={{ display: "flex", justifyContent: "space-between", padding: "8px 0", borderBottom: "1px solid var(--border-color)", color: "var(--text-danger)" }}>
                        <span>
                          <strong>{deduction.check.replace(/_/g, " ")}</strong>: {deduction.reason}
                        </span>
                        <span>-{deduction.penalty}</span>
                      </div>
                    ))
                  ) : (
                    <div style={{ padding: "8px 0", borderBottom: "1px solid var(--border-color)", color: "var(--text-muted)" }}>
                      No flags triggered.
                    </div>
                  )}
                  {cachedData.algorithmic_score !== undefined && (
                    <div style={{ display: "flex", justifyContent: "space-between", padding: "8px 0", borderBottom: "1px solid var(--border-color)", fontWeight: "600", background: "var(--surface-sunken)" }}>
                      <span>Algorithmic Score</span>
                      <span>{cachedData.algorithmic_score}</span>
                    </div>
                  )}
                  {cachedData.gemma_adjustment !== undefined && (
                    <div style={{ display: "flex", justifyContent: "space-between", padding: "8px 0", borderBottom: "1px solid var(--border-color)", color: cachedData.gemma_adjustment > 0 ? "var(--text-success)" : (cachedData.gemma_adjustment < 0 ? "var(--text-danger)" : "inherit") }}>
                      <span>
                        <strong>Gemma Adjustment</strong>: {cachedData.gemma_adjustment_justification}
                      </span>
                      <span>{cachedData.gemma_adjustment > 0 ? `+${cachedData.gemma_adjustment}` : cachedData.gemma_adjustment}</span>
                    </div>
                  )}
                  <div style={{ display: "flex", justifyContent: "space-between", paddingTop: "8px", fontWeight: "bold", fontSize: "16px" }}>
                    <span>Final Score</span>
                    <span>{cachedData.final_score ?? cachedData.score}</span>
                  </div>
                </div>
              </div>

              {/* Flagged Reasons */}
              {cachedData.flagged_reasons.length > 0 && (
                <div className="panel-card">
                  <div className="panel-card-header">Flagged Reasons</div>
                  <div className="flagged-chips">
                    {cachedData.flagged_reasons.map((reason, i) => (
                      <span key={i} className="flagged-chip">
                        {reason}
                      </span>
                    ))}
                  </div>
                </div>
              )}

              {/* Recommended Action */}
              <div className={`action-callout action-${cachedData.recommended_action}`}>
                <BookOpen size={16} />
                <span>
                  Recommended Action:{" "}
                  <strong>
                    {cachedData.recommended_action.replace(/_/g, " ").toUpperCase()}
                  </strong>
                </span>
              </div>

              {/* Signals Grid */}
              <div className="panel-card">
                <div className="panel-card-header">
                  Stage 2 — Deterministic Signals
                </div>
                <div className="signals-grid">
                  {Object.entries(cachedData.signals).map(
                    ([key, value]) => (
                      <SignalCard
                        key={key}
                        signalKey={key}
                        data={value}
                      />
                    ),
                  )}
                </div>
              </div>

              {/* Reasoning Narrative — THE hero element */}
              <div className="panel-card">
                <ReasoningNarrative
                  narrative={cachedData.reasoning_narrative}
                />
              </div>
            </div>
          </div>

          {/* Officer Actions */}
          <div className="officer-actions">
            <ActionButton
              label="Approve"
              status="approved"
              icon={<CheckCircle2 size={16} />}
              className="officer-btn-approve"
              loading={actionLoading}
              success={actionSuccess}
              onClick={() => setConfirmAction("approved")}
            />
            <ActionButton
              label="Escalate"
              status="escalated"
              icon={<AlertTriangle size={16} />}
              className="officer-btn-escalate"
              loading={actionLoading}
              success={actionSuccess}
              onClick={() => setConfirmAction("escalated")}
            />
            <ActionButton
              label="Request Documents"
              status="requires_documents"
              icon={<FileText size={16} />}
              className="officer-btn-request-docs"
              loading={actionLoading}
              success={actionSuccess}
              onClick={() => setConfirmAction("requires_documents")}
            />
          </div>

          {/* Audit Trail */}
          <details className="audit-trail-panel" style={{ marginBottom: "24px", background: "var(--surface-sunken)", padding: "16px", borderRadius: "8px", border: "1px solid var(--border-color)" }}>
            <summary style={{ cursor: "pointer", fontWeight: "600", color: "var(--text-muted)" }}>
              Audit Trail ({auditLog.length} events)
            </summary>
            <div style={{ marginTop: "12px", fontSize: "12px" }}>
              {auditLog.length === 0 ? (
                <span style={{ color: "var(--text-muted)" }}>No audit events recorded.</span>
              ) : (
                <ul style={{ listStyleType: "none", padding: 0, margin: 0 }}>
                  {auditLog.map((log, i) => (
                    <li key={i} style={{ marginBottom: "8px", borderBottom: "1px solid var(--border-color)", paddingBottom: "8px" }}>
                      <span style={{ color: "var(--text-muted)", display: "inline-block", width: "120px" }}>
                        {new Date(log.timestamp).toLocaleString("en-IN", { hour: "numeric", minute: "numeric", day: "numeric", month: "short" })}
                      </span>
                      <strong>{log.officer_uid}</strong> {log.action}
                    </li>
                  ))}
                </ul>
              )}
            </div>
          </details>

          {/* Conversational Audit Agent Chat */}
          <ChatPanelWithHistoryExport
            caseId={id}
            onHistoryChange={setConversationHistory}
          />
        </div>
      )}

      {/* Confirmation Dialog */}
      {confirmAction && (
        <div className="confirm-overlay" onClick={() => setConfirmAction(null)}>
          <div
            className="confirm-dialog"
            onClick={(e) => e.stopPropagation()}
          >
            <h4>Confirm Action</h4>
            <p>
              Are you sure you want to{" "}
              <strong>
                {confirmAction.replace(/_/g, " ")}
              </strong>{" "}
              this case?
            </p>
            <div className="confirm-actions">
              <button
                className="confirm-cancel"
                onClick={() => setConfirmAction(null)}
              >
                Cancel
              </button>
              <button
                className={`confirm-proceed officer-action-btn officer-btn-${
                  confirmAction === "approved"
                    ? "approve"
                    : confirmAction === "escalated"
                      ? "escalate"
                      : "request-docs"
                }`}
                onClick={() => handleAction(confirmAction)}
              >
                Confirm
              </button>
            </div>
          </div>
        </div>
      )}
    </div>
  );
}

/* -- Helper: Action button with loading/success states -- */
function ActionButton({
  label,
  status,
  icon,
  className,
  loading,
  success,
  onClick,
}: {
  label: string;
  status: string;
  icon: React.ReactNode;
  className: string;
  loading: string | null;
  success: string | null;
  onClick: () => void;
}) {
  const isLoading = loading === status;
  const isSuccess = success === status;

  return (
    <button
      className={`officer-action-btn ${className} ${isSuccess ? "success-flash" : ""}`}
      disabled={loading !== null}
      onClick={onClick}
    >
      {isLoading ? <Loader2 size={16} className="animate-spin" /> : icon}
      {isLoading ? "Updating…" : isSuccess ? "Done ✓" : label}
    </button>
  );
}

/* -- ChatPanel wrapper that exposes conversation history for PDF export -- */
function ChatPanelWithHistoryExport({
  caseId,
  onHistoryChange,
}: {
  caseId: string;
  onHistoryChange: (history: ConversationTurn[]) => void;
}) {
  return (
    <ChatPanel caseId={caseId} onMessagesChange={onHistoryChange} />
  );
}
