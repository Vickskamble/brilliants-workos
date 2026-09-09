import 'package:fl_chart/fl_chart.dart';
import 'package:flutter/material.dart';
import '../theme/app_theme.dart';

class TaskStatusDonut extends StatelessWidget {
  final int todo;
  final int inProgress;
  final int completed;

  const TaskStatusDonut({
    super.key,
    required this.todo,
    required this.inProgress,
    required this.completed,
  });

  int get total => todo + inProgress + completed;
  double get completionRate => total > 0 ? (completed / total * 100) : 0;

  @override
  Widget build(BuildContext context) {
    final sections = <PieChartSectionData>[
      if (completed > 0)
        PieChartSectionData(
          value: completed.toDouble(),
          color: AppColors.success,
          radius: 58,
        ),
      if (inProgress > 0)
        PieChartSectionData(
          value: inProgress.toDouble(),
          color: AppColors.info,
          radius: 58,
        ),
      if (todo > 0)
        PieChartSectionData(
          value: todo.toDouble(),
          color: AppColors.warning,
          radius: 58,
        ),
    ];

    if (sections.isEmpty) {
      sections.add(PieChartSectionData(value: 1, color: AppColors.divider, radius: 58));
    }

    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        SizedBox(
          height: 170,
          child: Stack(
            alignment: Alignment.center,
            children: [
              PieChart(
                PieChartData(
                  sections: sections,
                  centerSpaceRadius: 46,
                  sectionsSpace: 4,
                  startDegreeOffset: -90,
                ),
              ),
              Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(
                    '${completionRate.toStringAsFixed(0)}%',
                    style: Theme.of(context).textTheme.titleLarge?.copyWith(
                          fontWeight: FontWeight.w800,
                          color: AppColors.textPrimary,
                        ),
                  ),
                  Text(
                    '$total tasks',
                    style: Theme.of(context).textTheme.bodySmall?.copyWith(
                          color: AppColors.textSecondary,
                        ),
                  ),
                ],
              ),
            ],
          ),
        ),
        const SizedBox(height: 12),
        Wrap(
          spacing: 16,
          runSpacing: 8,
          alignment: WrapAlignment.center,
          children: [
            _LegendDot(color: AppColors.success, label: 'Completed ($completed)'),
            _LegendDot(color: AppColors.info, label: 'In Progress ($inProgress)'),
            _LegendDot(color: AppColors.warning, label: 'Pending ($todo)'),
          ],
        ),
      ],
    );
  }
}

class _LegendDot extends StatelessWidget {
  final Color color;
  final String label;

  const _LegendDot({required this.color, required this.label});

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Container(
          width: 10,
          height: 10,
          decoration: BoxDecoration(color: color, shape: BoxShape.circle),
        ),
        const SizedBox(width: 6),
        Text(
          label,
          style: Theme.of(context).textTheme.bodySmall?.copyWith(
                color: AppColors.textSecondary,
                fontWeight: FontWeight.w600,
              ),
        ),
      ],
    );
  }
}