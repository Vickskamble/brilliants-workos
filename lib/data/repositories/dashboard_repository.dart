import 'package:supabase_flutter/supabase_flutter.dart';
import '../datasources/notification_datasource.dart';
import '../datasources/dashboard_datasource.dart';
import '../../domain/entities/notification.dart';
import '../../domain/entities/dashboard_stats.dart';
import '../../domain/entities/standup.dart';

class DashboardRepository {
  final DashboardDatasource _dashboardDatasource;
  final NotificationDatasource _notificationDatasource;

  DashboardRepository(SupabaseClient client)
      : _dashboardDatasource = DashboardDatasource(client),
        _notificationDatasource = NotificationDatasource(client);

  Future<DashboardStats> getDashboardStats() => _dashboardDatasource.getDashboardStats();
  Future<Standup?> getTodayStandup(String profileId) => _dashboardDatasource.getTodayStandup(profileId);
  Future<Standup> saveStandup(Map<String, dynamic> data) => _dashboardDatasource.saveStandup(data);

  // Notifications
  Future<List<AppNotification>> getNotifications({bool unreadOnly = false}) =>
      _notificationDatasource.getNotifications(unreadOnly: unreadOnly);
  Future<int> getUnreadCount() => _notificationDatasource.getUnreadCount();
  Future<void> markAsRead(String id) => _notificationDatasource.markAsRead(id);
  Future<void> markAllAsRead() => _notificationDatasource.markAllAsRead();
  RealtimeChannel subscribeToNotifications({required void Function(AppNotification) onNotification}) =>
      _notificationDatasource.subscribeToNotifications(onNotification: onNotification);
}
