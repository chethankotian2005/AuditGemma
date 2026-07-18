interface ConfidenceBadgeProps {
  confidence: "high" | "moderate" | "low";
}

const config = {
  high: {
    label: "High Confidence",
    className: "confidence-badge confidence-high",
  },
  moderate: {
    label: "Moderate Confidence",
    className: "confidence-badge confidence-moderate",
  },
  low: {
    label: "Low Confidence",
    className: "confidence-badge confidence-low",
  },
};

export default function ConfidenceBadge({ confidence }: ConfidenceBadgeProps) {
  const { label, className } = config[confidence];
  return <span className={className}>{label}</span>;
}
