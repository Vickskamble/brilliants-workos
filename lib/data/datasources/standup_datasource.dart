import 'package:supabase_flutter/supabase_flutter.dart';
import '../../domain/entities/standup.dart';
import '../../domain/entities/team_standup.dart';

class StandupDatasource {
  final SupabaseClient _client;

  StandupDatasource(this._client);

  String get _today => DateTime.now().toIso8601String().split('T').first;

  Future<String?> _getCompanyId() async {
    final userId = _client.auth.currentUser?.id;
    if (userId == null) return null;
    final data = await _client
        .from('workos_profiles')
        .select('company_id')
        .eq('user_id', userId)
        .maybeSingle();
    return data?['company_id'] as String?;
  }

  Future<String?> getCurrentProfileId() async {
    final userId = _client.auth.currentUser?.id;
    if (userId == null) return null;
    final data = await _client
        .from('workos_profiles')
        .select('id')
        .eq('user_id', userId)
        .maybeSingle();
    return data?['id'] as String?;
  }

  Future<Standup?> getTodayStandup(String profileId) async {
    final data = await _client
        .from('workos_daily_standups')
        .select()
        .eq('profile_id', profileId)
        .eq('standup_date', _today)
        .maybeSingle();

    if (data == null) return null;
    return Standup.fromJson(data);
  }

  /// Create or update today's standup for the current user.
  Future<Standup> saveStandup({
    required Map<String, dynamic> fields,
    required String status,
  }) async {
    final profileId = await getCurrentProfileId();
    final companyId = await _getCompanyId();
    if (profileId == null || companyId == null) {
      throw Exception('No profile or company found');
    }

    final existing = await _client
        .from('workos_daily_standups')
        .select('id')
        .eq('profile_id', profileId)
        .eq('standup_date', _today)
        .maybeSingle();

    final payload = <String, dynamic>{
      'company_id': companyId,
      'profile_id': profileId,
      'standup_date': _today,
      ...fields,
      'status': status,
    };

    if (existing != null) {
      final data = await _client
          .from('workos_daily_standups')
          .update(payload)
          .eq('id', existing['id'] as String)
          .select()
          .single();
      return Standup.fromJson(data);
    }

    final data = await _client
        .from('workos_daily_standups')
        .insert(payload)
        .select()
        .single();
    return Standup.fromJson(data);
  }

  /// Today's standup status for every active member.
  /// RLS restricts members to their own rows; owners/admins see everyone.
  Future<List<TeamStandup>> getCompanyTodayStandups() async {
    final companyId = await _getCompanyId();
    if (companyId == null) return const [];

    final profiles = await _client
        .from('workos_profiles')
        .select('id, full_name')
        .eq('company_id', companyId)
        .eq('is_active', true);

    final standups = await _client
        .from('workos_daily_standups')
        .select()
        .eq('company_id', companyId)
        .eq('standup_date', _today);

    final standupById = <String, Map<String, dynamic>>{
      for (final s in standups) s['profile_id'] as String: s,
    };

    return (profiles as List).map((p) {
      return TeamStandup.fromProfileAndStandup(
        profileId: p['id'] as String,
        fullName: p['full_name'] as String? ?? 'Unknown',
        standup: standupById[p['id'] as String],
      );
    }).toList();
  }
}