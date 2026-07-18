import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import '../../models/case_model.dart';
import '../../services/api_service.dart';
import '../../theme/app_theme.dart';
import 'case_submit_screen.dart';

/// Multi-step document capture: pick image → extract → preview → confirm.
class DocumentCaptureScreen extends StatefulWidget {
  const DocumentCaptureScreen({super.key});

  @override
  State<DocumentCaptureScreen> createState() => _DocumentCaptureScreenState();
}

class _DocumentCaptureScreenState extends State<DocumentCaptureScreen> {
  final _api = ApiService();
  final _picker = ImagePicker();
  final List<_CapturedDocument> _documents = [];
  bool _isExtracting = false;

  final _docTypes = [
    ('Invoice', Icons.receipt_long_rounded),
    ('GST Filing', Icons.account_balance_rounded),
    ('Bank Statement', Icons.account_balance_wallet_rounded),
    ('KYC Document', Icons.badge_rounded),
  ];

  Future<void> _captureDocument(String docType, {bool fromCamera = true}) async {
    final XFile? picked;
    try {
      if (fromCamera) {
        picked = await _picker.pickImage(source: ImageSource.camera);
      } else {
        picked = await _picker.pickImage(source: ImageSource.gallery);
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Could not open ${fromCamera ? "camera" : "gallery"}: $e'),
            backgroundColor: AppTheme.danger,
          ),
        );
      }
      return;
    }
    if (picked == null) return;

    // Non-null from here — avoids ! operators below.
    final XFile image = picked;

    setState(() => _isExtracting = true);

    try {
      final extraction = await _api.extractDocument(image);
      setState(() {
        _documents.add(_CapturedDocument(
          docType: docType,
          file: image,
          extraction: extraction,
        ));
      });
    } on ApiException catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Server error (${e.statusCode}): ${e.detail}'),
            backgroundColor: AppTheme.danger,
            duration: const Duration(seconds: 5),
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        // Network / byte-read / unexpected errors
        final message = e.toString().contains('Failed to fetch') ||
                e.toString().contains('ClientException')
            ? 'Could not reach the server. Check your network connection.'
            : 'Extraction failed: $e';
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(message),
            backgroundColor: AppTheme.danger,
            duration: const Duration(seconds: 5),
          ),
        );
      }
    } finally {
      setState(() => _isExtracting = false);
    }
  }

  void _removeDocument(int index) {
    setState(() => _documents.removeAt(index));
  }

  void _proceedToSubmit() {
    if (_documents.isEmpty) return;
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => CaseSubmitScreen(documents: _documents),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Upload Documents'),
      ),
      body: Column(
        children: [
          // Extraction overlay
          if (_isExtracting)
            Container(
              padding: const EdgeInsets.all(16),
              color: AppTheme.accent.withValues(alpha: 0.1),
              child: const Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  SizedBox(
                    width: 18,
                    height: 18,
                    child: CircularProgressIndicator(
                      strokeWidth: 2,
                      color: AppTheme.accent,
                    ),
                  ),
                  SizedBox(width: 12),
                  Text(
                    'Analyzing document with Gemma…',
                    style: TextStyle(
                      color: AppTheme.accent,
                      fontSize: 13,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                ],
              ),
            ),

          Expanded(
            child: _documents.isEmpty
                ? _buildDocTypeSelector()
                : _buildDocumentList(),
          ),

          // Bottom bar
          if (_documents.isNotEmpty)
            Container(
              padding: const EdgeInsets.all(16),
              decoration: const BoxDecoration(
                color: AppTheme.bgSurface,
                border: Border(top: BorderSide(color: AppTheme.border)),
              ),
              child: Row(
                children: [
                  Expanded(
                    child: OutlinedButton.icon(
                      onPressed: () => _showDocTypeBottomSheet(),
                      icon: const Icon(Icons.add_rounded, size: 18),
                      label: const Text('Add Document'),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: ElevatedButton.icon(
                      onPressed: _proceedToSubmit,
                      icon: const Icon(Icons.send_rounded, size: 18),
                      label: Text('Review (${_documents.length})'),
                    ),
                  ),
                ],
              ),
            ),
        ],
      ),
    );
  }

  Widget _buildDocTypeSelector() {
    return Padding(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'Select document type to upload',
            style: TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.w600,
              color: AppTheme.textPrimary,
            ),
          ),
          const SizedBox(height: 4),
          const Text(
            'Each document will be analyzed by Gemma for extraction.',
            style: TextStyle(color: AppTheme.textMuted, fontSize: 13),
          ),
          const SizedBox(height: 20),
          ...List.generate(_docTypes.length, (i) {
            final (label, icon) = _docTypes[i];
            return Padding(
              padding: const EdgeInsets.only(bottom: 8),
              child: _DocTypeButton(
                icon: icon,
                label: label,
                onCamera: () => _captureDocument(label, fromCamera: true),
                onGallery: () => _captureDocument(label, fromCamera: false),
              ),
            );
          }),
        ],
      ),
    );
  }

  Widget _buildDocumentList() {
    return ListView.builder(
      padding: const EdgeInsets.all(16),
      itemCount: _documents.length + 1,
      itemBuilder: (context, index) {
        if (index == 0) {
          return const Padding(
            padding: EdgeInsets.only(bottom: 12),
            child: Text(
              'Captured Documents',
              style: TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.w600,
                color: AppTheme.textPrimary,
              ),
            ),
          );
        }
        final doc = _documents[index - 1];
        return _DocumentPreviewCard(
          doc: doc,
          onRemove: () => _removeDocument(index - 1),
        );
      },
    );
  }

  void _showDocTypeBottomSheet() {
    showModalBottomSheet(
      context: context,
      backgroundColor: AppTheme.bgSurface,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (context) {
        return Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Center(
                child: Container(
                  width: 40,
                  height: 4,
                  decoration: BoxDecoration(
                    color: AppTheme.borderLight,
                    borderRadius: BorderRadius.circular(2),
                  ),
                ),
              ),
              const SizedBox(height: 16),
              const Text(
                'Add another document',
                style: TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.w600,
                  color: AppTheme.textPrimary,
                ),
              ),
              const SizedBox(height: 12),
              ...List.generate(_docTypes.length, (i) {
                final (label, icon) = _docTypes[i];
                return _DocTypeButton(
                  icon: icon,
                  label: label,
                  onCamera: () {
                    Navigator.pop(context);
                    _captureDocument(label, fromCamera: true);
                  },
                  onGallery: () {
                    Navigator.pop(context);
                    _captureDocument(label, fromCamera: false);
                  },
                );
              }),
              const SizedBox(height: 16),
            ],
          ),
        );
      },
    );
  }
}

class _DocTypeButton extends StatelessWidget {
  final IconData icon;
  final String label;
  final VoidCallback onCamera;
  final VoidCallback onGallery;

  const _DocTypeButton({
    required this.icon,
    required this.label,
    required this.onCamera,
    required this.onGallery,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: AppTheme.bgSurface,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: AppTheme.border),
      ),
      child: Padding(
        padding: const EdgeInsets.all(12),
        child: Row(
          children: [
            Icon(icon, color: AppTheme.textSecondary, size: 20),
            const SizedBox(width: 12),
            Expanded(
              child: Text(
                label,
                style: const TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.w500,
                  color: AppTheme.textPrimary,
                ),
              ),
            ),
            IconButton(
              icon: const Icon(Icons.camera_alt_rounded, size: 20),
              onPressed: onCamera,
              color: AppTheme.accent,
              tooltip: 'Camera',
            ),
            IconButton(
              icon: const Icon(Icons.photo_library_rounded, size: 20),
              onPressed: onGallery,
              color: AppTheme.accent,
              tooltip: 'Gallery',
            ),
          ],
        ),
      ),
    );
  }
}

class _DocumentPreviewCard extends StatelessWidget {
  final _CapturedDocument doc;
  final VoidCallback onRemove;

  const _DocumentPreviewCard({
    required this.doc,
    required this.onRemove,
  });

  @override
  Widget build(BuildContext context) {
    final ext = doc.extraction;
    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: Container(
        decoration: BoxDecoration(
          color: AppTheme.bgSurface,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: AppTheme.border),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Header
            Padding(
              padding: const EdgeInsets.all(12),
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
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          doc.docType,
                          style: const TextStyle(
                            fontSize: 14,
                            fontWeight: FontWeight.w600,
                            color: AppTheme.textPrimary,
                          ),
                        ),
                        Text(
                          'Type: ${ext.documentType} · Confidence: ${ext.extractionConfidence}',
                          style: const TextStyle(
                            fontSize: 11,
                            color: AppTheme.textMuted,
                          ),
                        ),
                      ],
                    ),
                  ),
                  IconButton(
                    icon: const Icon(Icons.close_rounded, size: 18),
                    onPressed: onRemove,
                    color: AppTheme.textMuted,
                  ),
                ],
              ),
            ),
            const Divider(height: 1),
            // Extraction summary
            Padding(
              padding: const EdgeInsets.all(12),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  if (ext.amounts.isNotEmpty)
                    _ExtractionRow(
                      label: 'Amounts',
                      value: ext.amounts
                          .map((a) => '₹${a.toStringAsFixed(0)}')
                          .join(', '),
                    ),
                  if (ext.dates.isNotEmpty)
                    _ExtractionRow(
                      label: 'Dates',
                      value: ext.dates.join(', '),
                    ),
                  if (ext.extractedEntities.isNotEmpty)
                    _ExtractionRow(
                      label: 'Entities',
                      value: ext.extractedEntities.values
                          .take(3)
                          .join(', '),
                    ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _ExtractionRow extends StatelessWidget {
  final String label;
  final String value;

  const _ExtractionRow({required this.label, required this.value});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 4),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            width: 60,
            child: Text(
              label,
              style: const TextStyle(
                color: AppTheme.textMuted,
                fontSize: 11,
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
          Expanded(
            child: Text(
              value,
              style: const TextStyle(
                color: AppTheme.textSecondary,
                fontSize: 12,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

/// Internal model for a captured document + its extraction result.
class _CapturedDocument {
  final String docType;
  final XFile file;
  final ExtractionResponse extraction;

  _CapturedDocument({
    required this.docType,
    required this.file,
    required this.extraction,
  });
}
