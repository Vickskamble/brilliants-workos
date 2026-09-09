import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import '../../../core/theme/app_theme.dart';
import '../../../core/utils/formatters.dart';
import '../../../core/widgets/status_badge.dart';
import '../../../core/widgets/priority_badge.dart';
import '../../../core/widgets/empty_state.dart';
import '../../blocs/tasks/tasks_bloc.dart';
import '../../../domain/entities/task.dart';

class MyTasksPage extends StatefulWidget {
  const MyTasksPage({super.key});

  @override
  State<MyTasksPage> createState() => _MyTasksPageState();
}

class _MyTasksPageState extends State<MyTasksPage> {
  @override
  void initState() {
    super.initState();
    context.read<TasksBloc>().add(LoadMyTasks());
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('My Tasks'),
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh),
            onPressed: () => context.read<TasksBloc>().add(LoadMyTasks()),
          ),
        ],
      ),
      body: BlocBuilder<TasksBloc, TasksState>(
        builder: (context, state) {
          if (state is TasksLoading) {
            return const Center(child: CircularProgressIndicator());
          }

          if (state is TasksError) {
            return Center(child: Text(state.message));
          }

          if (state is MyTasksLoaded) {
            if (state.tasks.isEmpty) {
              return const EmptyState(
                icon: Icons.task_outlined,
                title: 'No Tasks Today',
                subtitle: 'You have no tasks assigned for today.',
              );
            }

            return Column(
              children: [
                // Summary bar
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                  child: Row(
                    children: [
                      _SummaryChip(count: state.completedCount, label: 'Done', color: AppColors.success),
                      const SizedBox(width: 8),
                      _SummaryChip(count: state.pendingCount, label: 'Pending', color: AppColors.warning),
                      const SizedBox(width: 8),
                      _SummaryChip(count: state.overdueCount, label: 'Overdue', color: AppColors.error),
                      const Spacer(),
                      Text(
                        '${state.tasks.length} tasks',
                        style: Theme.of(context).textTheme.bodySmall?.copyWith(color: AppColors.textSecondary),
                      ),
                    ],
                  ),
                ),

                // Task list
                Expanded(
                  child: ListView.separated(
                    padding: const EdgeInsets.symmetric(horizontal: 16),
                    itemCount: state.tasks.length,
                    separatorBuilder: (_, _) => const SizedBox(height: 8),
                    itemBuilder: (context, index) {
                      final task = state.tasks[index];
                      return _TaskCard(task: task);
                    },
                  ),
                ),
              ],
            );
          }

          return const SizedBox.shrink();
        },
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: () => Navigator.pushNamed(context, '/assign-task'),
        child: const Icon(Icons.add),
      ),
    );
  }
}

class _SummaryChip extends StatelessWidget {
  final int count;
  final String label;
  final Color color;

  const _SummaryChip({required this.count, required this.label, required this.color});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(8),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Text(
            '$count',
            style: TextStyle(color: color, fontWeight: FontWeight.bold, fontSize: 14),
          ),
          const SizedBox(width: 4),
          Text(label, style: TextStyle(color: color, fontSize: 12)),
        ],
      ),
    );
  }
}

class _TaskCard extends StatelessWidget {
  final Task task;

  const _TaskCard({required this.task});

  @override
  Widget build(BuildContext context) {
    return Card(
      child: InkWell(
        onTap: () => Navigator.pushNamed(context, '/task-detail', arguments: task.id),
        borderRadius: BorderRadius.circular(12),
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Expanded(
                    child: Text(
                      task.title,
                      style: Theme.of(context).textTheme.titleMedium?.copyWith(
                            fontWeight: FontWeight.w600,
                            decoration: task.isCompleted ? TextDecoration.lineThrough : null,
                            color: task.isCompleted ? AppColors.textTertiary : null,
                          ),
                    ),
                  ),
                  PriorityBadge(priority: task.priority, compact: true),
                ],
              ),
              if (task.description != null && task.description!.isNotEmpty) ...[
                const SizedBox(height: 4),
                Text(
                  task.description!,
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                  style: Theme.of(context).textTheme.bodySmall?.copyWith(color: AppColors.textSecondary),
                ),
              ],
              const SizedBox(height: 8),
              Row(
                children: [
                  StatusBadge(status: task.status, compact: true),
                  const SizedBox(width: 8),
                  if (task.dueDate != null) ...[
                    Icon(Icons.calendar_today, size: 14, color: task.isOverdue ? AppColors.error : AppColors.textTertiary),
                    const SizedBox(width: 4),
                    Text(
                      AppFormatters.formatShortDate(task.dueDate!),
                      style: TextStyle(
                        fontSize: 12,
                        color: task.isOverdue ? AppColors.error : AppColors.textTertiary,
                        fontWeight: task.isOverdue ? FontWeight.w600 : null,
                      ),
                    ),
                  ],
                  const Spacer(),
                  if (task.targetValue != null)
                    Text(
                      '${task.actualValue ?? 0}/${task.targetValue!.toInt()}',
                      style: Theme.of(context).textTheme.bodySmall?.copyWith(
                            color: AppColors.textSecondary,
                            fontWeight: FontWeight.w600,
                          ),
                    ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}
