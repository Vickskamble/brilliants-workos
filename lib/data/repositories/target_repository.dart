import 'package:supabase_flutter/supabase_flutter.dart';
import '../datasources/target_datasource.dart';
import '../../domain/entities/target.dart';

class TargetRepository {
  final TargetDatasource _datasource;

  TargetRepository(SupabaseClient client) : _datasource = TargetDatasource(client);

  Future<List<Target>> getTargets({String? profileId, String? targetType, String? periodType}) =>
      _datasource.getTargets(profileId: profileId, targetType: targetType, periodType: periodType);
  Future<Target?> getTarget(String id) => _datasource.getTarget(id);
  Future<Target> createTarget(Map<String, dynamic> data) => _datasource.createTarget(data);
  Future<Target> updateTarget(String id, Map<String, dynamic> data) => _datasource.updateTarget(id, data);
  Future<void> deleteTarget(String id) => _datasource.deleteTarget(id);
  Future<List<Target>> getActiveTargets({String? profileId}) => _datasource.getActiveTargets(profileId: profileId);
}
