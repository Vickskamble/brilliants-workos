import 'package:flutter/material.dart';
import '../theme/app_theme.dart';

class PriorityBadge extends StatelessWidget {
  final String priority;
  final bool compact;

  const PriorityBadge({super.key, required this.priority, this.compact = false});

  @override
  Widget build(BuildContext context) {
    final (color, label) = switch (priority) {
      'URGENT' => (AppColors.urgent, 'Urgent'),
      'HIGH' => (AppColors.high, 'High'),
      'MEDIUM' => (AppColors.medium, 'Medium'),
      'LOW' => (AppColors.low, 'Low'),
      _ => (AppColors.textTertiary, priority),
    };

    return Container(
      padding: compact
          ? const EdgeInsets.symmetric(horizontal: 6, vertical: 2)
          : const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(6),
        border: Border.all(color: color.withValues(alpha: 0.3)),
      ),
      child: Text(
        label,
        style: TextStyle(
          fontSize: compact ? 10 : 12,
          fontWeight: FontWeight.w600,
          color: color,
        ),
      ),
    );
  }
}
