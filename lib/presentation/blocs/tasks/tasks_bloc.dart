import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:equatable/equatable.dart';
import '../../../data/repositories/task_repository.dart';
import '../../../domain/entities/task.dart';

// Events
abstract class TasksEvent extends Equatable {
  @override
  List<Object?> get props => [];
}

class LoadMyTasks extends TasksEvent {
  final String? status;
  LoadMyTasks({this.status});
  @override
  List<Object?> get props => [status];
}

class LoadAssignedTasks extends TasksEvent {
  final String? status;
  final String? assigneeId;
  LoadAssignedTasks({this.status, this.assigneeId});
  @override
  List<Object?> get props => [status, assigneeId];
}

class LoadOverdueTasks extends TasksEvent {}

class LoadTaskDetail extends TasksEvent {
  final String taskId;
  LoadTaskDetail(this.taskId);
  @override
  List<Object?> get props => [taskId];
}

class CreateTask extends TasksEvent {
  final Map<String, dynamic> taskData;
  CreateTask(this.taskData);
  @override
  List<Object?> get props => [taskData];
}

class UpdateTaskStatus extends TasksEvent {
  final String taskId;
  final String status;
  final String? result;
  final String? comment;
  final double? actualValue;
  UpdateTaskStatus(this.taskId, this.status, {this.result, this.comment, this.actualValue});
  @override
  List<Object?> get props => [taskId, status, result, comment, actualValue];
}

class DeleteTask extends TasksEvent {
  final String taskId;
  DeleteTask(this.taskId);
  @override
  List<Object?> get props => [taskId];
}

// States
abstract class TasksState extends Equatable {
  @override
  List<Object?> get props => [];
}

class TasksInitial extends TasksState {}

class TasksLoading extends TasksState {}

class MyTasksLoaded extends TasksState {
  final List<Task> tasks;
  final int completedCount;
  final int pendingCount;
  final int overdueCount;
  MyTasksLoaded(this.tasks, {this.completedCount = 0, this.pendingCount = 0, this.overdueCount = 0});
  @override
  List<Object?> get props => [tasks.length, completedCount, pendingCount];
}

class AssignedTasksLoaded extends TasksState {
  final List<Task> tasks;
  AssignedTasksLoaded(this.tasks);
  @override
  List<Object?> get props => [tasks.length];
}

class OverdueTasksLoaded extends TasksState {
  final List<Task> tasks;
  OverdueTasksLoaded(this.tasks);
  @override
  List<Object?> get props => [tasks.length];
}

class TaskDetailLoaded extends TasksState {
  final Task task;
  TaskDetailLoaded(this.task);
  @override
  List<Object?> get props => [task.id];
}

class TaskCreated extends TasksState {
  final Task task;
  TaskCreated(this.task);
  @override
  List<Object?> get props => [task.id];
}

class TaskUpdated extends TasksState {
  final Task task;
  TaskUpdated(this.task);
  @override
  List<Object?> get props => [task.id];
}

class TaskDeleted extends TasksState {}

class TasksError extends TasksState {
  final String message;
  TasksError(this.message);
  @override
  List<Object?> get props => [message];
}

// BLoC
class TasksBloc extends Bloc<TasksEvent, TasksState> {
  final TaskRepository _repository;

  TasksBloc({required this._repository})
      : super(TasksInitial()) {
    on<LoadMyTasks>(_onLoadMyTasks);
    on<LoadAssignedTasks>(_onLoadAssignedTasks);
    on<LoadOverdueTasks>(_onLoadOverdueTasks);
    on<LoadTaskDetail>(_onLoadTaskDetail);
    on<CreateTask>(_onCreateTask);
    on<UpdateTaskStatus>(_onUpdateStatus);
    on<DeleteTask>(_onDeleteTask);
  }

  Future<void> _onLoadMyTasks(LoadMyTasks event, Emitter<TasksState> emit) async {
    emit(TasksLoading());
    try {
      final tasks = await _repository.getMyTasks(status: event.status);
      final completed = tasks.where((t) => t.isCompleted).length;
      final pending = tasks.where((t) => t.isTodo || t.isInProgress).length;
      final overdue = tasks.where((t) => t.isOverdue).length;
      emit(MyTasksLoaded(tasks, completedCount: completed, pendingCount: pending, overdueCount: overdue));
    } catch (e) {
      emit(TasksError(e.toString()));
    }
  }

  Future<void> _onLoadAssignedTasks(LoadAssignedTasks event, Emitter<TasksState> emit) async {
    emit(TasksLoading());
    try {
      final tasks = await _repository.getAssignedTasks(
        status: event.status,
        assigneeId: event.assigneeId,
      );
      emit(AssignedTasksLoaded(tasks));
    } catch (e) {
      emit(TasksError(e.toString()));
    }
  }

  Future<void> _onLoadOverdueTasks(LoadOverdueTasks event, Emitter<TasksState> emit) async {
    emit(TasksLoading());
    try {
      final tasks = await _repository.getOverdueTasks();
      emit(OverdueTasksLoaded(tasks));
    } catch (e) {
      emit(TasksError(e.toString()));
    }
  }

  Future<void> _onLoadTaskDetail(LoadTaskDetail event, Emitter<TasksState> emit) async {
    emit(TasksLoading());
    try {
      final task = await _repository.getTask(event.taskId);
      if (task != null) {
        emit(TaskDetailLoaded(task));
      } else {
        emit(TasksError('Task not found'));
      }
    } catch (e) {
      emit(TasksError(e.toString()));
    }
  }

  Future<void> _onCreateTask(CreateTask event, Emitter<TasksState> emit) async {
    try {
      final task = await _repository.createTask(event.taskData);
      emit(TaskCreated(task));
    } catch (e) {
      emit(TasksError(e.toString()));
    }
  }

  Future<void> _onUpdateStatus(UpdateTaskStatus event, Emitter<TasksState> emit) async {
    try {
      final task = await _repository.updateStatus(
        event.taskId,
        event.status,
        result: event.result,
        comment: event.comment,
        actualValue: event.actualValue,
      );
      emit(TaskUpdated(task));
    } catch (e) {
      emit(TasksError(e.toString()));
    }
  }

  Future<void> _onDeleteTask(DeleteTask event, Emitter<TasksState> emit) async {
    try {
      await _repository.deleteTask(event.taskId);
      emit(TaskDeleted());
    } catch (e) {
      emit(TasksError(e.toString()));
    }
  }
}
