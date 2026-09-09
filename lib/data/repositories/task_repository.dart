import 'package:supabase_flutter/supabase_flutter.dart';
import '../datasources/task_datasource.dart';
import '../../domain/entities/task.dart';

class TaskRepository {
  final TaskDatasource _datasource;

  TaskRepository(SupabaseClient client) : _datasource = TaskDatasource(client);

  Future<List<Task>> getMyTasks({String? status}) => _datasource.getMyTasks(status: status);
  Future<List<Task>> getAssignedTasks({String? status, String? assigneeId}) =>
      _datasource.getAssignedTasks(status: status, assigneeId: assigneeId);
  Future<List<Task>> getOverdueTasks() => _datasource.getOverdueTasks();
  Future<Task?> getTask(String taskId) => _datasource.getTask(taskId);
  Future<Task> createTask(Map<String, dynamic> data) => _datasource.createTask(data);
  Future<Task> updateTask(String id, Map<String, dynamic> data) => _datasource.updateTask(id, data);
  Future<Task> updateStatus(String id, String status, {String? result, String? comment, double? actualValue}) =>
      _datasource.updateStatus(id, status, result: result, comment: comment, actualValue: actualValue);
  Future<void> deleteTask(String id) => _datasource.deleteTask(id);
  Future<List<Task>> getTasksForDate(DateTime date) => _datasource.getTasksForDate(date);
  Future<List<Task>> getTeamTasks(String teamId) => _datasource.getTeamTasks(teamId);
  RealtimeChannel subscribeToTaskChanges({required void Function() onChanged}) =>
      _datasource.subscribeToTaskChanges(onChanged: onChanged);
}
