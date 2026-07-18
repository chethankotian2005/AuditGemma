// =============================================================================
// Score utility functions — color interpolation, formatting
// =============================================================================

/**
 * Maps a score (0-100) to an HSL color string using a continuous gradient:
 *   0   → deep red    hsl(0, 80%, 45%)
 *   50  → amber       hsl(45, 90%, 50%)
 *   100 → green       hsl(145, 70%, 42%)
 *
 * Uses piecewise linear interpolation through the amber midpoint so that
 * "gray zone" cases (40-70) get distinguishable amber/yellow tones rather
 * than a murky red-green mix.
 */
export function scoreToHsl(score: number): string {
  const s = Math.max(0, Math.min(100, score));

  let h: number, sat: number, light: number;

  if (s <= 50) {
    // Red → Amber
    const t = s / 50;
    h = lerp(0, 45, t);
    sat = lerp(80, 90, t);
    light = lerp(45, 50, t);
  } else {
    // Amber → Green
    const t = (s - 50) / 50;
    h = lerp(45, 145, t);
    sat = lerp(90, 70, t);
    light = lerp(50, 42, t);
  }

  return `hsl(${Math.round(h)}, ${Math.round(sat)}%, ${Math.round(light)}%)`;
}

/**
 * Returns a CSS linear-gradient string representing the full 0-100 score spectrum.
 */
export function scoreGradientCSS(): string {
  const stops = [0, 10, 20, 30, 40, 50, 60, 70, 80, 90, 100];
  const colorStops = stops.map((s) => `${scoreToHsl(s)} ${s}%`).join(", ");
  return `linear-gradient(to right, ${colorStops})`;
}

/**
 * Returns a muted/darker variant of the score color for backgrounds.
 */
export function scoreToMutedHsl(score: number): string {
  const s = Math.max(0, Math.min(100, score));

  let h: number, sat: number, light: number;

  if (s <= 50) {
    const t = s / 50;
    h = lerp(0, 45, t);
    sat = lerp(50, 55, t);
    light = lerp(18, 20, t);
  } else {
    const t = (s - 50) / 50;
    h = lerp(45, 145, t);
    sat = lerp(55, 45, t);
    light = lerp(20, 18, t);
  }

  return `hsl(${Math.round(h)}, ${Math.round(sat)}%, ${Math.round(light)}%)`;
}

/** Format a score as a padded string, e.g. "07" or "85" */
export function formatScore(score: number): string {
  return Math.round(score).toString().padStart(2, "0");
}

export function formatDeductionReason(deduction: any, signals: any): string {
  const data = signals?.[deduction.check];
  if (!data) return deduction.reason;

  if (deduction.check === "transaction_velocity") {
    return `High velocity: ${data.max_transactions_in_window} transactions in ${data.window_hours || 24} hours.`;
  }
  if (deduction.check === "benfords_law") {
    return `Chi-square value ${data.chi_square} exceeds threshold ${data.chi_square_critical_value}.`;
  }
  if (deduction.check === "threshold_anomaly") {
    const maxOutlier = data.outliers?.reduce((max: any, o: any) => 
      Math.abs(o.modified_z_score) > Math.abs(max.modified_z_score) ? o : max
    , data.outliers[0]);
    if (maxOutlier) {
      return `MAD outlier detected: ₹${maxOutlier.amount} with Z-score ${maxOutlier.modified_z_score}.`;
    }
  }
  return deduction.reason;
}

/** Format an ISO timestamp to a relative time string */
export function formatRelativeTime(isoString: string): string {
  const date = new Date(isoString);
  const now = new Date();
  const diffMs = now.getTime() - date.getTime();
  const diffSec = Math.floor(diffMs / 1000);
  const diffMin = Math.floor(diffSec / 60);
  const diffHour = Math.floor(diffMin / 60);
  const diffDay = Math.floor(diffHour / 24);

  if (diffSec < 60) return "just now";
  if (diffMin < 60) return `${diffMin}m ago`;
  if (diffHour < 24) return `${diffHour}h ago`;
  if (diffDay < 7) return `${diffDay}d ago`;
  return date.toLocaleDateString("en-IN", {
    day: "numeric",
    month: "short",
    year: "numeric",
  });
}

/** Format status values for display */
export function formatStatus(status: string): string {
  const map: Record<string, string> = {
    pending: "Pending",
    approved: "Approved",
    escalated: "Escalated",
    requires_documents: "Docs Required",
  };
  return map[status] ?? status;
}

/** Linear interpolation */
function lerp(a: number, b: number, t: number): number {
  return a + (b - a) * t;
}
