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

  switch (key) {
    case "benfords_law":
      if (data.conformity === "acceptable") return "ok";
      if (data.conformity === "suspicious") return "warning";
      return "alert";
    case "transaction_velocity":
      return data.spike_detected ? "alert" : "ok";
    case "threshold_anomaly":
      return data.has_anomalies ? "alert" : "ok";
    case "entity_consistency":
      return data.consistent ? "ok" : "alert";
    default:
      return "warning";
  }
}

// eslint-disable-next-line @typescript-eslint/no-explicit-any
function renderSignalData(key: string, data: any) {
  if (!data) return <span className="signal-no-data">No data</span>;

  switch (key) {
    case "benfords_law":
      return (
        <div className="signal-metrics">
          <div className="signal-metric">
            <span className="signal-metric-label">Conformity</span>
            <span className="signal-metric-value">{data.conformity ?? "—"}</span>
          </div>
          <div className="signal-metric">
            <span className="signal-metric-label">χ²</span>
            <span className="signal-metric-value">
              {typeof data.chi_squared === "number"
                ? data.chi_squared.toFixed(3)
                : "—"}
            </span>
          </div>
          <div className="signal-metric">
            <span className="signal-metric-label">p-value</span>
            <span className="signal-metric-value">
              {typeof data.p_value === "number"
                ? data.p_value.toFixed(4)
                : "—"}
            </span>
          </div>
        </div>
      );

    case "transaction_velocity":
      return (
        <div className="signal-metrics">
          <div className="signal-metric">
            <span className="signal-metric-label">Rate/day</span>
            <span className="signal-metric-value">
              {typeof data.rate_per_day === "number"
                ? data.rate_per_day.toFixed(1)
                : "—"}
            </span>
          </div>
          <div className="signal-metric">
            <span className="signal-metric-label">Spike</span>
            <span className="signal-metric-value">
              {data.spike_detected ? "⚠ Detected" : "None"}
            </span>
          </div>
          {data.spike_ratio && (
            <div className="signal-metric">
              <span className="signal-metric-label">Spike ratio</span>
              <span className="signal-metric-value">
                {data.spike_ratio.toFixed(2)}×
              </span>
            </div>
          )}
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
              {Array.isArray(data.outliers) ? data.outliers.length : "0"}
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
              {data.consistent ? "✓ Yes" : "✗ No"}
            </span>
          </div>
          {Array.isArray(data.mismatches) && data.mismatches.length > 0 && (
            <div className="signal-metric signal-metric-wide">
              <span className="signal-metric-label">Mismatches</span>
              <span className="signal-metric-value signal-mismatches">
                {data.mismatches.join(", ")}
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
