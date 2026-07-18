import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../theme/app_theme.dart';
import '../../widgets/status_badge.dart';
import '../../services/api_service.dart';
import '../../models/case_model.dart';
import 'document_capture_screen.dart';

/// SME-appropriate case status view.
/// Does NOT show raw numeric score — just status + plain-language summary.
class CaseStatusScreen extends StatefulWidget {
  final String caseId;
  final String status;

  const CaseStatusScreen({
    super.key,
    required this.caseId,
    required this.status,
  });

  @override
  State<CaseStatusScreen> createState() => _CaseStatusScreenState();
}

class _CaseStatusScreenState extends State<CaseStatusScreen> {
  CaseDetail? _caseDetail;
  bool _isLoading = true;
  String? _error;

  @override
  void initState() {
    super.initState();
    _loadData();
  }

  Future<void> _loadData() async {
    try {
      final apiService = context.read<ApiService>();
      final detail = await apiService.getCase(widget.caseId);
      if (mounted) {
        setState(() {
          _caseDetail = detail;
          _isLoading = false;
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _error = e.toString();
          _isLoading = false;
        });
      }
    }
  }

  String get _statusMessage {
    final status = _caseDetail?.status ?? widget.status;
    switch (status) {
      case 'pending':
        return 'Your application is being reviewed by our compliance team. You will be notified once a decision is made.';
      case 'escalated':
        return 'Your application is under review — additional documents may be requested. Our team will reach out if needed.';
      case 'requires_documents':
        return 'Additional documents are needed to process your application. Please upload the requested documents.';
      default:
        return 'Application status is being determined.';
    }
  }

  IconData get _statusIcon {
    final status = _caseDetail?.status ?? widget.status;
    switch (status) {
      case 'pending':
        return Icons.hourglass_top_rounded;
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
    if (_isLoading) {
      return Scaffold(
        appBar: AppBar(title: const Text('Application Status')),
        body: const Center(child: CircularProgressIndicator(color: AppTheme.accent)),
      );
    }

    if (_error != null) {
      return Scaffold(
        appBar: AppBar(title: const Text('Application Status')),
        body: Center(child: Text('Error loading status: $_error', style: const TextStyle(color: AppTheme.danger))),
      );
    }

    final status = _caseDetail?.status ?? widget.status;
    
    // Approved State
    if (status == 'approved') {
      return Scaffold(
        appBar: AppBar(title: const Text('Application Status')),
        body: Center(
          child: Padding(
            padding: const EdgeInsets.all(32),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Container(
                  width: 96,
                  height: 96,
                  decoration: BoxDecoration(
                    color: AppTheme.success.withValues(alpha: 0.15),
                    shape: BoxShape.circle,
                  ),
                  child: const Icon(
                    Icons.check_circle_rounded,
                    size: 48,
                    color: AppTheme.success,
                  ),
                ),
                const SizedBox(height: 24),
                const Text(
                  'Application Approved!',
                  style: TextStyle(
                    fontSize: 24,
                    fontWeight: FontWeight.w700,
                    color: AppTheme.success,
                  ),
                ),
                const SizedBox(height: 12),
                const Text(
                  'Congratulations. Your application has been approved. Our team will contact you shortly with the next steps.',
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    fontSize: 16,
                    color: AppTheme.textSecondary,
                    height: 1.5,
                  ),
                ),
                const SizedBox(height: 48),
                SizedBox(
                  width: double.infinity,
                  child: ElevatedButton(
                    onPressed: () => Navigator.of(context).popUntil((route) => route.isFirst),
                    child: const Text('Back to Home'),
                  ),
                ),
              ],
            ),
          ),
        ),
      );
    }
    
    // Rejected State
    if (status == 'rejected') {
      return Scaffold(
        appBar: AppBar(title: const Text('Application Status')),
        body: SingleChildScrollView(
          padding: const EdgeInsets.all(24),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              Container(
                width: 80,
                height: 80,
                decoration: BoxDecoration(
                  color: AppTheme.danger.withValues(alpha: 0.12),
                  shape: BoxShape.circle,
                ),
                child: const Icon(
                  Icons.cancel_rounded,
                  size: 40,
                  color: AppTheme.danger,
                ),
              ),
              const SizedBox(height: 20),
              StatusBadge(status: status),
              const SizedBox(height: 16),
              Text(
                'Case ${widget.caseId.substring(0, 8)}…',
                style: const TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.w500,
                  color: AppTheme.textMuted,
                  fontFamily: 'monospace',
                ),
              ),
              const SizedBox(height: 24),
              Container(
                width: double.infinity,
                padding: const EdgeInsets.all(20),
                decoration: BoxDecoration(
                  color: AppTheme.danger.withValues(alpha: 0.05),
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: AppTheme.danger.withValues(alpha: 0.3)),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Row(
                      children: [
                        Icon(Icons.info_outline, color: AppTheme.danger, size: 20),
                        SizedBox(width: 8),
                        Text(
                          'Rejection Reason',
                          style: TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.w600,
                            color: AppTheme.danger,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 12),
                    Text(
                      _caseDetail?.rejectionReason ?? 'No reason provided.',
                      style: const TextStyle(
                        fontSize: 15,
                        color: AppTheme.textPrimary,
                        height: 1.5,
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 32),
              SizedBox(
                width: double.infinity,
                child: ElevatedButton.icon(
                  onPressed: () {
                    Navigator.of(context).pushReplacement(
                      MaterialPageRoute(
                        builder: (_) => const DocumentCaptureScreen(),
                      ),
                    );
                  },
                  icon: const Icon(Icons.add_rounded),
                  label: const Text('Submit a new application'),
                ),
              ),
              const SizedBox(height: 16),
              SizedBox(
                width: double.infinity,
                child: OutlinedButton(
                  onPressed: () => Navigator.of(context).popUntil((route) => route.isFirst),
                  child: const Text('Back to Home'),
                ),
              ),
            ],
          ),
        ),
      );
    }

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
                'Case ${widget.caseId.substring(0, 8)}…',
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
