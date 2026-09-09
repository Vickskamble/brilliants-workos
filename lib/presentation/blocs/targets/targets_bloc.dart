import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:equatable/equatable.dart';
import '../../../data/repositories/target_repository.dart';
import '../../../domain/entities/target.dart';

// Events
abstract class TargetsEvent extends Equatable {
  @override
  List<Object?> get props => [];
}

class LoadTargets extends TargetsEvent {
  final String? profileId;
  final String? targetType;
  LoadTargets({this.profileId, this.targetType});
  @override
  List<Object?> get props => [profileId, targetType];
}

class CreateTargetEvent extends TargetsEvent {
  final Map<String, dynamic> targetData;
  CreateTargetEvent(this.targetData);
  @override
  List<Object?> get props => [targetData];
}

class UpdateTargetEvent extends TargetsEvent {
  final String targetId;
  final Map<String, dynamic> updates;
  UpdateTargetEvent(this.targetId, this.updates);
  @override
  List<Object?> get props => [targetId, updates];
}

class DeleteTargetEvent extends TargetsEvent {
  final String targetId;
  DeleteTargetEvent(this.targetId);
  @override
  List<Object?> get props => [targetId];
}

// States
abstract class TargetsState extends Equatable {
  @override
  List<Object?> get props => [];
}

class TargetsInitial extends TargetsState {}

class TargetsLoading extends TargetsState {}

class TargetsLoaded extends TargetsState {
  final List<Target> targets;
  TargetsLoaded(this.targets);
  @override
  List<Object?> get props => [targets.length];
}

class TargetCreated extends TargetsState {
  final Target target;
  TargetCreated(this.target);
  @override
  List<Object?> get props => [target.id];
}

class TargetsError extends TargetsState {
  final String message;
  TargetsError(this.message);
  @override
  List<Object?> get props => [message];
}

// BLoC
class TargetsBloc extends Bloc<TargetsEvent, TargetsState> {
  final TargetRepository _repository;

  TargetsBloc({required TargetRepository repository})
      : _repository = repository,
        super(TargetsInitial()) {
    on<LoadTargets>(_onLoad);
    on<CreateTargetEvent>(_onCreate);
    on<UpdateTargetEvent>(_onUpdate);
    on<DeleteTargetEvent>(_onDelete);
  }

  Future<void> _onLoad(LoadTargets event, Emitter<TargetsState> emit) async {
    emit(TargetsLoading());
    try {
      final targets = await _repository.getTargets(
        profileId: event.profileId,
        targetType: event.targetType,
      );
      emit(TargetsLoaded(targets));
    } catch (e) {
      emit(TargetsError(e.toString()));
    }
  }

  Future<void> _onCreate(CreateTargetEvent event, Emitter<TargetsState> emit) async {
    try {
      final target = await _repository.createTarget(event.targetData);
      emit(TargetCreated(target));
    } catch (e) {
      emit(TargetsError(e.toString()));
    }
  }

  Future<void> _onUpdate(UpdateTargetEvent event, Emitter<TargetsState> emit) async {
    try {
      await _repository.updateTarget(event.targetId, event.updates);
      add(LoadTargets());
    } catch (e) {
      emit(TargetsError(e.toString()));
    }
  }

  Future<void> _onDelete(DeleteTargetEvent event, Emitter<TargetsState> emit) async {
    try {
      await _repository.deleteTarget(event.targetId);
      add(LoadTargets());
    } catch (e) {
      emit(TargetsError(e.toString()));
    }
  }
}
