"use client";

import { useState } from "react";
import { FileDown, Loader2 } from "lucide-react";
import type { CaseDetail, ConversationTurn, AuditLogEntry } from "@/lib/types";
import { formatDeductionReason } from "@/lib/score-utils";

interface ReportExportProps {
  caseData: CaseDetail;
  conversationHistory: ConversationTurn[];
  auditLog?: AuditLogEntry[];
}

export default function ReportExport({
  caseData,
  conversationHistory,
  auditLog = [],
}: ReportExportProps) {
  const [isGenerating, setIsGenerating] = useState(false);

  const handleExport = async () => {
    setIsGenerating(true);
    try {
      // Dynamic import to avoid SSR issues with @react-pdf/renderer
      const { pdf, Document, Page, Text, View, StyleSheet } = await import(
        "@react-pdf/renderer"
      );

      const styles = StyleSheet.create({
        page: {
          padding: 40,
          fontFamily: "Helvetica",
          fontSize: 10,
          color: "#1a1a2e",
          backgroundColor: "#ffffff",
        },
        header: {
          flexDirection: "row",
          justifyContent: "space-between",
          alignItems: "center",
          marginBottom: 24,
          borderBottomWidth: 2,
          borderBottomColor: "#6366f1",
          paddingBottom: 12,
        },
        headerTitle: {
          fontSize: 18,
          fontFamily: "Helvetica-Bold",
          color: "#0a0e17",
        },
        headerSubtitle: {
          fontSize: 9,
          color: "#64748b",
        },
        section: {
          marginBottom: 16,
        },
        sectionTitle: {
          fontSize: 13,
          fontFamily: "Helvetica-Bold",
          color: "#0a0e17",
          marginBottom: 8,
          borderBottomWidth: 1,
          borderBottomColor: "#e2e8f0",
          paddingBottom: 4,
        },
        row: {
          flexDirection: "row",
          marginBottom: 4,
        },
        label: {
          width: 140,
          fontFamily: "Helvetica-Bold",
          fontSize: 10,
          color: "#475569",
        },
        value: {
          flex: 1,
          fontSize: 10,
        },
        scoreValue: {
          fontSize: 24,
          fontFamily: "Helvetica-Bold",
        },
        flagChip: {
          backgroundColor: "#fef3c7",
          padding: "3 8",
          marginRight: 6,
          marginBottom: 4,
          borderRadius: 3,
          fontSize: 9,
          color: "#92400e",
        },
        flagRow: {
          flexDirection: "row",
          flexWrap: "wrap",
          marginBottom: 8,
        },
        narrativeStep: {
          marginBottom: 8,
          paddingLeft: 12,
          borderLeftWidth: 2,
          borderLeftColor: "#6366f1",
        },
        narrativeStepNum: {
          fontSize: 8,
          color: "#6366f1",
          fontFamily: "Helvetica-Bold",
          marginBottom: 2,
        },
        narrativeText: {
          fontSize: 10,
          lineHeight: 1.5,
          color: "#334155",
        },
        signalGrid: {
          flexDirection: "row",
          flexWrap: "wrap",
          gap: 8,
        },
        signalBox: {
          width: "48%",
          borderWidth: 1,
          borderColor: "#e2e8f0",
          borderRadius: 4,
          padding: 8,
          marginBottom: 8,
        },
        signalLabel: {
          fontSize: 9,
          fontFamily: "Helvetica-Bold",
          color: "#475569",
          marginBottom: 4,
        },
        signalValue: {
          fontSize: 9,
          color: "#1e293b",
        },
        chatMessage: {
          marginBottom: 8,
          paddingLeft: 8,
          borderLeftWidth: 2,
        },
        chatOfficer: {
          borderLeftColor: "#6366f1",
        },
        chatGemma: {
          borderLeftColor: "#22c55e",
        },
        chatRole: {
          fontSize: 8,
          fontFamily: "Helvetica-Bold",
          color: "#64748b",
          marginBottom: 2,
        },
        chatContent: {
          fontSize: 9,
          lineHeight: 1.4,
          color: "#334155",
        },
        footer: {
          position: "absolute",
          bottom: 24,
          left: 40,
          right: 40,
          borderTopWidth: 1,
          borderTopColor: "#e2e8f0",
          paddingTop: 8,
          flexDirection: "row",
          justifyContent: "space-between",
        },
        footerText: {
          fontSize: 8,
          color: "#94a3b8",
        },
        auditRow: {
          flexDirection: "row",
          marginBottom: 6,
          paddingBottom: 6,
          borderBottomWidth: 1,
          borderBottomColor: "#f1f5f9",
        },
        auditTime: {
          width: 100,
          fontSize: 8,
          color: "#64748b",
        },
        auditAction: {
          flex: 1,
          fontSize: 9,
          color: "#334155",
        },
      });

      const narrativeSteps = caseData.reasoning_narrative
        .split(/\n{2,}/)
        .map((s) => s.trim())
        .filter((s) => s.length > 0);

      const ReportDocument = () => (
        <Document>
          <Page size="A4" style={styles.page}>
            {/* Header */}
            <View style={styles.header}>
              <View>
                <Text style={styles.headerTitle}>
                  AuditGemma Compliance Report
                </Text>
                <Text style={styles.headerSubtitle}>
                  Case ID: {caseData.case_id}
                </Text>
              </View>
              <View>
                <Text style={styles.headerSubtitle}>
                  Generated: {new Date().toLocaleString("en-IN")}
                </Text>
              </View>
            </View>

            {/* Score Summary */}
            <View style={styles.section}>
              <Text style={styles.sectionTitle}>Assessment Summary</Text>
              <View style={styles.row}>
                <Text style={styles.label}>Risk Score</Text>
                <Text style={styles.scoreValue}>
                  {caseData.score}/100
                </Text>
              </View>
              <View style={styles.row}>
                <Text style={styles.label}>Confidence</Text>
                <Text style={styles.value}>
                  {caseData.confidence.toUpperCase()}
                </Text>
              </View>
              <View style={styles.row}>
                <Text style={styles.label}>Recommended Action</Text>
                <Text style={styles.value}>
                  {caseData.recommended_action
                    .replace(/_/g, " ")
                    .toUpperCase()}
                </Text>
              </View>
            </View>

            {/* Rejection Reason (If applicable) */}
            {caseData.status === "rejected" && caseData.rejection_reason && (
              <View style={styles.section}>
                <Text style={styles.sectionTitle}>Rejection Reason</Text>
                <View style={[styles.row, { backgroundColor: "#fef2f2", padding: 8, borderRadius: 4 }]}>
                  <Text style={[styles.value, { color: "#991b1b" }]}>
                    {caseData.rejection_reason}
                  </Text>
                </View>
              </View>
            )}

            {/* Flagged Reasons */}
            {caseData.deductions?.length > 0 && (
              <View style={styles.section}>
                <Text style={styles.sectionTitle}>Flagged Reasons</Text>
                <View style={styles.flagRow}>
                  {caseData.deductions.map((deduction, i) => (
                    <Text key={i} style={styles.flagChip}>
                      {formatDeductionReason(deduction, caseData.signals)}
                    </Text>
                  ))}
                </View>
              </View>
            )}

            {/* Signals */}
            <View style={styles.section}>
              <Text style={styles.sectionTitle}>
                Stage 2 — Deterministic Signals
              </Text>
              <View style={styles.signalGrid}>
                {Object.entries(caseData.signals).map(([key, val]) => (
                  <View key={key} style={styles.signalBox}>
                    <Text style={styles.signalLabel}>
                      {key.replace(/_/g, " ").toUpperCase()}
                    </Text>
                    <Text style={styles.signalValue}>
                      {typeof val === "object"
                        ? JSON.stringify(val, null, 1)
                        : String(val)}
                    </Text>
                  </View>
                ))}
              </View>
            </View>

            {/* Reasoning Narrative */}
            <View style={styles.section}>
              <Text style={styles.sectionTitle}>
                Stage 3 — Reasoning Narrative
              </Text>
              {narrativeSteps.map((step, i) => (
                <View key={i} style={styles.narrativeStep}>
                  <Text style={styles.narrativeStepNum}>
                    Step {i + 1}
                  </Text>
                  <Text style={styles.narrativeText}>{step}</Text>
                </View>
              ))}
            </View>

            {/* Audit Trail */}
            {auditLog && auditLog.length > 0 && (
              <View style={styles.section}>
                <Text style={styles.sectionTitle}>Officer Audit Trail</Text>
                {auditLog.map((log, i) => (
                  <View key={i} style={styles.auditRow}>
                    <Text style={styles.auditTime}>
                      {new Date(log.timestamp).toLocaleString("en-IN", {
                        hour: "numeric", minute: "numeric", day: "numeric", month: "short", year: "numeric"
                      })}
                    </Text>
                    <Text style={styles.auditAction}>
                      <Text style={{ fontFamily: "Helvetica-Bold" }}>{log.officer_uid} </Text>
                      {log.action}
                    </Text>
                  </View>
                ))}
              </View>
            )}

            {/* Footer */}
            <View style={styles.footer} fixed>
              <Text style={styles.footerText}>
                Generated by AuditGemma — for internal compliance use only
              </Text>
              <Text style={styles.footerText}>
                © {new Date().getFullYear()} AuditGemma
              </Text>
            </View>
          </Page>

          {/* Conversation transcript (if any) on a second page */}
          {conversationHistory.length > 0 && (
            <Page size="A4" style={styles.page}>
              <View style={styles.section}>
                <Text style={styles.sectionTitle}>
                  Audit Conversation Transcript
                </Text>
                <Text style={styles.headerSubtitle}>
                  {conversationHistory.length} messages in this session
                </Text>
              </View>

              {conversationHistory.map((msg, i) => (
                <View
                  key={i}
                  style={[
                    styles.chatMessage,
                    msg.role === "officer"
                      ? styles.chatOfficer
                      : styles.chatGemma,
                  ]}
                >
                  <Text style={styles.chatRole}>
                    {msg.role === "officer" ? "OFFICER" : "GEMMA"}
                  </Text>
                  <Text style={styles.chatContent}>{msg.content}</Text>
                </View>
              ))}

              {/* Footer */}
              <View style={styles.footer} fixed>
                <Text style={styles.footerText}>
                  Generated by AuditGemma — for internal compliance use only
                </Text>
                <Text style={styles.footerText}>
                  © {new Date().getFullYear()} AuditGemma
                </Text>
              </View>
            </Page>
          )}
        </Document>
      );

      const blob = await pdf(<ReportDocument />).toBlob();
      const url = URL.createObjectURL(blob);
      const a = document.createElement("a");
      a.href = url;
      a.download = `auditgemma-report-${caseData.case_id.slice(0, 8)}.pdf`;
      document.body.appendChild(a);
      a.click();
      document.body.removeChild(a);
      URL.revokeObjectURL(url);
    } catch (err) {
      console.error("PDF generation failed:", err);
      alert("Failed to generate PDF report. Please try again.");
    } finally {
      setIsGenerating(false);
    }
  };

  return (
    <button
      onClick={handleExport}
      disabled={isGenerating}
      className="report-export-btn"
    >
      {isGenerating ? (
        <>
          <Loader2 size={16} className="animate-spin" />
          Generating Report…
        </>
      ) : (
        <>
          <FileDown size={16} />
          Export PDF Report
        </>
      )}
    </button>
  );
}
