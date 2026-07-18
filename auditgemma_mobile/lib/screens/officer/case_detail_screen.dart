import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../providers/case_provider.dart';
import '../../theme/app_theme.dart';
import '../../models/case_model.dart';
import '../../widgets/score_gradient.dart';
import '../../widgets/confidence_badge.dart';
import '../../widgets/status_badge.dart';
import '../../widgets/chat_bottom_sheet.dart';

/// Full case detail screen (tapped from triage card).
class CaseDetailScreen extends StatefulWidget {
  final String caseId;

  const CaseDetailScreen({super.key, required this.caseId});

  @override
  State<CaseDetailScreen> createState() => _CaseDetailScreenState();
}

class _CaseDetailScreenState extends State<CaseDetailScreen> {
  CaseScoreResponse? _scoreResponse;
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadData();
  }

  Future<void> _loadData() async {
    // In a real app with the full API, we would fetch GET /case/{id}
    // and if we need the full score, maybe a dedicated endpoint or it's
    // included. For this hackathon demo, we'll try to load from cache
    // (assuming SME scored it locally, or it was pushed with full data),
    // or we just show a mock based on the ID to demonstrate the UI.
    
    final provider = context.read<CaseProvider>();
    final cached = provider.getCachedScore(widget.caseId);
    
    if (cached != null) {
      _scoreResponse = cached;
    } else {
      // Mock for demo if no cache
      await Future.delayed(const Duration(milliseconds: 600));
      _scoreResponse = CaseScoreResponse(
        caseId: widget.caseId,
        score: 82,
        confidence: 'high',
        flaggedReasons: [
          'Unusual transaction velocity in Q4',
          'Entity mismatch across GST/Bank',
        ],
        recommendedAction: 'Escalate for manual review of Q4 invoices',
        reasoningNarrative: 'Step 1: Extracted... Step 2: Analyzed...',
        signals: {
          'benfords_law': {'status': 'flagged', 'value': '0.12 MAD'},
          'transaction_velocity': {'status': 'flagged', 'value': '+300% YoY'},
        },
      );
    }
    
    if (mounted) setState(() => _isLoading = false);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Case Detail'),
        actions: [
          IconButton(
            icon: const Icon(Icons.forum_rounded),
            color: AppTheme.accent,
            tooltip: 'Ask Gemma',
            onPressed: () => ChatBottomSheet.show(context, widget.caseId),
          ),
        ],
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator(color: AppTheme.accent))
          : SingleChildScrollView(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Header
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(
                        'Case ${widget.caseId.substring(0, 8)}',
                        style: const TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.w600,
                          color: AppTheme.textPrimary,
                          fontFamily: 'monospace',
                        ),
                      ),
                      const StatusBadge(status: 'pending'),
                    ],
                  ),
                  const SizedBox(height: 24),
                  
                  // Score bar
                  Center(
                    child: ScoreGradientWidget(
                      score: _scoreResponse!.score,
                      variant: 'bar',
                    ),
                  ),
                  const SizedBox(height: 24),
                  
                  // Confidence
                  Center(child: ConfidenceBadge(confidence: _scoreResponse!.confidence)),
                  const SizedBox(height: 32),
                  
                  // Recommended Action
                  Container(
                    width: double.infinity,
                    padding: const EdgeInsets.all(16),
                    decoration: BoxDecoration(
                      color: AppTheme.accent.withValues(alpha: 0.1),
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(color: AppTheme.accent.withValues(alpha: 0.2)),
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Text(
                          'RECOMMENDED ACTION',
                          style: TextStyle(
                            color: AppTheme.accent,
                            fontSize: 10,
                            fontWeight: FontWeight.w700,
                            letterSpacing: 1,
                          ),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          _scoreResponse!.recommendedAction,
                          style: const TextStyle(
                            color: AppTheme.textPrimary,
                            fontSize: 14,
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 24),
                  
                  // Flagged Reasons
                  const Text(
                    'FLAGGED REASONS',
                    style: TextStyle(
                      color: AppTheme.textMuted,
                      fontSize: 11,
                      fontWeight: FontWeight.w700,
                      letterSpacing: 1,
                    ),
                  ),
                  const SizedBox(height: 12),
                  ..._scoreResponse!.flaggedReasons.map((r) => Padding(
                    padding: const EdgeInsets.only(bottom: 8),
                    child: Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Icon(Icons.warning_amber_rounded, size: 18, color: AppTheme.warning),
                        const SizedBox(width: 8),
                        Expanded(
                          child: Text(
                            r,
                            style: const TextStyle(color: AppTheme.textSecondary, fontSize: 14),
                          ),
                        ),
                      ],
                    ),
                  )),
                  const SizedBox(height: 24),
                  
                  // Signals Grid
                  const Text(
                    'STAGE 2 SIGNALS',
                    style: TextStyle(
                      color: AppTheme.textMuted,
                      fontSize: 11,
                      fontWeight: FontWeight.w700,
                      letterSpacing: 1,
                    ),
                  ),
                  const SizedBox(height: 12),
                  GridView.count(
                    crossAxisCount: 2,
                    shrinkWrap: true,
                    physics: const NeverScrollableScrollPhysics(),
                    mainAxisSpacing: 8,
                    crossAxisSpacing: 8,
                    childAspectRatio: 1.5,
                    children: _scoreResponse!.signals.entries.map((e) {
                      final data = e.value as Map<String, dynamic>;
                      final isFlagged = data['status'] == 'flagged';
                      return Container(
                        padding: const EdgeInsets.all(12),
                        decoration: BoxDecoration(
                          color: AppTheme.bgSurface,
                          borderRadius: BorderRadius.circular(12),
                          border: Border.all(color: AppTheme.border),
                        ),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Row(
                              children: [
                                Container(
                                  width: 8,
                                  height: 8,
                                  decoration: BoxDecoration(
                                    shape: BoxShape.circle,
                                    color: isFlagged ? AppTheme.warning : AppTheme.success,
                                  ),
                                ),
                                const SizedBox(width: 8),
                                Expanded(
                                  child: Text(
                                    e.key.replaceAll('_', ' ').toUpperCase(),
                                    style: const TextStyle(
                                      fontSize: 10,
                                      fontWeight: FontWeight.w600,
                                      color: AppTheme.textMuted,
                                    ),
                                    maxLines: 1,
                                    overflow: TextOverflow.ellipsis,
                                  ),
                                ),
                              ],
                            ),
                            const Spacer(),
                            Text(
                              data['value'].toString(),
                              style: const TextStyle(
                                fontSize: 14,
                                fontWeight: FontWeight.w600,
                                color: AppTheme.textPrimary,
                              ),
                            ),
                          ],
                        ),
                      );
                    }).toList(),
                  ),
                  const SizedBox(height: 80), // padding for FAB
                ],
              ),
            ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () => ChatBottomSheet.show(context, widget.caseId),
        icon: const Icon(Icons.forum_rounded),
        label: const Text('Ask Gemma'),
      ),
    );
  }
}
