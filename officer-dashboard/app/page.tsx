"use client";

import { useEffect, useState, useMemo } from "react";
import { useRouter } from "next/navigation";
import { Search, Filter, RefreshCw } from "lucide-react";
import { getCases, ApiError } from "@/lib/api";
import { useAuth } from "@/context/AuthContext";
import type { CaseListItem, CaseStatusValue } from "@/lib/types";
import ScoreGradient from "@/components/ScoreGradient";
import StatusBadge from "@/components/StatusBadge";
import SkeletonLoader from "@/components/SkeletonLoader";

export default function CaseQueuePage() {
  const router = useRouter();
  const { user, logout } = useAuth();
  const [cases, setCases] = useState<CaseListItem[]>([]);
  const [loading, setLoading] = useState(true);
  const [error, setError] = useState<string | null>(null);

  // Filters
  const [statusFilter, setStatusFilter] = useState<string>("all");
  const [scoreMin, setScoreMin] = useState(0);
  const [scoreMax, setScoreMax] = useState(100);
  const [searchQuery, setSearchQuery] = useState("");

  const fetchCases = async () => {
    if (!user) return; // Don't fire API calls pre-login
    setLoading(true);
    setError(null);
    try {
      const data = await getCases();
      setCases(data);
    } catch (err) {
      if (err instanceof ApiError && (err.status === 401 || err.status === 403)) {
        logout("session_expired");
        return;
      }
      setError(
        err instanceof Error ? err.message : "Failed to fetch cases",
      );
    } finally {
      setLoading(false);
    }
  };

  useEffect(() => {
    if (user) {
      fetchCases();
    } else {
      setLoading(false);
    }
  }, [user]);

  const filteredCases = useMemo(() => {
    return cases.filter((c) => {
      if (statusFilter !== "all" && c.status !== statusFilter) return false;
      if (c.score < scoreMin || c.score > scoreMax) return false;
      if (
        searchQuery &&
        !c.case_id.toLowerCase().includes(searchQuery.toLowerCase())
      )
        return false;
      return true;
    });
  }, [cases, statusFilter, scoreMin, scoreMax, searchQuery]);

  return (
    <div className="page-container">
      {/* Header */}
      <div className="page-header">
        <div>
          <h1 className="page-title">Case Queue</h1>
          <p className="page-subtitle">
            {cases.length} total case{cases.length !== 1 ? "s" : ""} ·{" "}
            {filteredCases.length} showing
          </p>
        </div>
        <button
          onClick={fetchCases}
          className="officer-action-btn officer-btn-request-docs"
          disabled={loading}
        >
          <RefreshCw size={14} className={loading ? "animate-spin" : ""} />
          Refresh
        </button>
      </div>

      {/* Filters */}
      <div className="filters-bar">
        <Filter size={14} style={{ color: "var(--text-muted)" }} />

        <select
          className="filter-select"
          value={statusFilter}
          onChange={(e) => setStatusFilter(e.target.value)}
        >
          <option value="all">All Statuses</option>
          <option value="pending">Pending</option>
          <option value="approved">Approved</option>
          <option value="escalated">Escalated</option>
          <option value="requires_documents">Docs Required</option>
        </select>

        <div className="filter-score-range">
          <span>Score</span>
          <input
            type="range"
            min={0}
            max={100}
            value={scoreMin}
            onChange={(e) => setScoreMin(Number(e.target.value))}
          />
          <span style={{ fontFamily: "var(--font-mono)", fontSize: "12px" }}>
            {scoreMin}
          </span>
          <span>—</span>
          <input
            type="range"
            min={0}
            max={100}
            value={scoreMax}
            onChange={(e) => setScoreMax(Number(e.target.value))}
          />
          <span style={{ fontFamily: "var(--font-mono)", fontSize: "12px" }}>
            {scoreMax}
          </span>
        </div>

        <div style={{ position: "relative" }}>
          <Search
            size={14}
            style={{
              position: "absolute",
              left: "10px",
              top: "50%",
              transform: "translateY(-50%)",
              color: "var(--text-muted)",
            }}
          />
          <input
            type="text"
            className="filter-input"
            placeholder="Search by case ID…"
            value={searchQuery}
            onChange={(e) => setSearchQuery(e.target.value)}
            style={{ paddingLeft: "32px" }}
          />
        </div>
      </div>

      {/* Error state */}
      {error && (
        <div className="chat-error" style={{ marginBottom: "16px" }}>
          <p>{error}</p>
          <button onClick={fetchCases} className="chat-error-dismiss">
            Retry
          </button>
        </div>
      )}

      {/* Table */}
      <div className="cases-table-wrap animate-fade-in">
        <table className="cases-table">
          <thead>
            <tr>
              <th>Case ID</th>
              <th>Score</th>
              <th>Status</th>
            </tr>
          </thead>
          <tbody>
            {loading ? (
              <SkeletonLoader variant="table-row" count={6} />
            ) : filteredCases.length === 0 ? (
              <tr>
                <td colSpan={3}>
                  <div className="table-empty">
                    <p className="table-empty-title">
                      {cases.length === 0
                        ? "No cases yet"
                        : "No cases match filters"}
                    </p>
                    <p className="table-empty-hint">
                      {cases.length === 0
                        ? "Score a loan application via the API to see cases here."
                        : "Try adjusting your filter criteria."}
                    </p>
                  </div>
                </td>
              </tr>
            ) : (
              filteredCases.map((c) => (
                <tr
                  key={c.case_id}
                  onClick={() => router.push(`/case/${c.case_id}`)}
                >
                  <td className="case-id-cell">
                    {c.case_id.slice(0, 8)}…
                  </td>
                  <td>
                    <ScoreGradient
                      score={c.score}
                      variant="chip"
                    />
                  </td>
                  <td>
                    <StatusBadge
                      status={c.status as CaseStatusValue}
                    />
                  </td>
                </tr>
              ))
            )}
          </tbody>
        </table>
      </div>
    </div>
  );
}
