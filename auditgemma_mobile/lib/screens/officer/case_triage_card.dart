import 'package:flutter/material.dart';
import '../../models/case_model.dart';
import '../../theme/app_theme.dart';
import '../../widgets/score_gradient.dart';
import '../../widgets/confidence_badge.dart';
import '../../widgets/status_badge.dart';

/// The hero swipe card for officer triage.
class CaseTriageCard extends StatelessWidget {
  final CaseListItem caseItem;
  final VoidCallback onTap;

  const CaseTriageCard({
    super.key,
    required this.caseItem,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        decoration: BoxDecoration(
          color: AppTheme.bgSurface,
          borderRadius: BorderRadius.circular(20),
          border: Border.all(color: AppTheme.border),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.2),
              blurRadius: 10,
              offset: const Offset(0, 5),
            ),
          ],
        ),
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Header row
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    'Case ${caseItem.caseId.substring(0, 8)}',
                    style: const TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.w600,
                      color: AppTheme.textMuted,
                      fontFamily: 'monospace',
                    ),
                  ),
                  StatusBadge(status: caseItem.status),
                ],
              ),
              const Spacer(flex: 1),
              
              // Score Hero
              Center(
                child: ScoreGradientWidget(
                  score: caseItem.score,
                  variant: 'bar',
                ),
              ),
              
              const Spacer(flex: 1),
              
              // Mock Flagged reasons (In a real app, this would come from a preview endpoint or cached detail)
              const Text(
                'FLAGGED REASONS',
                style: TextStyle(
                  color: AppTheme.textMuted,
                  fontSize: 10,
                  fontWeight: FontWeight.w700,
                  letterSpacing: 1,
                ),
              ),
              const SizedBox(height: 8),
              _buildFlagChip('Unusual transaction velocity'),
              const SizedBox(height: 4),
              _buildFlagChip('Entity mismatch across GST/Bank'),
              
              const Spacer(flex: 2),
              
              // Swipe instructions
              Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(Icons.keyboard_arrow_left_rounded, color: AppTheme.danger.withValues(alpha: 0.5), size: 20),
                  const SizedBox(width: 4),
                  Text(
                    'Escalate',
                    style: TextStyle(color: AppTheme.danger.withValues(alpha: 0.7), fontSize: 12, fontWeight: FontWeight.w600),
                  ),
                  const SizedBox(width: 24),
                  Icon(Icons.keyboard_arrow_up_rounded, color: AppTheme.info.withValues(alpha: 0.5), size: 20),
                  const SizedBox(width: 4),
                  Text(
                    'Docs',
                    style: TextStyle(color: AppTheme.info.withValues(alpha: 0.7), fontSize: 12, fontWeight: FontWeight.w600),
                  ),
                  const SizedBox(width: 24),
                  Text(
                    'Approve',
                    style: TextStyle(color: AppTheme.success.withValues(alpha: 0.7), fontSize: 12, fontWeight: FontWeight.w600),
                  ),
                  const SizedBox(width: 4),
                  Icon(Icons.keyboard_arrow_right_rounded, color: AppTheme.success.withValues(alpha: 0.5), size: 20),
                ],
              )
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildFlagChip(String label) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
      decoration: BoxDecoration(
        color: AppTheme.warning.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: AppTheme.warning.withValues(alpha: 0.2)),
      ),
      child: Text(
        label,
        style: const TextStyle(
          color: AppTheme.warning,
          fontSize: 12,
        ),
      ),
    );
  }
}
