import 'package:supabase_flutter/supabase_flutter.dart';
import '../../domain/entities/notification.dart';

class NotificationDatasource {
  final SupabaseClient _client;

  NotificationDatasource(this._client);

  Future<List<AppNotification>> getNotifications({
    bool unreadOnly = false,
    int limit = 50,
  }) async {
    final userId = _client.auth.currentUser?.id;

    var query = _client
        .from('workos_notifications')
        .select()
        .eq('user_id', userId!);

    if (unreadOnly) {
      query = query.eq('is_read', false);
    }

    final data = await query.order('created_at', ascending: false).limit(limit);
    return (data as List).map((e) => AppNotification.fromJson(e as Map<String, dynamic>)).toList();
  }

  Future<int> getUnreadCount() async {
    final userId = _client.auth.currentUser?.id;
    if (userId == null) return 0;

    final data = await _client
        .from('workos_notifications')
        .select('id')
        .eq('user_id', userId)
        .eq('is_read', false);

    return (data as List).length;
  }

  Future<void> markAsRead(String notificationId) async {
    await _client
        .from('workos_notifications')
        .update({'is_read': true})
        .eq('id', notificationId);
  }

  Future<void> markAllAsRead() async {
    final userId = _client.auth.currentUser?.id;
    await _client
        .from('workos_notifications')
        .update({'is_read': true})
        .eq('user_id', userId!)
        .eq('is_read', false);
  }

  Future<void> deleteNotification(String notificationId) async {
    await _client
        .from('workos_notifications')
        .delete()
        .eq('id', notificationId);
  }

  /// Subscribe to real-time notifications
  RealtimeChannel subscribeToNotifications({
    required void Function(AppNotification) onNotification,
  }) {
    final userId = _client.auth.currentUser?.id;

    return _client
        .channel('notifications:$userId')
        .onPostgresChanges(
          event: PostgresChangeEvent.insert,
          schema: 'public',
          table: 'workos_notifications',
          filter: PostgresChangeFilter(
            type: PostgresChangeFilterType.eq,
            column: 'user_id',
            value: userId,
          ),
          callback: (payload) {
            if (payload.newRecord.isNotEmpty) {
              onNotification(AppNotification.fromJson(payload.newRecord));
            }
          },
        )
        .subscribe();
  }
}
