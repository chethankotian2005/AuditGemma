interface ReasoningNarrativeProps {
  narrative: string;
}

/**
 * Renders the Gemma reasoning narrative as visually distinct, numbered
 * "reasoning step" blocks — NOT a wall of text.
 *
 * Splits on double-newlines (paragraph breaks) and renders each paragraph
 * as a separate step card with a left-border accent and step number.
 */
export default function ReasoningNarrative({
  narrative,
}: ReasoningNarrativeProps) {
  // Split on double-newline or lines that look like numbered steps
  const steps = narrative
    .split(/\n{2,}/)
    .map((s) => s.trim())
    .filter((s) => s.length > 0);

  if (steps.length === 0) {
    return (
      <div className="reasoning-empty">
        No reasoning narrative available for this case.
      </div>
    );
  }

  return (
    <div className="reasoning-container">
      <h3 className="reasoning-title">Reasoning Narrative</h3>
      <p className="reasoning-subtitle">
        Gemma&apos;s step-by-step analysis grounded in Stage 2 deterministic
        signals
      </p>
      <div className="reasoning-steps">
        {steps.map((step, index) => (
          <div key={index} className="reasoning-step">
            <div className="reasoning-step-number">
              <span>{index + 1}</span>
            </div>
            <div className="reasoning-step-content">
              <p>{cleanStepText(step)}</p>
            </div>
          </div>
        ))}
      </div>
    </div>
  );
}

/** Remove leading numbering like "1." or "Step 1:" that the model might prepend */
function cleanStepText(text: string): string {
  return text.replace(/^(?:step\s*\d+[:.]\s*|\d+[.)]\s*)/i, "").trim();
}
