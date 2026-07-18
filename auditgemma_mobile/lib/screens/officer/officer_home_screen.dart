import 'dart:math';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../providers/auth_provider.dart';
import '../../providers/case_provider.dart';
import '../../theme/app_theme.dart';
import '../../services/notification_service.dart';
import '../../widgets/voice_recorder.dart';
import 'case_triage_card.dart';
import 'case_detail_screen.dart';

class OfficerHomeScreen extends StatefulWidget {
  const OfficerHomeScreen({super.key});

  @override
  State<OfficerHomeScreen> createState() => _OfficerHomeScreenState();
}

class _OfficerHomeScreenState extends State<OfficerHomeScreen> {
  final NotificationService _notificationService = NotificationService();

  @override
  void initState() {
    super.initState();
    Future.microtask(() => context.read<CaseProvider>().fetchCases());
    _notificationService.onNewCaseNotification = () {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('New case assigned for review!'),
            backgroundColor: AppTheme.accent,
          ),
        );
        context.read<CaseProvider>().fetchCases();
      }
    };
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Case Queue'),
        actions: [
          IconButton(
            icon: const Icon(Icons.notifications_active_rounded),
            tooltip: 'Simulate New Case',
            onPressed: () => _notificationService.simulateNewCasePush(),
          ),
          IconButton(
            icon: const Icon(Icons.logout_rounded, size: 20),
            onPressed: () => context.read<AuthProvider>().logout(),
            tooltip: 'Switch role',
          ),
        ],
      ),
      body: Consumer<CaseProvider>(
        builder: (context, provider, _) {
          if (provider.isLoading && provider.cases.isEmpty) {
            return const Center(
              child: CircularProgressIndicator(color: AppTheme.accent),
            );
          }

          final pendingCases =
              provider.cases.where((c) => c.status == 'pending').toList();

          if (pendingCases.isEmpty) {
            return _buildEmptyState();
          }

          // Build a stack of cards for swipe triage.
          // In a real production app, you might use a package like swipe_cards,
          // but we can build a custom spring-physics dismissible stack here for the hero interaction.
          return SafeArea(
            child: Padding(
              padding: const EdgeInsets.all(16.0),
              child: Stack(
                children: pendingCases.reversed.map((caseItem) {
                  final isTop = caseItem.caseId == pendingCases.first.caseId;
                  return _SwipeableCardWrapper(
                    key: ValueKey(caseItem.caseId),
                    isTop: isTop,
                    onSwipedRight: () {
                      provider.updateStatus(caseItem.caseId, 'approved');
                    },
                    onSwipedLeft: () {
                      _showVoiceNoteDialog(caseItem.caseId, provider);
                    },
                    onSwipedUp: () {
                      provider.updateStatus(caseItem.caseId, 'requires_documents');
                    },
                    child: CaseTriageCard(
                      caseItem: caseItem,
                      onTap: () {
                        Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder: (_) => CaseDetailScreen(caseId: caseItem.caseId),
                          ),
                        );
                      },
                    ),
                  );
                }).toList(),
              ),
            ),
          );
        },
      ),
    );
  }

  Widget _buildEmptyState() {
    return Center(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(Icons.inbox_rounded,
              size: 64, color: AppTheme.textMuted.withValues(alpha: 0.3)),
          const SizedBox(height: 16),
          const Text(
            'Queue Empty',
            style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.w600,
              color: AppTheme.textSecondary,
            ),
          ),
          const SizedBox(height: 8),
          const Text(
            'You have triaged all pending cases.',
            style: TextStyle(color: AppTheme.textMuted),
          ),
        ],
      ),
    );
  }

  void _showVoiceNoteDialog(String caseId, CaseProvider provider) {
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) {
        return Dialog(
          backgroundColor: Colors.transparent,
          child: VoiceRecorderWidget(
            onRecordingComplete: (filePath) {
              Navigator.pop(context); // close dialog
              if (filePath != null) {
                // Escalate with voice note
                provider.updateStatus(caseId, 'escalated');
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(
                    content: Text('Voice note saved: $filePath'),
                    backgroundColor: AppTheme.success,
                  ),
                );
              } else {
                // Cancelled, don't escalate, reset card (would need to wire card reset)
                provider.fetchCases(); // simple reset for demo
              }
            },
          ),
        );
      },
    );
  }
}

/// Custom swipe wrapper with spring physics, rotation, and color trails.
class _SwipeableCardWrapper extends StatefulWidget {
  final Widget child;
  final bool isTop;
  final VoidCallback onSwipedRight;
  final VoidCallback onSwipedLeft;
  final VoidCallback onSwipedUp;

  const _SwipeableCardWrapper({
    super.key,
    required this.child,
    required this.isTop,
    required this.onSwipedRight,
    required this.onSwipedLeft,
    required this.onSwipedUp,
  });

  @override
  State<_SwipeableCardWrapper> createState() => _SwipeableCardWrapperState();
}

class _SwipeableCardWrapperState extends State<_SwipeableCardWrapper>
    with SingleTickerProviderStateMixin {
  late AnimationController _animationController;
  Offset _dragOffset = Offset.zero;
  double _angle = 0;

  @override
  void initState() {
    super.initState();
    _animationController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 300),
    );
  }

  @override
  void dispose() {
    _animationController.dispose();
    super.dispose();
  }

  void _onPanUpdate(DragUpdateDetails details) {
    if (!widget.isTop) return;
    setState(() {
      _dragOffset += details.delta;
      _angle = 45 * (_dragOffset.dx / MediaQuery.of(context).size.width) * (pi / 180);
    });
  }

  void _onPanEnd(DragEndDetails details) {
    if (!widget.isTop) return;
    
    final size = MediaQuery.of(context).size;
    final thresholdX = size.width * 0.3;
    final thresholdY = size.height * 0.2;

    if (_dragOffset.dx > thresholdX) {
      _animateOffScreen(Offset(size.width, 0), widget.onSwipedRight);
    } else if (_dragOffset.dx < -thresholdX) {
      _animateOffScreen(Offset(-size.width, 0), widget.onSwipedLeft);
    } else if (_dragOffset.dy < -thresholdY) {
      _animateOffScreen(Offset(0, -size.height), widget.onSwipedUp);
    } else {
      _animateBackToCenter();
    }
  }

  void _animateOffScreen(Offset targetOffset, VoidCallback onComplete) {
    final startOffset = _dragOffset;
    Animation<double> anim = CurvedAnimation(
      parent: _animationController,
      curve: Curves.easeOut,
    );

    _animationController.addListener(() {
      if (mounted) {
        setState(() {
          _dragOffset = Offset.lerp(startOffset, targetOffset, anim.value)!;
        });
      }
    });

    _animationController.addStatusListener((status) {
      if (status == AnimationStatus.completed) {
        onComplete();
      }
    });

    _animationController.forward(from: 0);
  }

  void _animateBackToCenter() {
    final startOffset = _dragOffset;
    final startAngle = _angle;
    
    Animation<double> anim = CurvedAnimation(
      parent: _animationController,
      curve: Curves.elasticOut, // bouncy return
    );

    _animationController.addListener(() {
      if (mounted) {
        setState(() {
          _dragOffset = Offset.lerp(startOffset, Offset.zero, anim.value)!;
          _angle = _lerpDouble(startAngle, 0, anim.value)!;
        });
      }
    });

    _animationController.forward(from: 0);
  }

  double? _lerpDouble(num? a, num? b, double t) {
    if (a == null && b == null) return null;
    a ??= 0.0;
    b ??= 0.0;
    return a + (b - a) * t;
  }

  Color _getBackgroundColor() {
    if (_dragOffset.dx > 50) return AppTheme.success.withValues(alpha: min(_dragOffset.dx / 200, 0.5));
    if (_dragOffset.dx < -50) return AppTheme.danger.withValues(alpha: min(-_dragOffset.dx / 200, 0.5));
    if (_dragOffset.dy < -50) return AppTheme.info.withValues(alpha: min(-_dragOffset.dy / 200, 0.5));
    return Colors.transparent;
  }

  @override
  Widget build(BuildContext context) {
    if (!widget.isTop) {
      // Background cards slightly scaled down
      return Padding(
        padding: const EdgeInsets.only(top: 16.0),
        child: Transform.scale(
          scale: 0.95,
          child: widget.child,
        ),
      );
    }

    return GestureDetector(
      onPanUpdate: _onPanUpdate,
      onPanEnd: _onPanEnd,
      child: Stack(
        clipBehavior: Clip.none,
        children: [
          // Color trail overlay
          Positioned.fill(
            child: Container(
              decoration: BoxDecoration(
                color: _getBackgroundColor(),
                borderRadius: BorderRadius.circular(20),
              ),
            ),
          ),
          Transform.translate(
            offset: _dragOffset,
            child: Transform.rotate(
              angle: _angle,
              child: widget.child,
            ),
          ),
        ],
      ),
    );
  }
}
