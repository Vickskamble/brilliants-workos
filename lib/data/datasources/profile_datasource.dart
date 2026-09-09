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
      },
    );
  }
}
