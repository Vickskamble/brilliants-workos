import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import '../../../core/theme/app_theme.dart';
import '../../../core/utils/formatters.dart';
import '../../../core/widgets/empty_state.dart';
import '../../blocs/dashboard/dashboard_bloc.dart';

class NotificationsPage extends StatefulWidget {
  const NotificationsPage({super.key});

  @override
  State<NotificationsPage> createState() => _NotificationsPageState();
}

class _NotificationsPageState extends State<NotificationsPage> {
  @override
  void initState() {
    super.initState();
    context.read<DashboardBloc>().add(LoadNotifications());
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Notifications'),
        actions: [
          IconButton(
            icon: const Icon(Icons.done_all),
            tooltip: 'Mark all as read',
            onPressed: () => context.read<DashboardBloc>().add(MarkAllNotificationsRead()),
          ),
        ],
      ),
      body: BlocBuilder<DashboardBloc, DashboardState>(
        builder: (context, state) {
          if (state is DashboardLoading) {
            return const Center(child: CircularProgressIndicator());
          }

          if (state is DashboardError) {
            return Center(child: Text(state.message));
          }

          if (state is NotificationsLoaded) {
            if (state.notifications.isEmpty) {
              return const EmptyState(
                icon: Icons.notifications_none,
                title: 'No Notifications Yet',
                subtitle: 'You\'ll see task assignments, reminders, and alerts here.',
              );
            }

            return ListView.separated(
              padding: const EdgeInsets.all(16),
              itemCount: state.notifications.length,
              separatorBuilder: (_, __) => const SizedBox(height: 8),
              itemBuilder: (context, index) {
                final notification = state.notifications[index];
                final color = _notificationColor(notification.type);
                return ListTile(
                  leading: CircleAvatar(
                    backgroundColor: color.withValues(alpha: 0.1),
                    child: Icon(_notificationIcon(notification.type), color: color, size: 20),
                  ),
                  title: Text(
                    notification.title,
                    style: TextStyle(
                      fontWeight: notification.isRead ? FontWeight.normal : FontWeight.bold,
                    ),
                  ),
                  subtitle: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(notification.body),
                      const SizedBox(height: 4),
                      Text(
                        AppFormatters.formatDateTime(notification.createdAt),
                        style: Theme.of(context).textTheme.bodySmall?.copyWith(color: AppColors.textTertiary),
                      ),
                    ],
                  ),
                  trailing: notification.isRead
                      ? null
                      : Container(
                          width: 10,
                          height: 10,
                          decoration: const BoxDecoration(
                            color: AppColors.primary,
                            shape: BoxShape.circle,
                          ),
                        ),
                  onTap: () {
                    if (!notification.isRead) {
                      context.read<DashboardBloc>().add(MarkNotificationRead(notification.id));
                    }
                  },
                );
              },
            );
          }

          return const SizedBox.shrink();
        },
      ),
    );
  }

  Color _notificationColor(String type) {
    switch (type) {
      case 'TASK_OVERDUE':
      case 'TASK_ESCALATION':
      case 'TASK_CRITICAL':
        return AppColors.error;
      case 'TARGET_ACHIEVED':
        return AppColors.success;
      case 'TASK_REMINDER':
        return AppColors.warning;
      default:
        return AppColors.primary;
    }
  }

  IconData _notificationIcon(String type) {
    switch (type) {
      case 'TASK_OVERDUE':
      case 'TASK_ESCALATION':
      case 'TASK_CRITICAL':
        return Icons.warning_amber;
      case 'TARGET_ACHIEVED':
        return Icons.emoji_events_outlined;
      case 'TASK_REMINDER':
        return Icons.alarm;
      default:
        return Icons.notifications_outlined;
    }
  }
}
