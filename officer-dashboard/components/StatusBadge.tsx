import type { CaseStatusValue } from "@/lib/types";
import { formatStatus } from "@/lib/score-utils";

interface StatusBadgeProps {
  status: CaseStatusValue;
}

const classMap: Record<CaseStatusValue, string> = {
  pending: "status-badge status-pending",
  approved: "status-badge status-approved",
  escalated: "status-badge status-escalated",
  requires_documents: "status-badge status-requires-docs",
};

export default function StatusBadge({ status }: StatusBadgeProps) {
  return (
    <span className={classMap[status] ?? "status-badge"}>
      {formatStatus(status)}
    </span>
  );
}
