import 'package:supabase_flutter/supabase_flutter.dart';
import '../datasources/team_datasource.dart';
import '../datasources/profile_datasource.dart';
import '../../domain/entities/team.dart';
import '../../domain/entities/profile.dart';

class TeamRepository {
  final TeamDatasource _teamDatasource;
  final ProfileDatasource _profileDatasource;

  TeamRepository(SupabaseClient client)
      : _teamDatasource = TeamDatasource(client),
        _profileDatasource = ProfileDatasource(client);

  Future<List<Team>> getTeams() => _teamDatasource.getTeams();
  Future<Team?> getTeam(String id) => _teamDatasource.getTeam(id);
  Future<Team> createTeam({required String name, String? description, String? managerId}) =>
      _teamDatasource.createTeam(name: name, description: description, managerId: managerId);
  Future<Team> updateTeam(String id, Map<String, dynamic> data) => _teamDatasource.updateTeam(id, data);
  Future<void> deleteTeam(String id) => _teamDatasource.deleteTeam(id);
  Future<void> addMember(String teamId, String profileId) => _teamDatasource.addMember(teamId, profileId);
  Future<void> removeMember(String teamId, String profileId) => _teamDatasource.removeMember(teamId, profileId);
  Future<List<Profile>> getTeamMembers(String teamId) => _teamDatasource.getTeamMembers(teamId);
  Future<List<Profile>> getAvailableMembers() => _teamDatasource.getAvailableMembers();

  // Company members
  Future<List<Profile>> getCompanyMembers() => _profileDatasource.getCompanyMembers();
  Future<List<Profile>> getActiveMembers() => _profileDatasource.getActiveMembers();
  Future<Profile?> getProfileById(String id) => _profileDatasource.getProfileById(id);
  Future<Profile> updateProfile(String id, Map<String, dynamic> data) => _profileDatasource.updateProfile(id, data);
  Future<void> deactivateProfile(String id) => _profileDatasource.deactivateProfile(id);
  Future<Map<String, dynamic>> inviteMember({
    required String email,
    required String fullName,
    String role = 'MEMBER',
    String department = 'OTHER',
  }) =>
      _profileDatasource.inviteMember(
        email: email,
        fullName: fullName,
        role: role,
        department: department,
      );

  Future<Map<String, dynamic>> getPerformanceScore(String profileId) =>
      _profileDatasource.getPerformanceScore(profileId);
}
