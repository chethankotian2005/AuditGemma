"use client";

import { useEffect, useState, useRef } from "react";
import { scoreToHsl, scoreGradientCSS } from "@/lib/score-utils";

interface ScoreGradientProps {
  score: number;
  /** "bar" = large hero bar for Case Detail, "chip" = compact pill for table */
  variant?: "bar" | "chip";
  /** Whether to animate the score counting up from 0 */
  animate?: boolean;
}

export default function ScoreGradient({
  score,
  variant = "chip",
  animate = false,
}: ScoreGradientProps) {
  const [displayScore, setDisplayScore] = useState(animate ? 0 : score);
  const animationRef = useRef<number | null>(null);
  const startTimeRef = useRef<number | null>(null);

  useEffect(() => {
    if (!animate) {
      setDisplayScore(score);
      return;
    }

    const duration = 1200; // ms
    startTimeRef.current = null;

    function step(timestamp: number) {
      if (!startTimeRef.current) startTimeRef.current = timestamp;
      const elapsed = timestamp - startTimeRef.current;
      const progress = Math.min(elapsed / duration, 1);
      // Ease-out cubic
      const eased = 1 - Math.pow(1 - progress, 3);
      setDisplayScore(Math.round(eased * score));

      if (progress < 1) {
        animationRef.current = requestAnimationFrame(step);
      }
    }

    animationRef.current = requestAnimationFrame(step);
    return () => {
      if (animationRef.current) cancelAnimationFrame(animationRef.current);
    };
  }, [score, animate]);

  const color = scoreToHsl(displayScore);

  if (variant === "chip") {
    return (
      <span
        className="score-chip"
        style={{
          backgroundColor: `${scoreToHsl(displayScore)}20`,
          color: color,
          borderColor: `${color}40`,
        }}
      >
        {displayScore}
      </span>
    );
  }

  // Bar variant — large hero display
  return (
    <div className="score-bar-container">
      <div className="score-bar-label-row">
        <span className="score-bar-value" style={{ color }}>
          {displayScore}
        </span>
        <span className="score-bar-max">/ 100</span>
      </div>
      <div className="score-bar-track">
        <div
          className="score-bar-fill"
          style={{
            width: `${displayScore}%`,
            background: scoreGradientCSS(),
          }}
        />
        {/* Score marker */}
        <div
          className="score-bar-marker"
          style={{
            left: `${displayScore}%`,
            backgroundColor: color,
            boxShadow: `0 0 12px ${color}80`,
          }}
        />
      </div>
      <div className="score-bar-labels">
        <span>High Risk</span>
        <span>Moderate</span>
        <span>Low Risk</span>
      </div>
    </div>
  );
}
