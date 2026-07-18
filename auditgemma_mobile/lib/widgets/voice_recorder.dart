import 'package:flutter/material.dart';
import '../theme/app_theme.dart';

/// Voice note recorder widget for officer escalation.
///
/// Records audio using a simple timer-based UI. The actual recording
/// functionality requires the `record` package — for now, this provides
/// the complete UI with a stub for the recording backend.
///
/// TODO: Wire actual audio recording when `record` package is added.
/// TODO: Gemma transcription — awaiting backend endpoint for audio→text.
///       Do NOT fake a working transcription call.
class VoiceRecorderWidget extends StatefulWidget {
  final void Function(String? filePath) onRecordingComplete;

  const VoiceRecorderWidget({
    super.key,
    required this.onRecordingComplete,
  });

  @override
  State<VoiceRecorderWidget> createState() => _VoiceRecorderWidgetState();
}

class _VoiceRecorderWidgetState extends State<VoiceRecorderWidget>
    with SingleTickerProviderStateMixin {
  bool _isRecording = false;
  int _seconds = 0;
  late AnimationController _pulseController;

  @override
  void initState() {
    super.initState();
    _pulseController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1000),
    )..repeat(reverse: true);
  }

  @override
  void dispose() {
    _pulseController.dispose();
    super.dispose();
  }

  void _toggleRecording() {
    setState(() {
      _isRecording = !_isRecording;
      if (_isRecording) {
        _seconds = 0;
        _startTimer();
      } else {
        // Recording stopped — return stub path
        // TODO: Replace with actual recording file path from `record` package
        widget.onRecordingComplete('voice_note_${DateTime.now().millisecondsSinceEpoch}.m4a');
      }
    });
  }

  void _startTimer() {
    Future.doWhile(() async {
      await Future.delayed(const Duration(seconds: 1));
      if (!_isRecording || !mounted) return false;
      setState(() => _seconds++);
      return true;
    });
  }

  void _cancel() {
    setState(() {
      _isRecording = false;
      _seconds = 0;
    });
    widget.onRecordingComplete(null);
  }

  String _formatTime(int seconds) {
    final m = (seconds ~/ 60).toString().padLeft(2, '0');
    final s = (seconds % 60).toString().padLeft(2, '0');
    return '$m:$s';
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppTheme.bgSurface,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: AppTheme.border),
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          const Text(
            'VOICE NOTE',
            style: TextStyle(
              color: AppTheme.textMuted,
              fontSize: 10,
              fontWeight: FontWeight.w700,
              letterSpacing: 1,
            ),
          ),
          const SizedBox(height: 12),
          // Timer display
          Text(
            _formatTime(_seconds),
            style: const TextStyle(
              fontSize: 32,
              fontWeight: FontWeight.w700,
              fontFamily: 'monospace',
              color: AppTheme.textPrimary,
            ),
          ),
          const SizedBox(height: 16),
          // Record button with pulse
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              if (_isRecording)
                TextButton(
                  onPressed: _cancel,
                  child: const Text(
                    'Cancel',
                    style: TextStyle(color: AppTheme.textMuted),
                  ),
                ),
              const SizedBox(width: 16),
              GestureDetector(
                onTap: _toggleRecording,
                child: AnimatedBuilder(
                  animation: _pulseController,
                  builder: (context, child) {
                    final scale = _isRecording
                        ? 1.0 + (_pulseController.value * 0.15)
                        : 1.0;
                    return Transform.scale(
                      scale: scale,
                      child: Container(
                        width: 56,
                        height: 56,
                        decoration: BoxDecoration(
                          shape: BoxShape.circle,
                          color: _isRecording
                              ? AppTheme.danger
                              : AppTheme.accent,
                          boxShadow: _isRecording
                              ? [
                                  BoxShadow(
                                    color: AppTheme.danger.withValues(alpha: 0.4),
                                    blurRadius: 16,
                                    spreadRadius: 2,
                                  )
                                ]
                              : [],
                        ),
                        child: Icon(
                          _isRecording ? Icons.stop_rounded : Icons.mic_rounded,
                          color: Colors.white,
                          size: 28,
                        ),
                      ),
                    );
                  },
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          Text(
            _isRecording ? 'Tap to stop recording' : 'Tap to start recording',
            style: const TextStyle(
              color: AppTheme.textMuted,
              fontSize: 12,
            ),
          ),
          const SizedBox(height: 8),
          // TODO notice
          Container(
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              color: AppTheme.warning.withValues(alpha: 0.1),
              borderRadius: BorderRadius.circular(6),
            ),
            child: const Text(
              'Transcription via Gemma — awaiting backend endpoint',
              style: TextStyle(
                color: AppTheme.warning,
                fontSize: 10,
                fontWeight: FontWeight.w500,
              ),
              textAlign: TextAlign.center,
            ),
          ),
        ],
      ),
    );
  }
}
