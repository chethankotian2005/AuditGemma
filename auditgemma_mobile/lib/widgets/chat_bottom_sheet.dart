import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../providers/chat_provider.dart';
import '../theme/app_theme.dart';

/// Lightweight Gemma Q&A as a draggable bottom sheet.
/// Used by officers for quick questions while triaging.
class ChatBottomSheet extends StatefulWidget {
  final String caseId;

  const ChatBottomSheet({super.key, required this.caseId});

  /// Show the chat bottom sheet.
  static void show(BuildContext context, String caseId) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: AppTheme.bgSurface,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (_) => ChangeNotifierProvider(
        create: (_) => ChatProvider(),
        child: ChatBottomSheet(caseId: caseId),
      ),
    );
  }

  @override
  State<ChatBottomSheet> createState() => _ChatBottomSheetState();
}

class _ChatBottomSheetState extends State<ChatBottomSheet> {
  final _controller = TextEditingController();
  final _scrollController = ScrollController();

  final _suggestions = [
    'Why was this flagged?',
    'Explain the Benford\'s analysis',
    'Any entity mismatches?',
    'Transaction velocity concerns?',
  ];

  void _send() {
    final text = _controller.text.trim();
    if (text.isEmpty) return;
    _controller.clear();
    context.read<ChatProvider>().sendQuestion(widget.caseId, text);
    _scrollToBottom();
  }

  void _scrollToBottom() {
    Future.delayed(const Duration(milliseconds: 100), () {
      if (_scrollController.hasClients) {
        _scrollController.animateTo(
          _scrollController.position.maxScrollExtent,
          duration: const Duration(milliseconds: 300),
          curve: Curves.easeOut,
        );
      }
    });
  }

  @override
  void dispose() {
    _controller.dispose();
    _scrollController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return DraggableScrollableSheet(
      initialChildSize: 0.65,
      maxChildSize: 0.9,
      minChildSize: 0.4,
      expand: false,
      builder: (context, scrollController) {
        return Column(
          children: [
            // Handle
            Container(
              margin: const EdgeInsets.only(top: 8),
              width: 40,
              height: 4,
              decoration: BoxDecoration(
                color: AppTheme.borderLight,
                borderRadius: BorderRadius.circular(2),
              ),
            ),
            // Header
            Padding(
              padding: const EdgeInsets.all(16),
              child: Row(
                children: [
                  Container(
                    width: 8,
                    height: 8,
                    decoration: const BoxDecoration(
                      shape: BoxShape.circle,
                      color: AppTheme.accent,
                      boxShadow: [
                        BoxShadow(color: AppTheme.accent, blurRadius: 6),
                      ],
                    ),
                  ),
                  const SizedBox(width: 10),
                  const Expanded(
                    child: Text(
                      'Gemma Audit Agent',
                      style: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.w700,
                        color: AppTheme.textPrimary,
                      ),
                    ),
                  ),
                  IconButton(
                    icon: const Icon(Icons.close, size: 20),
                    onPressed: () => Navigator.pop(context),
                    color: AppTheme.textMuted,
                  ),
                ],
              ),
            ),
            const Divider(height: 1),
            // Messages
            Expanded(
              child: Consumer<ChatProvider>(
                builder: (context, chat, _) {
                  if (chat.messages.isEmpty && !chat.isLoading) {
                    return _buildEmptyState();
                  }
                  return ListView.builder(
                    controller: _scrollController,
                    padding: const EdgeInsets.all(16),
                    itemCount: chat.messages.length + (chat.isLoading ? 1 : 0),
                    itemBuilder: (context, i) {
                      if (i == chat.messages.length && chat.isLoading) {
                        return _buildThinkingBubble();
                      }
                      final msg = chat.messages[i];
                      final isOfficer = msg.role == 'officer';
                      return Padding(
                        padding: const EdgeInsets.only(bottom: 12),
                        child: Row(
                          mainAxisAlignment: isOfficer
                              ? MainAxisAlignment.end
                              : MainAxisAlignment.start,
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            if (!isOfficer) ...[
                              const CircleAvatar(
                                radius: 14,
                                backgroundColor: AppTheme.bgElevated,
                                child: Text('🤖', style: TextStyle(fontSize: 14)),
                              ),
                              const SizedBox(width: 8),
                            ],
                            Flexible(
                              child: Container(
                                padding: const EdgeInsets.all(12),
                                decoration: BoxDecoration(
                                  color: isOfficer
                                      ? AppTheme.accent.withValues(alpha: 0.12)
                                      : AppTheme.bgElevated,
                                  borderRadius: BorderRadius.circular(12),
                                  border: Border.all(
                                    color: isOfficer
                                        ? AppTheme.accent.withValues(alpha: 0.15)
                                        : AppTheme.border,
                                  ),
                                ),
                                child: Text(
                                  msg.content,
                                  style: const TextStyle(
                                    fontSize: 13,
                                    color: AppTheme.textSecondary,
                                    height: 1.5,
                                  ),
                                ),
                              ),
                            ),
                            if (isOfficer) const SizedBox(width: 8),
                          ],
                        ),
                      );
                    },
                  );
                },
              ),
            ),
            // Error
            Consumer<ChatProvider>(
              builder: (context, chat, _) {
                if (chat.error == null) return const SizedBox.shrink();
                return Container(
                  margin: const EdgeInsets.symmetric(horizontal: 16),
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    color: AppTheme.danger.withValues(alpha: 0.12),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Text(
                    chat.error!,
                    style: const TextStyle(
                      color: AppTheme.danger,
                      fontSize: 12,
                    ),
                  ),
                );
              },
            ),
            // Input
            Container(
              padding: const EdgeInsets.all(12),
              decoration: const BoxDecoration(
                border: Border(
                  top: BorderSide(color: AppTheme.border),
                ),
                color: AppTheme.bgPrimary,
              ),
              child: Row(
                children: [
                  Expanded(
                    child: TextField(
                      controller: _controller,
                      style: const TextStyle(
                        fontSize: 13,
                        color: AppTheme.textPrimary,
                      ),
                      decoration: const InputDecoration(
                        hintText: 'Ask about this case…',
                        border: InputBorder.none,
                        contentPadding: EdgeInsets.symmetric(
                          horizontal: 12,
                          vertical: 10,
                        ),
                      ),
                      onSubmitted: (_) => _send(),
                      textInputAction: TextInputAction.send,
                    ),
                  ),
                  const SizedBox(width: 8),
                  Consumer<ChatProvider>(
                    builder: (context, chat, _) {
                      return IconButton(
                        onPressed: chat.isLoading ? null : _send,
                        icon: const Icon(Icons.send_rounded, size: 20),
                        color: AppTheme.accent,
                        disabledColor: AppTheme.textMuted,
                      );
                    },
                  ),
                ],
              ),
            ),
          ],
        );
      },
    );
  }

  Widget _buildEmptyState() {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Text(
              'Ask Gemma anything about this case',
              style: TextStyle(
                color: AppTheme.textSecondary,
                fontSize: 14,
                fontWeight: FontWeight.w500,
              ),
            ),
            const SizedBox(height: 16),
            Wrap(
              spacing: 8,
              runSpacing: 8,
              alignment: WrapAlignment.center,
              children: _suggestions.map((s) {
                return ActionChip(
                  label: Text(
                    s,
                    style: const TextStyle(
                      fontSize: 12,
                      color: AppTheme.accent,
                    ),
                  ),
                  backgroundColor: AppTheme.accent.withValues(alpha: 0.1),
                  side: BorderSide(
                    color: AppTheme.accent.withValues(alpha: 0.2),
                  ),
                  onPressed: () {
                    _controller.text = s;
                    _send();
                  },
                );
              }).toList(),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildThinkingBubble() {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const CircleAvatar(
            radius: 14,
            backgroundColor: AppTheme.bgElevated,
            child: Text('🤖', style: TextStyle(fontSize: 14)),
          ),
          const SizedBox(width: 8),
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: AppTheme.bgElevated,
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: AppTheme.border),
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                SizedBox(
                  width: 16,
                  height: 16,
                  child: CircularProgressIndicator(
                    strokeWidth: 2,
                    color: AppTheme.accent.withValues(alpha: 0.6),
                  ),
                ),
                const SizedBox(width: 10),
                Text(
                  'Reasoning over case data…',
                  style: TextStyle(
                    fontSize: 12,
                    color: AppTheme.accent.withValues(alpha: 0.8),
                    fontStyle: FontStyle.italic,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
