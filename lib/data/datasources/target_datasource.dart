import 'package:supabase_flutter/supabase_flutter.dart';
import '../../domain/entities/target.dart';

class TargetDatasource {
  final SupabaseClient _client;

  TargetDatasource(this._client);

  Future<List<Target>> getTargets({
    String? profileId,
    String? targetType,
    String? periodType,
  }) async {
    var query = _client
        .from('workos_targets')
        .select('*, profile:workos_profiles!profile_id(full_name)');

    if (profileId != null) {
      query = query.eq('profile_id', profileId);
    }
    if (targetType != null) {
      query = query.eq('target_type', targetType);
    }
    if (periodType != null) {
      query = query.eq('period_type', periodType);
    }

    final data = await query.order('period_start', ascending: false);
    return (data as List).map((e) {
      final m = e;
      final profile = m['profile'] as Map<String, dynamic>?;
      return Target.fromJson({
        ...m,
        'profile_name': profile?['full_name'],
      });
    }).toList();
  }

  Future<Target?> getTarget(String targetId) async {
    final data = await _client
        .from('workos_targets')
        .select()
        .eq('id', targetId)
        .maybeSingle();

    if (data == null) return null;
    return Target.fromJson(data);
  }

  Future<Target> createTarget(Map<String, dynamic> targetData) async {
    targetData['company_id'] ??= await _getCompanyId();
    final data = await _client
        .from('workos_targets')
        .insert(targetData)
        .select()
        .single();

    return Target.fromJson(data);
  }

  Future<String> _getCompanyId() async {
    final userId = _client.auth.currentUser!.id;
    final data = await _client
        .from('workos_profiles')
        .select('company_id')
        .eq('user_id', userId)
        .single();
    return data['company_id'] as String;
  }

  Future<Target> updateTarget(String targetId, Map<String, dynamic> updates) async {
    final data = await _client
        .from('workos_targets')
        .update(updates)
        .eq('id', targetId)
        .select()
        .single();

    return Target.fromJson(data);
  }

  Future<void> deleteTarget(String targetId) async {
    await _client.from('workos_targets').delete().eq('id', targetId);
  }

  /// Get active targets for a member in current period
  Future<List<Target>> getActiveTargets({String? profileId}) async {
    final today = DateTime.now().toIso8601String().split('T').first;
    var query = _client
        .from('workos_targets')
        .select()
        .lte('period_start', today)
        .gte('period_end', today);

    if (profileId != null) {
      query = query.eq('profile_id', profileId);
    }

    final data = await query;
    return (data as List).map((e) => Target.fromJson(e)).toList();
  }
}

