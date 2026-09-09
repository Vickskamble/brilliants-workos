import 'package:flutter/material.dart';
import '../theme/app_theme.dart';

class PerformanceRing extends StatelessWidget {
  final double percentage;
  final double size;
  final double strokeWidth;
  final String? label;

  const PerformanceRing({
    super.key,
    required this.percentage,
    this.size = 80,
    this.strokeWidth = 8,
    this.label,
  });

  Color get _bandColor {
    if (percentage >= 85) return AppColors.excellent;
    if (percentage >= 70) return AppColors.good;
    if (percentage >= 50) return AppColors.average;
    return AppColors.needsAttention;
  }

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: size,
      height: size,
      child: Stack(
        alignment: Alignment.center,
        children: [
          SizedBox(
            width: size,
            height: size,
            child: CircularProgressIndicator(
              value: percentage / 100,
              strokeWidth: strokeWidth,
              backgroundColor: AppColors.divider,
              valueColor: AlwaysStoppedAnimation(_bandColor),
              strokeCap: StrokeCap.round,
            ),
          ),
          Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(
                '${percentage.round()}%',
                style: TextStyle(
                  fontSize: size * 0.22,
                  fontWeight: FontWeight.bold,
                  color: _bandColor,
                ),
              ),
              if (label != null)
                Text(
                  label!,
                  style: TextStyle(
                    fontSize: size * 0.12,
                    color: AppColors.textSecondary,
                  ),
                ),
            ],
          ),
        ],
      ),
    );
  }
}
