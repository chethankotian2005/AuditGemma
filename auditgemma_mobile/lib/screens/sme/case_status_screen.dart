import 'package:flutter/material.dart';
import '../../theme/app_theme.dart';
import '../../widgets/status_badge.dart';

/// SME-appropriate case status view.
/// Does NOT show raw numeric score — just status + plain-language summary.
class CaseStatusScreen extends StatelessWidget {
  final String caseId;
  final String status;

  const CaseStatusScreen({
    super.key,
    required this.caseId,
    required this.status,
  });

  String get _statusMessage {
    switch (status) {
      case 'pending':
        return 'Your application is being reviewed by our compliance team. You will be notified once a decision is made.';
      case 'approved':
        return 'Your application has been approved. You will receive further instructions shortly.';
      case 'escalated':
        return 'Your application is under review — additional documents may be requested. Our team will reach out if needed.';
      case 'requires_documents':
        return 'Additional documents are needed to process your application. Please upload the requested documents.';
      default:
        return 'Application status is being determined.';
    }
  }

  IconData get _statusIcon {
    switch (status) {
      case 'pending':
        return Icons.hourglass_top_rounded;
      case 'approved':
        return Icons.check_circle_rounded;
      case 'escalated':
        return Icons.info_rounded;
      case 'requires_documents':
        return Icons.upload_file_rounded;
      default:
        return Icons.help_outline_rounded;
    }
  }

  @override
  Widget build(BuildContext context) {
    final statusColor = AppTheme.statusColor(status);

    return Scaffold(
      appBar: AppBar(
        title: const Text('Application Status'),
      ),
      body: Center(
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              // Status icon
              Container(
                width: 80,
                height: 80,
                decoration: BoxDecoration(
                  color: statusColor.withValues(alpha: 0.12),
                  shape: BoxShape.circle,
                ),
                child: Icon(
                  _statusIcon,
                  size: 40,
                  color: statusColor,
                ),
              ),
              const SizedBox(height: 20),
              // Status badge
              StatusBadge(status: status),
              const SizedBox(height: 16),
              // Case ID
              Text(
                'Case ${caseId.substring(0, 8)}…',
                style: const TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.w500,
                  color: AppTheme.textMuted,
                  fontFamily: 'monospace',
                ),
              ),
              const SizedBox(height: 20),
              // Plain-language message
              Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: AppTheme.bgSurface,
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: AppTheme.border),
                ),
                child: Text(
                  _statusMessage,
                  textAlign: TextAlign.center,
                  style: const TextStyle(
                    fontSize: 14,
                    color: AppTheme.textSecondary,
                    height: 1.6,
                  ),
                ),
              ),
              const SizedBox(height: 32),
              // Back button
              SizedBox(
                width: double.infinity,
                child: OutlinedButton(
                  onPressed: () => Navigator.of(context).popUntil(
                    (route) => route.isFirst,
                  ),
                  child: const Text('Back to Applications'),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
