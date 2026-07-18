import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../providers/case_provider.dart';
import '../../theme/app_theme.dart';
import 'case_status_screen.dart';

/// Review all captured documents, add business context, submit for scoring.
class CaseSubmitScreen extends StatefulWidget {
  final List<dynamic> documents; // _CapturedDocument list from capture screen

  const CaseSubmitScreen({super.key, required this.documents});

  @override
  State<CaseSubmitScreen> createState() => _CaseSubmitScreenState();
}

class _CaseSubmitScreenState extends State<CaseSubmitScreen> {
  final _contextController = TextEditingController();
  final _panController = TextEditingController();
  bool _isSubmitting = false;
  String? _panError;

  /// Validate PAN format: 5 letters + 4 digits + 1 letter (standard Indian PAN)
  bool _validatePan(String pan) {
    if (pan.isEmpty) return true; // PAN is optional
    final panRegex = RegExp(r'^[A-Z]{5}[0-9]{4}[A-Z]{1}$');
    return panRegex.hasMatch(pan.toUpperCase());
  }

  Future<void> _submit() async {
    final panText = _panController.text.trim();
    if (panText.isNotEmpty && !_validatePan(panText)) {
      setState(() => _panError = 'Invalid PAN format (e.g. ABCPK1234L)');
      return;
    }
    setState(() {
      _panError = null;
      _isSubmitting = true;
    });

    // Convert captured documents to extraction JSON for scoring
    final docs = widget.documents.map<Map<String, dynamic>>((doc) {
      // Access the extraction's toJson
      return (doc as dynamic).extraction.toJson() as Map<String, dynamic>;
    }).toList();

    final result = await context.read<CaseProvider>().submitCase(
          docs,
          _contextController.text.trim(),
          panNumber: panText.toUpperCase(),
        );

    if (!mounted) return;
    setState(() => _isSubmitting = false);

    if (result != null) {
      // Navigate to status screen, replacing the capture/submit flow
      Navigator.of(context).popUntil((route) => route.isFirst);
      Navigator.push(
        context,
        MaterialPageRoute(
          builder: (_) => CaseStatusScreen(
            caseId: result.caseId,
            status: 'pending',
          ),
        ),
      );
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Failed to submit. Please try again.'),
          backgroundColor: AppTheme.danger,
        ),
      );
    }
  }

  @override
  void dispose() {
    _contextController.dispose();
    _panController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Review & Submit'),
      ),
      body: Column(
        children: [
          Expanded(
            child: ListView(
              padding: const EdgeInsets.all(16),
              children: [
                // Document summary
                const Text(
                  'DOCUMENTS',
                  style: TextStyle(
                    color: AppTheme.textMuted,
                    fontSize: 11,
                    fontWeight: FontWeight.w700,
                    letterSpacing: 1,
                  ),
                ),
                const SizedBox(height: 8),
                ...List.generate(widget.documents.length, (i) {
                  final doc = widget.documents[i] as dynamic;
                  return Container(
                    margin: const EdgeInsets.only(bottom: 8),
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: AppTheme.bgSurface,
                      borderRadius: BorderRadius.circular(10),
                      border: Border.all(color: AppTheme.border),
                    ),
                    child: Row(
                      children: [
                        Container(
                          padding: const EdgeInsets.all(6),
                          decoration: BoxDecoration(
                            color: AppTheme.success.withValues(alpha: 0.12),
                            borderRadius: BorderRadius.circular(6),
                          ),
                          child: const Icon(
                            Icons.check_circle_rounded,
                            color: AppTheme.success,
                            size: 16,
                          ),
                        ),
                        const SizedBox(width: 10),
                        Expanded(
                          child: Text(
                            doc.docType as String,
                            style: const TextStyle(
                              fontSize: 14,
                              fontWeight: FontWeight.w500,
                              color: AppTheme.textPrimary,
                            ),
                          ),
                        ),
                        Text(
                          doc.extraction.extractionConfidence as String,
                          style: const TextStyle(
                            fontSize: 11,
                            color: AppTheme.textMuted,
                          ),
                        ),
                      ],
                    ),
                  );
                }),
                const SizedBox(height: 24),
                // PAN Number
                const Text(
                  'PAN NUMBER',
                  style: TextStyle(
                    color: AppTheme.textMuted,
                    fontSize: 11,
                    fontWeight: FontWeight.w700,
                    letterSpacing: 1,
                  ),
                ),
                const SizedBox(height: 8),
                TextField(
                  controller: _panController,
                  textCapitalization: TextCapitalization.characters,
                  maxLength: 10,
                  decoration: InputDecoration(
                    hintText: 'e.g. ABCPK1234L',
                    counterText: '',
                    errorText: _panError,
                    suffixIcon: _panController.text.isNotEmpty
                        ? IconButton(
                            icon: const Icon(Icons.clear, size: 16),
                            onPressed: () {
                              _panController.clear();
                              setState(() => _panError = null);
                            },
                          )
                        : null,
                  ),
                  style: const TextStyle(
                    fontSize: 14,
                    color: AppTheme.textPrimary,
                    fontFamily: 'monospace',
                    letterSpacing: 2,
                  ),
                  onChanged: (val) {
                    if (_panError != null) {
                      setState(() => _panError = null);
                    }
                  },
                ),
                const SizedBox(height: 4),
                const Text(
                  'Your PAN is used for credit bureau lookup (demo only — not a real bureau check).',
                  style: TextStyle(
                    color: AppTheme.textMuted,
                    fontSize: 12,
                  ),
                ),
                const SizedBox(height: 24),
                // Business context
                const Text(
                  'BUSINESS CONTEXT',
                  style: TextStyle(
                    color: AppTheme.textMuted,
                    fontSize: 11,
                    fontWeight: FontWeight.w700,
                    letterSpacing: 1,
                  ),
                ),
                const SizedBox(height: 8),
                TextField(
                  controller: _contextController,
                  maxLines: 3,
                  decoration: const InputDecoration(
                    hintText:
                        'e.g. "Textile wholesaler, seasonal Q4 spike expected"',
                  ),
                  style: const TextStyle(
                    fontSize: 14,
                    color: AppTheme.textPrimary,
                  ),
                ),
                const SizedBox(height: 8),
                const Text(
                  'Provide context about the business to help Gemma assess the application more accurately.',
                  style: TextStyle(
                    color: AppTheme.textMuted,
                    fontSize: 12,
                  ),
                ),
              ],
            ),
          ),
          // Submit button
          Container(
            padding: const EdgeInsets.all(16),
            decoration: const BoxDecoration(
              color: AppTheme.bgSurface,
              border: Border(top: BorderSide(color: AppTheme.border)),
            ),
            child: SizedBox(
              width: double.infinity,
              child: ElevatedButton.icon(
                onPressed: _isSubmitting ? null : _submit,
                icon: _isSubmitting
                    ? const SizedBox(
                        width: 18,
                        height: 18,
                        child: CircularProgressIndicator(
                          strokeWidth: 2,
                          color: Colors.white,
                        ),
                      )
                    : const Icon(Icons.send_rounded, size: 18),
                label: Text(_isSubmitting
                    ? 'Submitting to Gemma…'
                    : 'Submit for Review'),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
