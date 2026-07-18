import 'package:flutter/material.dart';
import '../theme/app_theme.dart';

/// Continuous red→amber→green score display.
/// [variant]: 'chip' for compact pills, 'bar' for large hero display.
class ScoreGradientWidget extends StatelessWidget {
  final int score;
  final String variant;

  const ScoreGradientWidget({
    super.key,
    required this.score,
    this.variant = 'chip',
  });

  @override
  Widget build(BuildContext context) {
    if (variant == 'bar') return _buildBar();
    return _buildChip();
  }

  Widget _buildChip() {
    final color = AppTheme.scoreToColor(score);
    final mutedColor = AppTheme.scoreToMutedColor(score);

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
      decoration: BoxDecoration(
        color: mutedColor,
        borderRadius: BorderRadius.circular(6),
        border: Border.all(color: color.withValues(alpha: 0.3)),
      ),
      child: Text(
        score.toString(),
        style: TextStyle(
          color: color,
          fontSize: 14,
          fontWeight: FontWeight.w700,
          fontFamily: 'monospace',
        ),
      ),
    );
  }

  Widget _buildBar() {
    final color = AppTheme.scoreToColor(score);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Score value
        Row(
          crossAxisAlignment: CrossAxisAlignment.baseline,
          textBaseline: TextBaseline.alphabetic,
          children: [
            TweenAnimationBuilder<int>(
              tween: IntTween(begin: 0, end: score),
              duration: const Duration(milliseconds: 1200),
              curve: Curves.easeOutCubic,
              builder: (context, value, _) {
                final animColor = AppTheme.scoreToColor(value);
                return Text(
                  value.toString(),
                  style: TextStyle(
                    color: animColor,
                    fontSize: 48,
                    fontWeight: FontWeight.w800,
                    fontFamily: 'monospace',
                    height: 1,
                  ),
                );
              },
            ),
            const SizedBox(width: 4),
            const Text(
              '/ 100',
              style: TextStyle(
                color: AppTheme.textMuted,
                fontSize: 16,
              ),
            ),
          ],
        ),
        const SizedBox(height: 10),
        // Track
        TweenAnimationBuilder<double>(
          tween: Tween(begin: 0, end: score / 100.0),
          duration: const Duration(milliseconds: 1200),
          curve: Curves.easeOutCubic,
          builder: (context, value, _) {
            return Stack(
              clipBehavior: Clip.none,
              children: [
                // Background track
                Container(
                  height: 8,
                  decoration: BoxDecoration(
                    color: AppTheme.bgElevated,
                    borderRadius: BorderRadius.circular(4),
                  ),
                ),
                // Filled portion with gradient
                FractionallySizedBox(
                  widthFactor: value,
                  child: Container(
                    height: 8,
                    decoration: BoxDecoration(
                      borderRadius: BorderRadius.circular(4),
                      gradient: LinearGradient(
                        colors: List.generate(
                          11,
                          (i) => AppTheme.scoreToColor(i * 10),
                        ),
                      ),
                    ),
                  ),
                ),
                // Marker dot
                Positioned(
                  left: (value *
                          (MediaQuery.of(
                                    context,
                                  ).size.width -
                              80)) -
                      7,
                  top: -3,
                  child: Container(
                    width: 14,
                    height: 14,
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      color: color,
                      border: Border.all(
                        color: AppTheme.bgPrimary,
                        width: 2,
                      ),
                      boxShadow: [
                        BoxShadow(
                          color: color.withValues(alpha: 0.5),
                          blurRadius: 8,
                        ),
                      ],
                    ),
                  ),
                ),
              ],
            );
          },
        ),
        const SizedBox(height: 6),
        // Labels
        const Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text(
              'HIGH RISK',
              style: TextStyle(
                color: AppTheme.textMuted,
                fontSize: 10,
                fontWeight: FontWeight.w600,
                letterSpacing: 0.5,
              ),
            ),
            Text(
              'MODERATE',
              style: TextStyle(
                color: AppTheme.textMuted,
                fontSize: 10,
                fontWeight: FontWeight.w600,
                letterSpacing: 0.5,
              ),
            ),
            Text(
              'LOW RISK',
              style: TextStyle(
                color: AppTheme.textMuted,
                fontSize: 10,
                fontWeight: FontWeight.w600,
                letterSpacing: 0.5,
              ),
            ),
          ],
        ),
      ],
    );
  }
}
