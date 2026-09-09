import 'package:flutter/foundation.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../../domain/entities/activity_point.dart';
import '../../domain/entities/dashboard_stats.dart';
import '../../domain/entities/leaderboard_entry.dart';
import '../../domain/entities/standup.dart';

class DashboardDatasource {
  final SupabaseClient _client;

  DashboardDatasource(this._client);

  Future<DashboardStats> getDashboardStats() async {
    final userId = _client.auth.currentUser?.id;
    if (userId == null) return const DashboardStats();

    // Get my profile
    final profile = await _client
        .from('workos_profiles')
        .select('id, company_id, full_name, role')
        .eq('user_id', userId)
        .maybeSingle();

    if (profile == null) return const DashboardStats();

    final companyId = profile['company_id'] as String;
    final today = DateTime.now().toIso8601String().split('T').first;

    // Company name
    String companyName = '';
    final company = await _client
        .from('workos_companies')
        .select('name')
        .eq('id', companyId)
        .maybeSingle();
    if (company != null) companyName = company['name'] as String? ?? '';

    // Teams count
    final teams = await _client
        .from('workos_teams')
        .select('id')
        .eq('company_id', companyId);

    // Active members count
    final activeMembers = await _client
        .from('workos_profiles')
        .select('id')
        .eq('company_id', companyId)
        .eq('is_active', true);

    // All tasks for the company
    final allTasks = await _client
        .from('workos_tasks')
        .select('id, status, due_date, completed_at')
        .eq('company_id', companyId);

    final todayScopeTasks =
        allTasks.where((t) {
          final due = t['due_date'] as String?;
          return due != null && due.compareTo(today) <= 0;
        }).toList();

    final completed =
        todayScopeTasks.where((t) => t['status'] == 'COMPLETED').length;
    final pending =
        todayScopeTasks.where(
              (t) => t['status'] == 'TODO' || t['status'] == 'IN_PROGRESS',
            ).length;
    final overdue =
        todayScopeTasks
            .where(
              (t) =>
                  (t['status'] == 'TODO' || t['status'] == 'IN_PROGRESS') &&
                  (t['due_date'] as String? ?? '').compareTo(today) < 0,
            )
            .length;

    // Status distribution across all tasks
    final statusTodo =
        allTasks.where((t) => t['status'] == 'TODO').length;
    final statusInProgress =
        allTasks.where((t) => t['status'] == 'IN_PROGRESS').length;
    final statusCompleted =
        allTasks.where((t) => t['status'] == 'COMPLETED').length;

    // Weekly activity: completed per day for the last 7 days
    final weeklyActivity = _buildWeeklyActivity(allTasks);

    // Monthly targets
    final monthStart = DateTime.now().copyWith(day: 1).toIso8601String().split('T').first;
    final monthEnd = DateTime(DateTime.now().year, DateTime.now().month + 1, 0)
        .toIso8601String().split('T').first;

    final targets = await _client
        .from('workos_targets')
        .select('target_value, current_value')
        .eq('company_id', companyId)
        .gte('period_start', monthStart)
        .lte('period_end', monthEnd);

    double targetTotal = 0;
    double targetAchieved = 0;
    for (final t in targets) {
      targetTotal += (t['target_value'] as num).toDouble();
      targetAchieved += (t['current_value'] as num).toDouble();
    }

    final targetAchievement = targetTotal > 0 ? (targetAchieved / targetTotal * 100) : 0.0;

    // Leaderboard: top performers
    List<LeaderboardEntry> leaderboard = const [];
    try {
      final raw = await _client.rpc('get_company_leaderboard', params: {'p_limit': 6});
      if (raw is List) {
        leaderboard = raw
            .whereType<Map<String, dynamic>>()
            .map(LeaderboardEntry.fromJson)
            .toList();
      }
    } catch (e) {
      // Leaderboard is best-effort; dashboard shouldn't fail because of it
      debugPrint('Leaderboard fetch failed: $e');
    }

    return DashboardStats(
      myProfileId: profile['id'] as String,
      fullName: profile['full_name'] as String? ?? '',
      role: profile['role'] as String? ?? '',
      companyName: companyName,
      totalTeam: activeMembers.length,
      totalTeams: teams.length,
      totalTasks: todayScopeTasks.length,
      completed: completed,
      inProgress: statusInProgress,
      pending: pending,
      overdue: overdue,
      allTodo: statusTodo,
      allInProgress: statusInProgress,
      allCompleted: statusCompleted,
      targetAchievement: double.parse(targetAchievement.toStringAsFixed(1)),
      targetAchieved: targetAchieved,
      targetTotal: targetTotal,
      weeklyActivity: weeklyActivity,
      leaderboard: leaderboard,
    );
  }

  List<ActivityPoint> _buildWeeklyActivity(List<Map<String, dynamic>> tasks) {
    final today = DateTime.now();
    final days = <ActivityPoint>[];
    final weekdays = ['Mon', 'Tue', 'Wed', 'Thu', 'Fri', 'Sat', 'Sun'];

    final counts = <String, int>{};
    for (final t in tasks) {
      if (t['status'] != 'COMPLETED') continue;
      final raw = t['completed_at'] as String?;
      if (raw == null) continue;
      try {
        final day = DateTime.parse(raw).toLocal();
        final key = '${day.year}-${day.month}-${day.day}';
        counts[key] = (counts[key] ?? 0) + 1;
      } catch (_) {}
    }

    for (int i = 6; i >= 0; i--) {
      final day = today.subtract(Duration(days: i));
      final key = '${day.year}-${day.month}-${day.day}';
      days.add(ActivityPoint(
        label: i == 0 ? 'Today' : weekdays[day.weekday - 1],
        value: counts[key] ?? 0,
      ));
    }
    return days;
  }

  /// Get today's standup for a member
  Future<Standup?> getTodayStandup(String profileId) async {
    final today = DateTime.now().toIso8601String().split('T').first;
    final data = await _client
        .from('workos_daily_standups')
        .select()
        .eq('profile_id', profileId)
        .eq('standup_date', today)
        .maybeSingle();

    if (data == null) return null;
    return Standup.fromJson(data);
  }

  /// Create or update today's standup
  Future<Standup> saveStandup(Map<String, dynamic> standupData) async {
    final profileId = standupData['profile_id'] as String;
    final date = standupData['standup_date'] as String;

    final existing = await _client
        .from('workos_daily_standups')
        .select('id')
        .eq('profile_id', profileId)
        .eq('standup_date', date)
        .maybeSingle();

    if (existing != null) {
      final data = await _client
          .from('workos_daily_standups')
          .update(standupData)
          .eq('id', existing['id'] as String)
          .select()
          .single();
      return Standup.fromJson(data);
    } else {
      final data = await _client
          .from('workos_daily_standups')
          .insert(standupData)
          .select()
          .single();
      return Standup.fromJson(data);
    }
  }

  /// Subscribe to live task changes so dashboard KPIs refresh automatically.
  RealtimeChannel subscribeToTaskChanges({required void Function() onChanged}) {
    final userId = _client.auth.currentUser?.id;
    return _client
        .channel('dash-tasks:$userId')
        .onPostgresChanges(
          event: PostgresChangeEvent.all,
          schema: 'public',
          table: 'workos_tasks',
          callback: (payload) => onChanged(),
        )
        .subscribe();
  }

  /// Subscribe to live stand-up changes so the team stand-up card refreshes.
  RealtimeChannel subscribeToStandupChanges({required void Function() onChanged}) {
    final userId = _client.auth.currentUser?.id;
    return _client
        .channel('dash-standups:$userId')
        .onPostgresChanges(
          event: PostgresChangeEvent.all,
          schema: 'public',
          table: 'workos_daily_standups',
          callback: (payload) => onChanged(),
        )
        .subscribe();
  }
}