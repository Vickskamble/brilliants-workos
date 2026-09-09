import 'package:flutter/material.dart';
import '../theme/app_theme.dart';

class PerformanceRing extends StatelessWidget {
  final double percentage;
  final double size;
  final double strokeWidth;
  final String? label;
  final Color? ringColor;
  final Color? trackColor;
  final Color? textColor;
  final Color? labelColor;
  final Color? centerBackground;

  const PerformanceRing({
    super.key,
    required this.percentage,
    this.size = 80,
    this.strokeWidth = 8,
    this.label,
    this.ringColor,
    this.trackColor,
    this.textColor,
    this.labelColor,
    this.centerBackground,
  });

  Color get _bandColor {
    if (ringColor != null) return ringColor!;
    if (percentage >= 85) return AppColors.excellent;
    if (percentage >= 70) return AppColors.good;
    if (percentage >= 50) return AppColors.average;
    return AppColors.needsAttention;
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      width: size,
      height: size,
      decoration: BoxDecoration(
        color: centerBackground ?? Colors.transparent,
        shape: BoxShape.circle,
      ),
      child: Stack(
        alignment: Alignment.center,
        children: [
          SizedBox(
            width: size,
            height: size,
            child: CircularProgressIndicator(
              value: percentage / 100,
              strokeWidth: strokeWidth,
              backgroundColor: trackColor ?? AppColors.divider,
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
                  color: textColor ?? _bandColor,
                ),
              ),
              if (label != null)
                Text(
                  label!,
                  style: TextStyle(
                    fontSize: size * 0.12,
                    color: labelColor ?? AppColors.textSecondary,
                  ),
                ),
            ],
          ),
        ],
      ),
    );
  }
}