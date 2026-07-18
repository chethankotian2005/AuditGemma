import {
  Activity,
  BarChart3,
  GitCompareArrows,
  TrendingUp,
} from "lucide-react";

interface SignalCardProps {
  signalKey: string;
  // eslint-disable-next-line @typescript-eslint/no-explicit-any
  data: any;
}

const signalMeta: Record<
  string,
  { label: string; icon: React.ReactNode; description: string }
> = {
  benfords_law: {
    label: "Benford's Law",
    icon: <BarChart3 size={18} />,
    description: "First-digit distribution conformity analysis",
  },
  transaction_velocity: {
    label: "Transaction Velocity",
    icon: <TrendingUp size={18} />,
    description: "Transaction rate and spike detection",
  },
  threshold_anomaly: {
    label: "Threshold Anomaly",
    icon: <Activity size={18} />,
    description: "Median/MAD robust outlier detection",
  },
  entity_consistency: {
    label: "Entity Consistency",
    icon: <GitCompareArrows size={18} />,
    description: "Cross-document entity matching",
  },
};

export default function SignalCard({ signalKey, data }: SignalCardProps) {
  const meta = signalMeta[signalKey] ?? {
    label: signalKey,
    icon: <Activity size={18} />,
    description: "",
  };

  // Derive a status indicator from the signal data
  const status = deriveStatus(signalKey, data);

  return (
    <div className={`signal-card signal-${status}`}>
      <div className="signal-card-header">
        <span className="signal-card-icon">{meta.icon}</span>
        <span className="signal-card-label">{meta.label}</span>
        <span className={`signal-status-dot signal-dot-${status}`} />
      </div>
      <p className="signal-card-desc">{meta.description}</p>
      <div className="signal-card-body">
        {renderSignalData(signalKey, data)}
      </div>
    </div>
  );
}

function deriveStatus(
  key: string,
  // eslint-disable-next-line @typescript-eslint/no-explicit-any
  data: any,
): "ok" | "warning" | "alert" {
  if (!data) return "warning";
  if (data.applicable === false) return "ok";

  if (data.flagged === true) {
    if (data.severity === "high") return "alert";
    return "warning";
  }

  return "ok";
}

// eslint-disable-next-line @typescript-eslint/no-explicit-any
function renderSignalData(key: string, data: any) {
  if (!data) return <span className="signal-no-data">No data</span>;
  if (data.applicable === false) {
    return <div className="signal-no-data" style={{ padding: "12px 0", color: "var(--text-muted)", fontSize: "13px" }}>Not Applicable: {data.reason || "Not enough data to run check"}</div>;
  }

  switch (key) {
    case "benfords_law":
      return (
        <div className="signal-metrics">
          <div className="signal-metric">
            <span className="signal-metric-label">Sample Size</span>
            <span className="signal-metric-value">{data.sample_size ?? "—"}</span>
          </div>
          <div className="signal-metric">
            <span className="signal-metric-label">χ²</span>
            <span className="signal-metric-value">
              {typeof data.chi_square === "number"
                ? data.chi_square.toFixed(3)
                : data.chi_square ?? "—"}
            </span>
          </div>
          <div className="signal-metric">
            <span className="signal-metric-label">Status</span>
            <span className="signal-metric-value">
              {data.flagged ? "✗ Non-conforming" : "✓ Acceptable"}
            </span>
          </div>
        </div>
      );

    case "transaction_velocity":
      return (
        <div className="signal-metrics">
          <div className="signal-metric">
            <span className="signal-metric-label">Max in Window</span>
            <span className="signal-metric-value">
              {data.max_transactions_in_window ?? "—"}
            </span>
          </div>
          <div className="signal-metric">
            <span className="signal-metric-label">Spike</span>
            <span className="signal-metric-value">
              {data.flagged ? "⚠ Detected" : "None"}
            </span>
          </div>
          <div className="signal-metric">
            <span className="signal-metric-label">Total Txns</span>
            <span className="signal-metric-value">
              {data.total_transactions ?? "—"}
            </span>
          </div>
        </div>
      );

    case "threshold_anomaly":
      return (
        <div className="signal-metrics">
          <div className="signal-metric">
            <span className="signal-metric-label">Median</span>
            <span className="signal-metric-value">
              {typeof data.median === "number"
                ? `₹${data.median.toLocaleString("en-IN")}`
                : "—"}
            </span>
          </div>
          <div className="signal-metric">
            <span className="signal-metric-label">MAD</span>
            <span className="signal-metric-value">
              {typeof data.mad === "number"
                ? `₹${data.mad.toLocaleString("en-IN")}`
                : "—"}
            </span>
          </div>
          <div className="signal-metric">
            <span className="signal-metric-label">Outliers</span>
            <span className="signal-metric-value">
              {data.outlier_count ?? "0"}
            </span>
          </div>
        </div>
      );

    case "entity_consistency":
      return (
        <div className="signal-metrics">
          <div className="signal-metric">
            <span className="signal-metric-label">Consistent</span>
            <span className="signal-metric-value">
              {!data.flagged ? "✓ Yes" : "✗ No"}
            </span>
          </div>
          {Array.isArray(data.mismatches) && data.mismatches.length > 0 && (
            <div className="signal-metric signal-metric-wide">
              <span className="signal-metric-label">Mismatches</span>
              <span className="signal-metric-value signal-mismatches" style={{ whiteSpace: "pre-wrap", wordBreak: "break-word" }}>
                {data.mismatches.map((m: any) => 
                  typeof m === "string" ? m : `${m.field} (${m.document_a} vs ${m.document_b})`
                ).join("\n")}
              </span>
            </div>
          )}
        </div>
      );

    default:
      return (
        <pre className="signal-raw">{JSON.stringify(data, null, 2)}</pre>
      );
  }
}
