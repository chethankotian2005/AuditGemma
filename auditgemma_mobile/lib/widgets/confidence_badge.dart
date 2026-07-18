import 'package:flutter/material.dart';
import '../theme/app_theme.dart';

class ConfidenceBadge extends StatelessWidget {
  final String confidence;

  const ConfidenceBadge({super.key, required this.confidence});

  @override
  Widget build(BuildContext context) {
    final Color color;
    switch (confidence) {
      case 'high':
        color = AppTheme.success;
      case 'moderate':
        color = AppTheme.warning;
      case 'low':
        color = AppTheme.danger;
      default:
        color = AppTheme.textMuted;
    }

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.12),
        borderRadius: BorderRadius.circular(6),
        border: Border.all(color: color.withValues(alpha: 0.2)),
      ),
      child: Text(
        '${confidence.toUpperCase()} CONFIDENCE',
        style: TextStyle(
          color: color,
          fontSize: 10,
          fontWeight: FontWeight.w700,
          letterSpacing: 0.5,
        ),
      ),
    );
  }
}
