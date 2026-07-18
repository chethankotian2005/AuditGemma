"use client";

import {
  createContext,
  useContext,
  useState,
  useCallback,
  useEffect,
  type ReactNode,
} from "react";
import type { CaseScoreResponse } from "@/lib/types";

// ---------------------------------------------------------------------------
// Client-side cache for full CaseScoreResponse data.
//
// GET /case/{id} only returns { case_id, status, score, updated_at }.
// The full CaseScoreResponse (with reasoning_narrative, signals, flagged_reasons,
// confidence, recommended_action) is only available from POST /score.
//
// This context + localStorage cache stores those full responses so the Case
// Detail page can display them when navigating from the queue.
// ---------------------------------------------------------------------------

const STORAGE_KEY = "auditgemma_case_cache";

interface CaseDataContextType {
  /** Get a cached full score response by case_id */
  getCachedCase: (caseId: string) => CaseScoreResponse | null;
  /** Store a full score response in the cache */
  setCachedCase: (caseId: string, data: CaseScoreResponse) => void;
  /** All cached case IDs */
  cachedCaseIds: string[];
}

const CaseDataContext = createContext<CaseDataContextType | null>(null);

function loadFromStorage(): Record<string, CaseScoreResponse> {
  if (typeof window === "undefined") return {};
  try {
    const raw = localStorage.getItem(STORAGE_KEY);
    return raw ? JSON.parse(raw) : {};
  } catch {
    return {};
  }
}

function saveToStorage(cache: Record<string, CaseScoreResponse>) {
  if (typeof window === "undefined") return;
  try {
    localStorage.setItem(STORAGE_KEY, JSON.stringify(cache));
  } catch {
    // localStorage full or unavailable — silently fail
  }
}

export function CaseDataProvider({ children }: { children: ReactNode }) {
  const [cache, setCache] = useState<Record<string, CaseScoreResponse>>({});

  // Hydrate from localStorage on mount
  useEffect(() => {
    setCache(loadFromStorage());
  }, []);

  const getCachedCase = useCallback(
    (caseId: string): CaseScoreResponse | null => {
      return cache[caseId] ?? null;
    },
    [cache],
  );

  const setCachedCase = useCallback(
    (caseId: string, data: CaseScoreResponse) => {
      setCache((prev) => {
        const next = { ...prev, [caseId]: data };
        saveToStorage(next);
        return next;
      });
    },
    [],
  );

  const cachedCaseIds = Object.keys(cache);

  return (
    <CaseDataContext.Provider
      value={{ getCachedCase, setCachedCase, cachedCaseIds }}
    >
      {children}
    </CaseDataContext.Provider>
  );
}

export function useCaseData(): CaseDataContextType {
  const ctx = useContext(CaseDataContext);
  if (!ctx) {
    throw new Error("useCaseData must be used within a CaseDataProvider");
  }
  return ctx;
}
