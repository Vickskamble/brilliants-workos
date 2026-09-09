import 'package:supabase_flutter/supabase_flutter.dart';
import '../../domain/entities/team.dart';
import '../../domain/entities/profile.dart';

class TeamDatasource {
  final SupabaseClient _client;

  TeamDatasource(this._client);

  Future<List<Team>> getTeams() async {
    final data = await _client
        .from('workos_teams')
        .select('*, member_count:workos_team_members(count)')
        .order('name');

    return (data as List).map((e) {
      final memberCount = (e['member_count'] as List?)?.firstOrNull?['count'] ?? 0;
      return Team.fromJson({...e, 'member_count': memberCount});
    }).toList();
  }

  Future<Team?> getTeam(String teamId) async {
    final data = await _client
        .from('workos_teams')
        .select()
        .eq('id', teamId)
        .maybeSingle();

    if (data == null) return null;
    return Team.fromJson(data);
  }

  Future<Team> createTeam({
    required String name,
    String? description,
    String? managerId,
  }) async {
    final data = await _client
        .from('workos_teams')
        .insert({
          'name': name,
          'description': description,
          'manager_id': managerId,
        })
        .select()
        .single();

    return Team.fromJson(data);
  }

  Future<Team> updateTeam(String teamId, Map<String, dynamic> updates) async {
    final data = await _client
        .from('workos_teams')
        .update(updates)
        .eq('id', teamId)
        .select()
        .single();

    return Team.fromJson(data);
  }

  Future<void> deleteTeam(String teamId) async {
    await _client.from('workos_teams').delete().eq('id', teamId);
  }

  Future<void> addMember(String teamId, String profileId) async {
    await _client.from('workos_team_members').insert({
      'team_id': teamId,
      'profile_id': profileId,
    });
  }

  Future<void> removeMember(String teamId, String profileId) async {
    await _client
        .from('workos_team_members')
        .delete()
        .eq('team_id', teamId)
        .eq('profile_id', profileId);
  }

  Future<List<Profile>> getTeamMembers(String teamId) async {
    final data = await _client
        .from('workos_team_members')
        .select('profile:workos_profiles(*)')
        .eq('team_id', teamId);

    return (data as List)
        .map((e) => Profile.fromJson(e['profile'] as Map<String, dynamic>))
        .toList();
  }

  Future<List<Profile>> getAvailableMembers() async {
    // Members not yet in any team
    final allMembers = await _client
        .from('workos_profiles')
        .select()
        .eq('is_active', true)
        .order('full_name');

    final teamMembers = await _client
        .from('workos_team_members')
        .select('profile_id');

    final teamMemberIds = (teamMembers as List)
        .map((e) => e['profile_id'] as String)
        .toSet();

    return (allMembers as List)
        .map((e) => Profile.fromJson(e))
        .where((p) => !teamMemberIds.contains(p.id))
        .toList();
  }
}
