import 'package:supabase_flutter/supabase_flutter.dart';
import '../../domain/entities/dashboard_stats.dart';
import '../../domain/entities/standup.dart';

class DashboardDatasource {
  final SupabaseClient _client;

  DashboardDatasource(this._client);

  Future<DashboardStats> getDashboardStats() async {
    final userId = _client.auth.currentUser?.id;
    if (userId == null) return const DashboardStats();

    // Get company_id
    final profile = await _client
        .from('workos_profiles')
        .select('company_id')
        .eq('user_id', userId)
        .maybeSingle();

    if (profile == null) return const DashboardStats();

    final companyId = profile['company_id'] as String;
    final today = DateTime.now().toIso8601String().split('T').first;

    // Team count
    final teamCount = await _client
        .from('workos_profiles')
        .select('id')
        .eq('company_id', companyId)
        .eq('is_active', true);

    // Today's tasks
    final todayTasks = await _client
        .from('workos_tasks')
        .select('id, status, due_date')
        .eq('company_id', companyId)
        .lte('due_date', today);

    final completed = todayTasks.where((t) => t['status'] == 'COMPLETED').length;
    final pending = todayTasks.where((t) =>
        t['status'] == 'TODO' || t['status'] == 'IN_PROGRESS').length;
    final overdue = todayTasks.where((t) =>
        (t['status'] == 'TODO' || t['status'] == 'IN_PROGRESS') &&
        t['due_date'] < today).length;

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

    return DashboardStats(
      totalTeam: teamCount.length,
      totalTasks: todayTasks.length,
      completed: completed,
      pending: pending,
      overdue: overdue,
      targetAchievement: double.parse(targetAchievement.toStringAsFixed(1)),
      targetAchieved: targetAchieved,
      targetTotal: targetTotal,
    );
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
}
