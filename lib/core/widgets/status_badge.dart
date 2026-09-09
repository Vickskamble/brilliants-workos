import 'package:flutter/material.dart';
import '../theme/app_theme.dart';

class StatusBadge extends StatelessWidget {
  final String status;
  final bool compact;

  const StatusBadge({super.key, required this.status, this.compact = false});

  @override
  Widget build(BuildContext context) {
    final (color, label, icon) = switch (status) {
      'TODO' => (AppColors.textSecondary, 'To Do', Icons.schedule),
      'IN_PROGRESS' => (AppColors.info, 'In Progress', Icons.play_circle_outline),
      'COMPLETED' => (AppColors.success, 'Completed', Icons.check_circle_outline),
      'CANCELLED' => (AppColors.textTertiary, 'Cancelled', Icons.cancel_outlined),
      'DRAFT' => (AppColors.textSecondary, 'Draft', Icons.edit_note),
      'SUBMITTED' => (AppColors.info, 'Submitted', Icons.send),
      'REVIEWED' => (AppColors.success, 'Reviewed', Icons.fact_check_outlined),
      _ => (AppColors.textTertiary, status, Icons.help_outline),
    };

    return Container(
      padding: compact
          ? const EdgeInsets.symmetric(horizontal: 6, vertical: 2)
          : const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(6),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: compact ? 12 : 14, color: color),
          const SizedBox(width: 4),
          Text(
            label,
            style: TextStyle(
              fontSize: compact ? 10 : 12,
              fontWeight: FontWeight.w600,
              color: color,
            ),
          ),
        ],
      ),
    );
  }
}
