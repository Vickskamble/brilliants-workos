import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import '../../../core/theme/app_theme.dart';
import '../../../core/utils/formatters.dart';
import '../../../core/widgets/status_badge.dart';
import '../../../core/widgets/priority_badge.dart';
import '../../../core/widgets/loading_state.dart';
import '../../../core/widgets/empty_state.dart';
import '../../blocs/tasks/tasks_bloc.dart';

class TaskDetailPage extends StatefulWidget {
  final String taskId;
  const TaskDetailPage({super.key, required this.taskId});

  @override
  State<TaskDetailPage> createState() => _TaskDetailPageState();
}

class _TaskDetailPageState extends State<TaskDetailPage> {
  final _resultController = TextEditingController();
  final _commentController = TextEditingController();
  final _actualValueController = TextEditingController();
  bool _updating = false;

  @override
  void initState() {
    super.initState();
    context.read<TasksBloc>().add(LoadTaskDetail(widget.taskId));
  }

  @override
  void dispose() {
    _resultController.dispose();
    _commentController.dispose();
    _actualValueController.dispose();
    super.dispose();
  }

  void _onUpdateStatus(String status) async {
    setState(() => _updating = true);

    final result = _resultController.text.trim();
    final comment = _commentController.text.trim();
    final actualText = _actualValueController.text.trim();

    context.read<TasksBloc>().add(
          UpdateTaskStatus(
            widget.taskId,
            status,
            result: result.isEmpty ? null : result,
            comment: comment.isEmpty ? null : comment,
            actualValue: actualText.isEmpty ? null : double.tryParse(actualText),
          ),
        );

    setState(() => _updating = false);
  }

  String _friendlyStatus(String status) {
    switch (status) {
      case 'IN_PROGRESS':
        return 'In Progress';
      case 'COMPLETED':
        return 'Completed';
      case 'CANCELLED':
        return 'Cancelled';
      default:
        return status;
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Task Detail')),
      body: BlocListener<TasksBloc, TasksState>(
        listener: (context, state) {
          if (state is TasksError) {
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(content: Text(state.message), backgroundColor: AppColors.error),
            );
          } else if (state is TaskUpdated) {
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(
                content: Text('Task marked as ${_friendlyStatus(state.task.status)}'),
                backgroundColor: AppColors.success,
              ),
            );
            context.read<TasksBloc>().add(LoadTaskDetail(widget.taskId));
          }
        },
        child: BlocBuilder<TasksBloc, TasksState>(
          builder: (context, state) {
            if (state is TasksLoading) {
              return const LoadingState(message: 'Loading task...');
            }

            if (state is TasksError) {
              return EmptyState(
                icon: Icons.error_outline,
                title: 'Failed to load task',
                subtitle: state.message,
                action: ElevatedButton(
                  onPressed: () => context.read<TasksBloc>().add(LoadTaskDetail(widget.taskId)),
                  child: const Text('Retry'),
                ),
              );
            }

            final task = state is TaskDetailLoaded ? state.task : null;
            if (task == null) return const SizedBox.shrink();

            return SingleChildScrollView(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Title + priority
                  Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Expanded(
                        child: Text(
                          task.title,
                          style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                                fontWeight: FontWeight.bold,
                              ),
                        ),
                      ),
                      PriorityBadge(priority: task.priority),
                    ],
                  ),
                  const SizedBox(height: 16),

                  // Status + due date
                  Row(
                    children: [
                      StatusBadge(status: task.status),
                      const SizedBox(width: 12),
                      if (task.dueDate != null) ...[
                        Icon(Icons.calendar_today, size: 16, color: task.isOverdue ? AppColors.error : AppColors.textSecondary),
                        const SizedBox(width: 4),
                        Text(
                          'Due: ${AppFormatters.formatDate(task.dueDate!)}',
                          style: TextStyle(
                            color: task.isOverdue ? AppColors.error : AppColors.textSecondary,
                            fontWeight: task.isOverdue ? FontWeight.bold : null,
                          ),
                        ),
                      ],
                    ],
                  ),
                  const SizedBox(height: 8),

                  // Assignee
                  if (task.assigneeName != null)
                    ListTile(
                      contentPadding: EdgeInsets.zero,
                      leading: CircleAvatar(child: Text(task.assigneeName![0].toUpperCase())),
                      title: Text('Assigned To: ${task.assigneeName}'),
                      subtitle: task.assignerName != null ? Text('By: ${task.assignerName}') : null,
                    ),

                  // Description
                  if (task.description != null && task.description!.isNotEmpty) ...[
                    const SizedBox(height: 16),
                    Text(
                      'Description',
                      style: Theme.of(context).textTheme.titleSmall?.copyWith(fontWeight: FontWeight.w600),
                    ),
                    const SizedBox(height: 8),
                    Text(task.description!, style: Theme.of(context).textTheme.bodyMedium),
                  ],

                  // Target values
                  if (task.targetValue != null) ...[
                    const SizedBox(height: 16),
                    Text(
                      'Target: ${task.targetValue!.toInt()}',
                      style: Theme.of(context).textTheme.titleSmall?.copyWith(fontWeight: FontWeight.w600),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      'Actual: ${task.actualValue ?? 0}',
                      style: Theme.of(context).textTheme.bodyMedium,
                    ),
                  ],

                  // Result/comment (if completed)
                  if (task.isCompleted && (task.result != null || task.comment != null)) ...[
                    const SizedBox(height: 16),
                    if (task.result != null) ...[
                      Text('Result', style: Theme.of(context).textTheme.titleSmall?.copyWith(fontWeight: FontWeight.w600)),
                      const SizedBox(height: 4),
                      Text(task.result!, style: Theme.of(context).textTheme.bodyMedium),
                    ],
                    if (task.comment != null) ...[
                      const SizedBox(height: 12),
                      Text('Comment', style: Theme.of(context).textTheme.titleSmall?.copyWith(fontWeight: FontWeight.w600)),
                      const SizedBox(height: 4),
                      Text(task.comment!, style: Theme.of(context).textTheme.bodyMedium),
                    ],
                  ],

                  const SizedBox(height: 24),

                  // Status update (only if not completed/cancelled)
                  if (!task.isCompleted && task.status != 'CANCELLED') ...[
                    Text(
                      'Update Task',
                      style: Theme.of(context).textTheme.titleMedium?.copyWith(fontWeight: FontWeight.w600),
                    ),
                    const SizedBox(height: 16),

                    // Result
                    if (task.targetValue != null) ...[
                      TextFormField(
                        controller: _actualValueController,
                        keyboardType: TextInputType.number,
                        decoration: InputDecoration(
                          labelText: 'Actual Value',
                          hintText: 'Enter actual achievement ${task.targetValue!.toInt()}',
                        ),
                      ),
                      const SizedBox(height: 12),
                    ],

                    TextFormField(
                      controller: _resultController,
                      decoration: const InputDecoration(
                        labelText: 'Result',
                        hintText: 'What was the outcome?',
                      ),
                    ),
                    const SizedBox(height: 12),

                    TextFormField(
                      controller: _commentController,
                      decoration: const InputDecoration(
                        labelText: 'Comment',
                        hintText: 'Add any comments...',
                      ),
                      maxLines: 2,
                    ),
                    const SizedBox(height: 16),

                    // Status buttons
                    if (task.isTodo)
                      SizedBox(
                        width: double.infinity,
                        child: ElevatedButton(
                          onPressed: _updating ? null : () => _onUpdateStatus('IN_PROGRESS'),
                          child: const Text('Start Task'),
                        ),
                      )
                    else if (task.isInProgress)
                      SizedBox(
                        width: double.infinity,
                        child: ElevatedButton(
                          onPressed: _updating ? null : () => _onUpdateStatus('COMPLETED'),
                          style: ElevatedButton.styleFrom(backgroundColor: AppColors.success),
                          child: const Text('Mark Complete'),
                        ),
                      ),
                  ],

                  // Completed message
                  if (task.isCompleted) ...[
                    const SizedBox(height: 16),
                    Container(
                      padding: const EdgeInsets.all(16),
                      decoration: BoxDecoration(
                        color: AppColors.successLight,
                        borderRadius: BorderRadius.circular(10),
                      ),
                      child: Row(
                        children: [
                          const Icon(Icons.check_circle, color: AppColors.success),
                          const SizedBox(width: 12),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text('Task Completed',
                                    style: Theme.of(context).textTheme.titleSmall?.copyWith(
                                          color: AppColors.success,
                                          fontWeight: FontWeight.w600,
                                        )),
                                if (task.completedAt != null)
                                  Text(
                                    AppFormatters.formatDateTime(task.completedAt!),
                                    style: Theme.of(context).textTheme.bodySmall?.copyWith(color: AppColors.success),
                                  ),
                              ],
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ],
              ),
            );
          },
        ),
      ),
    );
  }
}
