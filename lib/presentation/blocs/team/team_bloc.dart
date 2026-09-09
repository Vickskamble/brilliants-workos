import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:equatable/equatable.dart';
import '../../../data/repositories/team_repository.dart';
import '../../../domain/entities/profile.dart';
import '../../../domain/entities/team.dart';

// Events
abstract class TeamEvent extends Equatable {
  @override
  List<Object?> get props => [];
}

class LoadTeamData extends TeamEvent {}

class LoadCompanyMembers extends TeamEvent {}

class CreateTeamEvent extends TeamEvent {
  final String name;
  final String? description;
  CreateTeamEvent({required this.name, this.description});
  @override
  List<Object?> get props => [name, description];
}

class AddTeamMember extends TeamEvent {
  final String teamId;
  final String profileId;
  AddTeamMember(this.teamId, this.profileId);
  @override
  List<Object?> get props => [teamId, profileId];
}

class RemoveTeamMember extends TeamEvent {
  final String teamId;
  final String profileId;
  RemoveTeamMember(this.teamId, this.profileId);
  @override
  List<Object?> get props => [teamId, profileId];
}

class LoadMemberDetail extends TeamEvent {
  final String profileId;
  LoadMemberDetail(this.profileId);
  @override
  List<Object?> get props => [profileId];
}

// States
abstract class TeamState extends Equatable {
  @override
  List<Object?> get props => [];
}

class TeamInitial extends TeamState {}

class TeamLoading extends TeamState {}

class TeamDataLoaded extends TeamState {
  final List<Team> teams;
  final List<Profile> members;
  TeamDataLoaded(this.teams, this.members);
  @override
  List<Object?> get props => [teams.length, members.length];
}

class CompanyMembersLoaded extends TeamState {
  final List<Profile> members;
  CompanyMembersLoaded(this.members);
  @override
  List<Object?> get props => [members.length];
}

class MemberDetailLoaded extends TeamState {
  final Profile member;
  MemberDetailLoaded(this.member);
  @override
  List<Object?> get props => [member.id];
}

class TeamError extends TeamState {
  final String message;
  TeamError(this.message);
  @override
  List<Object?> get props => [message];
}

// BLoC
class TeamBloc extends Bloc<TeamEvent, TeamState> {
  final TeamRepository _repository;

  TeamBloc({required TeamRepository repository})
      : _repository = repository,
        super(TeamInitial()) {
    on<LoadTeamData>(_onLoadTeamData);
    on<LoadCompanyMembers>(_onLoadCompanyMembers);
    on<CreateTeamEvent>(_onCreateTeam);
    on<AddTeamMember>(_onAddMember);
    on<RemoveTeamMember>(_onRemoveMember);
    on<LoadMemberDetail>(_onLoadMemberDetail);
  }

  Future<void> _onLoadTeamData(LoadTeamData event, Emitter<TeamState> emit) async {
    emit(TeamLoading());
    try {
      final teams = await _repository.getTeams();
      final members = await _repository.getActiveMembers();
      emit(TeamDataLoaded(teams, members));
    } catch (e) {
      emit(TeamError(e.toString()));
    }
  }

  Future<void> _onLoadCompanyMembers(LoadCompanyMembers event, Emitter<TeamState> emit) async {
    emit(TeamLoading());
    try {
      final members = await _repository.getCompanyMembers();
      emit(CompanyMembersLoaded(members));
    } catch (e) {
      emit(TeamError(e.toString()));
    }
  }

  Future<void> _onCreateTeam(CreateTeamEvent event, Emitter<TeamState> emit) async {
    try {
      await _repository.createTeam(name: event.name, description: event.description);
      add(LoadTeamData());
    } catch (e) {
      emit(TeamError(e.toString()));
    }
  }

  Future<void> _onAddMember(AddTeamMember event, Emitter<TeamState> emit) async {
    try {
      await _repository.addMember(event.teamId, event.profileId);
      add(LoadTeamData());
    } catch (e) {
      emit(TeamError(e.toString()));
    }
  }

  Future<void> _onRemoveMember(RemoveTeamMember event, Emitter<TeamState> emit) async {
    try {
      await _repository.removeMember(event.teamId, event.profileId);
      add(LoadTeamData());
    } catch (e) {
      emit(TeamError(e.toString()));
    }
  }

  Future<void> _onLoadMemberDetail(LoadMemberDetail event, Emitter<TeamState> emit) async {
    emit(TeamLoading());
    try {
      final member = await _repository.getProfileById(event.profileId);
      if (member != null) {
        emit(MemberDetailLoaded(member));
      } else {
        emit(TeamError('Member not found'));
      }
    } catch (e) {
      emit(TeamError(e.toString()));
    }
  }
}
