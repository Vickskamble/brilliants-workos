import 'package:supabase_flutter/supabase_flutter.dart';
import '../datasources/standup_datasource.dart';
import '../../domain/entities/standup.dart';
import '../../domain/entities/team_standup.dart';

class StandupRepository {
  final StandupDatasource _datasource;

  StandupRepository(SupabaseClient client) : _datasource = StandupDatasource(client);

  Future<String> getCurrentProfileId() async {
    final id = await _datasource.getCurrentProfileId();
    if (id == null) throw Exception('No profile found for current user');
    return id;
  }

  Future<Standup?> getTodayStandup(String profileId) =>
      _datasource.getTodayStandup(profileId);

  Future<Standup> saveMorningPlan({
    String? planTask1,
    String? planTask2,
    String? planTask3,
  }) =>
      _datasource.saveStandup(
        fields: {
          if (planTask1 != null && planTask1.isNotEmpty) 'plan_task_1': planTask1.trim(),
          if (planTask2 != null && planTask2.isNotEmpty) 'plan_task_2': planTask2.trim(),
          if (planTask3 != null && planTask3.isNotEmpty) 'plan_task_3': planTask3.trim(),
        },
        status: 'SUBMITTED',
      );

  Future<Standup> saveEveningReport({
    required String completedToday,
    String? pendingToday,
    String? blockers,
  }) =>
      _datasource.saveStandup(
        fields: {
          'completed_today': completedToday.trim(),
          if (pendingToday != null && pendingToday.isNotEmpty) 'pending_today': pendingToday.trim(),
          if (blockers != null && blockers.isNotEmpty) 'blockers': blockers.trim(),
        },
        status: 'SUBMITTED',
      );

  Future<List<TeamStandup>> getCompanyTodayStandups() =>
      _datasource.getCompanyTodayStandups();
}