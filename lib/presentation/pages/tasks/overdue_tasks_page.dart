import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import '../../../core/theme/app_theme.dart';
import '../../../core/widgets/empty_state.dart';
import '../../../core/widgets/priority_badge.dart';
import '../../blocs/tasks/tasks_bloc.dart';
import '../../../domain/entities/task.dart';

class OverdueTasksPage extends StatelessWidget {
  const OverdueTasksPage({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Overdue Tasks')),
      body: BlocBuilder<TasksBloc, TasksState>(
        builder: (context, state) {
          if (state is TasksLoading) {
            return const Center(child: CircularProgressIndicator());
          }
          if (state is TasksError) {
            return Center(child: Text(state.message));
          }
          if (state is OverdueTasksLoaded) {
            if (state.tasks.isEmpty) {
              return const EmptyState(
                icon: Icons.check_circle_outline,
                title: 'No Overdue Tasks',
                subtitle: 'Great job! All tasks are on track.',
              );
            }
            return ListView.separated(
              padding: const EdgeInsets.all(16),
              itemCount: state.tasks.length,
              separatorBuilder: (_, __) => const SizedBox(height: 8),
              itemBuilder: (context, index) {
                final task = state.tasks[index];
                return _OverdueCard(task: task);
              },
            );
          }
          return const SizedBox.shrink();
        },
      ),
    );
  }
}

class _OverdueCard extends StatelessWidget {
  final Task task;
  const _OverdueCard({required this.task});

  @override
  Widget build(BuildContext context) {
    return Card(
      color: AppColors.errorLight.withValues(alpha: 0.5),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Row(
          children: [
            const Icon(Icons.warning_amber, color: AppColors.error),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    task.title,
                    style: Theme.of(context).textTheme.titleMedium?.copyWith(fontWeight: FontWeight.w600),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    task.assigneeName != null ? 'Assigned to: ${task.assigneeName}' : 'Unassigned',
                    style: Theme.of(context).textTheme.bodySmall?.copyWith(color: AppColors.textSecondary),
                  ),
                  Text(
                    'Overdue by ${task.daysOverdue} day${task.daysOverdue > 1 ? 's' : ''}',
                    style: const TextStyle(color: AppColors.error, fontSize: 12),
                  ),
                ],
              ),
            ),
            PriorityBadge(priority: task.priority, compact: true),
          ],
        ),
      ),
    );
  }
}
