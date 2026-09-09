import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:equatable/equatable.dart';
import '../../../data/repositories/standup_repository.dart';
import '../../../domain/entities/standup.dart';
import '../../../domain/entities/team_standup.dart';

// Events
abstract class StandupEvent extends Equatable {
  @override
  List<Object?> get props => [];
}

class LoadMyStandup extends StandupEvent {}

class SaveMorningPlanEvent extends StandupEvent {
  final String? planTask1;
  final String? planTask2;
  final String? planTask3;
  SaveMorningPlanEvent({this.planTask1, this.planTask2, this.planTask3});
  @override
  List<Object?> get props => [planTask1, planTask2, planTask3];
}

class SaveEveningReportEvent extends StandupEvent {
  final String completedToday;
  final String? pendingToday;
  final String? blockers;
  SaveEveningReportEvent({required this.completedToday, this.pendingToday, this.blockers});
  @override
  List<Object?> get props => [completedToday, pendingToday, blockers];
}

class LoadCompanyStandups extends StandupEvent {}

// States
abstract class StandupState extends Equatable {
  @override
  List<Object?> get props => [];
}

class StandupInitial extends StandupState {}

class StandupLoading extends StandupState {}

class MyStandupLoaded extends StandupState {
  final Standup? standup;
  MyStandupLoaded(this.standup);
  @override
  List<Object?> get props => [standup?.id ?? '', standup?.standupDate ?? ''];
}

class StandupSaved extends StandupState {
  final Standup standup;
  StandupSaved(this.standup);
  @override
  List<Object?> get props => [standup.id];
}

class CompanyStandupsLoaded extends StandupState {
  final List<TeamStandup> standups;
  CompanyStandupsLoaded(this.standups);
  @override
  List<Object?> get props => [standups.length];
}

class StandupError extends StandupState {
  final String message;
  StandupError(this.message);
  @override
  List<Object?> get props => [message];
}

// BLoC
class StandupBloc extends Bloc<StandupEvent, StandupState> {
  final StandupRepository _repository;

  StandupBloc({required this._repository})
      : super(StandupInitial()) {
    on<LoadMyStandup>(_onLoadMyStandup);
    on<SaveMorningPlanEvent>(_onSaveMorningPlan);
    on<SaveEveningReportEvent>(_onSaveEveningReport);
    on<LoadCompanyStandups>(_onLoadCompanyStandups);
  }

  Future<void> _onLoadMyStandup(LoadMyStandup event, Emitter<StandupState> emit) async {
    emit(StandupLoading());
    try {
      final profileId = await _repository.getCurrentProfileId();
      final standup = await _repository.getTodayStandup(profileId);
      emit(MyStandupLoaded(standup));
    } catch (e) {
      emit(StandupError(e.toString()));
    }
  }

  Future<void> _onSaveMorningPlan(
      SaveMorningPlanEvent event, Emitter<StandupState> emit) async {
    try {
      final standup = await _repository.saveMorningPlan(
        planTask1: event.planTask1,
        planTask2: event.planTask2,
        planTask3: event.planTask3,
      );
      emit(StandupSaved(standup));
    } catch (e) {
      emit(StandupError(e.toString()));
    }
  }

  Future<void> _onSaveEveningReport(
      SaveEveningReportEvent event, Emitter<StandupState> emit) async {
    try {
      final standup = await _repository.saveEveningReport(
        completedToday: event.completedToday,
        pendingToday: event.pendingToday,
        blockers: event.blockers,
      );
      emit(StandupSaved(standup));
    } catch (e) {
      emit(StandupError(e.toString()));
    }
  }

  Future<void> _onLoadCompanyStandups(
      LoadCompanyStandups event, Emitter<StandupState> emit) async {
    emit(StandupLoading());
    try {
      final standups = await _repository.getCompanyTodayStandups();
      emit(CompanyStandupsLoaded(standups));
    } catch (e) {
      emit(StandupError(e.toString()));
    }
  }
}