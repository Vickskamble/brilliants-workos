import 'package:flutter/foundation.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../../domain/entities/task.dart';

class TaskDatasource {
  final SupabaseClient _client;

  TaskDatasource(this._client);

  /// Get today's tasks for the current user
  Future<List<Task>> getMyTasks({String? status}) async {
    final profileId = await _getProfileId();
    final today = DateTime.now().toIso8601String().split('T').first;

    var query = _client
        .from('workos_tasks')
        .select('*, assignee:workos_profiles!assigned_to(full_name, avatar_url)')
        .eq('assigned_to', profileId)
        .gte('due_date', today);

    if (status != null) {
      query = query.eq('status', status);
    }

    final data = await query.order('priority').order('due_date');
    return (data as List).map((e) => _parseTask(e)).toList();
  }

  /// Get all tasks assigned by the current user (manager view)
  Future<List<Task>> getAssignedTasks({String? status, String? assigneeId}) async {
    var query = _client
        .from('workos_tasks')
        .select('*, assignee:workos_profiles!assigned_to(full_name, avatar_url), assigner:workos_profiles!assigned_by(full_name)');

    if (status != null) {
      query = query.eq('status', status);
    }
    if (assigneeId != null) {
      query = query.eq('assigned_to', assigneeId);
    }

    final data = await query.order('created_at', ascending: false);
    return (data as List).map((e) => _parseTask(e)).toList();
  }

  /// Get overdue tasks
  Future<List<Task>> getOverdueTasks() async {
    final today = DateTime.now().toIso8601String().split('T').first;
    final data = await _client
        .from('workos_tasks')
        .select('*, assignee:workos_profiles!assigned_to(full_name, avatar_url)')
        .inFilter('status', ['TODO', 'IN_PROGRESS'])
        .lt('due_date', today)
        .order('due_date');

    return (data as List).map((e) => _parseTask(e)).toList();
  }

  /// Get a single task by ID
  Future<Task?> getTask(String taskId) async {
    final data = await _client
        .from('workos_tasks')
        .select('*, assignee:workos_profiles!assigned_to(full_name, avatar_url), assigner:workos_profiles!assigned_by(full_name)')
        .eq('id', taskId)
        .maybeSingle();

    if (data == null) return null;
    return _parseTask(data);
  }

  /// Create a new task
  Future<Task> createTask(Map<String, dynamic> taskData) async {
    final context = await _getMyContext();
    taskData['assigned_by'] = context.$1;
    taskData['company_id'] ??= context.$2;

    final data = await _client
        .from('workos_tasks')
        .insert(taskData)
        .select()
        .single();

    return Task.fromJson(data);
  }

  /// Update task
  Future<Task> updateTask(String taskId, Map<String, dynamic> updates) async {
    final data = await _client
        .from('workos_tasks')
        .update(updates)
        .eq('id', taskId)
        .select()
        .single();

    return Task.fromJson(data);
  }

  /// Update task status
  Future<Task> updateStatus(String taskId, String status, {
    String? result,
    String? comment,
    double? actualValue,
  }) async {
    final updates = <String, dynamic>{
      'status': status,
    };

    if (status == 'COMPLETED') {
      updates['completed_at'] = DateTime.now().toIso8601String();
      if (result != null) updates['result'] = result;
      if (comment != null) updates['comment'] = comment;
      if (actualValue != null) updates['actual_value'] = actualValue;
      // Roll the actual value up into the assignee's active targets via
      // a SECURITY DEFINER function (targets RLS is manager-only).
      if (actualValue != null) {
        try {
          await _client.rpc(
            'record_task_actual_value',
            params: {'p_task_id': taskId, 'p_actual_value': actualValue},
          );
        } catch (e) {
          // Target roll-up is best-effort; don't block completion.
          debugPrint('record_task_actual_value failed: $e');
        }
      }
    }

    return updateTask(taskId, updates);
  }

  /// Delete task
  Future<void> deleteTask(String taskId) async {
    await _client.from('workos_tasks').delete().eq('id', taskId);
  }

  /// Get tasks for a specific date
  Future<List<Task>> getTasksForDate(DateTime date) async {
    final dateStr = date.toIso8601String().split('T').first;
    final data = await _client
        .from('workos_tasks')
        .select('*, assignee:workos_profiles!assigned_to(full_name, avatar_url)')
        .eq('due_date', dateStr)
        .order('priority')
        .order('due_date');

    return (data as List).map((e) => _parseTask(e)).toList();
  }

  /// Get tasks for a team
  Future<List<Task>> getTeamTasks(String teamId) async {
    final data = await _client
        .from('workos_tasks')
        .select('*, assignee:workos_profiles!assigned_to(full_name, avatar_url)')
        .eq('team_id', teamId)
        .order('created_at', ascending: false);

    return (data as List).map((e) => _parseTask(e)).toList();
  }

  Future<String> _getProfileId() async {
    final userId = _client.auth.currentUser!.id;
    final data = await _client
        .from('workos_profiles')
        .select('id')
        .eq('user_id', userId)
        .single();
    return data['id'] as String;
  }

  Future<(String, String)> _getMyContext() async {
    final userId = _client.auth.currentUser!.id;
    final data = await _client
        .from('workos_profiles')
        .select('id, company_id')
        .eq('user_id', userId)
        .single();
    return (data['id'] as String, data['company_id'] as String);
  }

  Task _parseTask(Map<String, dynamic> data) {
    final assignee = data['assignee'] as Map<String, dynamic>?;
    final assigner = data['assigner'] as Map<String, dynamic>?;

    return Task.fromJson({
      ...data,
      'assignee_name': assignee?['full_name'],
      'assignee_avatar_url': assignee?['avatar_url'],
      'assigner_name': assigner?['full_name'],
    });
  }
}

