interface SkeletonLoaderProps {
  /** Predefined skeleton layouts */
  variant?: "text" | "card" | "table-row" | "score-bar" | "chat-bubble";
  /** Number of skeleton items to render */
  count?: number;
}

export default function SkeletonLoader({
  variant = "text",
  count = 1,
}: SkeletonLoaderProps) {
  const items = Array.from({ length: count }, (_, i) => i);

  if (variant === "table-row") {
    return (
      <>
        {items.map((i) => (
          <tr key={i} className="skeleton-table-row">
            <td><div className="skeleton skeleton-text" style={{ width: "140px" }} /></td>
            <td><div className="skeleton skeleton-chip" /></td>
            <td><div className="skeleton skeleton-badge" /></td>
            <td><div className="skeleton skeleton-text" style={{ width: "80px" }} /></td>
          </tr>
        ))}
      </>
    );
  }

  if (variant === "score-bar") {
    return (
      <div className="skeleton-score-bar-wrap">
        <div className="skeleton skeleton-score-number" />
        <div className="skeleton skeleton-score-track" />
      </div>
    );
  }

  if (variant === "chat-bubble") {
    return (
      <div className="skeleton-chat-bubble">
        <div className="skeleton skeleton-text" style={{ width: "80%" }} />
        <div className="skeleton skeleton-text" style={{ width: "60%" }} />
        <div className="skeleton skeleton-text" style={{ width: "45%" }} />
      </div>
    );
  }

  if (variant === "card") {
    return (
      <>
        {items.map((i) => (
          <div key={i} className="skeleton-card">
            <div className="skeleton skeleton-text" style={{ width: "60%" }} />
            <div className="skeleton skeleton-text" style={{ width: "90%" }} />
            <div className="skeleton skeleton-text" style={{ width: "40%" }} />
          </div>
        ))}
      </>
    );
  }

  // Default: text lines
  return (
    <div className="skeleton-text-group">
      {items.map((i) => (
        <div
          key={i}
          className="skeleton skeleton-text"
          style={{ width: `${70 + Math.random() * 30}%` }}
        />
      ))}
    </div>
  );
}
