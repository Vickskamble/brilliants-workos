import 'package:supabase_flutter/supabase_flutter.dart';
import '../../domain/entities/profile.dart';

class ProfileDatasource {
  final SupabaseClient _client;

  ProfileDatasource(this._client);

  Future<Profile?> getCurrentProfile() async {
    final userId = _client.auth.currentUser?.id;
    if (userId == null) return null;

    final data = await _client
        .from('workos_profiles')
        .select()
        .eq('user_id', userId)
        .maybeSingle();

    if (data == null) return null;
    return Profile.fromJson(data);
  }

  Future<Profile?> getProfileById(String profileId) async {
    final data = await _client
        .from('workos_profiles')
        .select()
        .eq('id', profileId)
        .maybeSingle();

    if (data == null) return null;
    return Profile.fromJson(data);
  }

  Future<List<Profile>> getCompanyMembers() async {
    final data = await _client
        .from('workos_profiles')
        .select()
        .order('full_name');

    return (data as List).map((e) => Profile.fromJson(e)).toList();
  }

  Future<List<Profile>> getActiveMembers() async {
    final data = await _client
        .from('workos_profiles')
        .select()
        .eq('is_active', true)
        .order('full_name');

    return (data as List).map((e) => Profile.fromJson(e)).toList();
  }

  Future<Profile> createProfile({
    required String userId,
    required String companyId,
    required String fullName,
    String role = 'MEMBER',
    String department = 'OTHER',
    String? phone,
  }) async {
    final data = await _client
        .from('workos_profiles')
        .insert({
          'user_id': userId,
          'company_id': companyId,
          'full_name': fullName,
          'role': role,
          'department': department,
          'phone': phone,
        })
        .select()
        .single();

    return Profile.fromJson(data);
  }

  Future<Profile> updateProfile(String profileId, Map<String, dynamic> updates) async {
    final data = await _client
        .from('workos_profiles')
        .update(updates)
        .eq('id', profileId)
        .select()
        .single();

    return Profile.fromJson(data);
  }

  Future<void> deactivateProfile(String profileId) async {
    await _client
        .from('workos_profiles')
        .update({'is_active': false})
        .eq('id', profileId);
  }

  Future<void> createCompany({
    required String name,
    required String slug,
    String? industry,
  }) async {
    // SECURITY DEFINER RPC — creates company + owner profile in one
    // atomic transaction, bypassing RLS so a fresh user can bootstrap.
    await _client.rpc(
      'create_workos_company',
      params: {
        'p_name': name,
        'p_slug': slug,
        'p_industry': industry,
        'p_full_name': _client.auth.currentUser?.userMetadata?['full_name'],
      },
    );
  }

  /// Invite a member by email. Returns a status map from the RPC:
  /// 'ADDED' | 'ALREADY_MEMBER' | 'INVITED' | 'IN_OTHER_COMPANY'.
  Future<Map<String, dynamic>> inviteMember({
    required String email,
    required String fullName,
    String role = 'MEMBER',
    String department = 'OTHER',
  }) async {
    final result = await _client.rpc(
      'invite_workos_member',
      params: {
        'p_email': email,
        'p_full_name': fullName,
        'p_role': role,
        'p_department': department,
      },
    );
    return Map<String, dynamic>.from(result as Map);
  }

  /// Called right after signup: attaches the user to the company that
  /// invited them (if a PENDING invite exists for their email).
  Future<Map<String, dynamic>> acceptInvite(String email) async {
    final result = await _client.rpc(
      'accept_workos_invite',
      params: {'p_email': email},
    );
    return Map<String, dynamic>.from(result as Map);
  }

  /// Performance breakdown for a member over a date range.
  /// Returns keys: task_completion, target_achievement, on_time_rate,
  /// overall, band, assigned, completed, completed_on_time,
  /// target_total, target_achieved.
  Future<Map<String, dynamic>> getPerformanceScore(
    String profileId, {
    DateTime? start,
    DateTime? end,
  }) async {
    final s = start ?? DateTime.now().copyWith(day: 1);
    final e = end ?? DateTime(DateTime.now().year, DateTime.now().month + 1, 0);
    final result = await _client.rpc(
      'get_performance_score',
      params: {
        'p_profile_id': profileId,
        'p_start_date': s.toIso8601String().split('T').first,
        'p_end_date': e.toIso8601String().split('T').first,
      },
    );
    return Map<String, dynamic>.from(result as Map);
  }
}
