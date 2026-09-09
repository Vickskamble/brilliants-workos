import 'dart:async';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:equatable/equatable.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../../../data/repositories/auth_repository.dart';
import '../../../domain/entities/profile.dart';

// Events
abstract class AuthEvent extends Equatable {
  @override
  List<Object?> get props => [];
}

class AuthStarted extends AuthEvent {}

class AuthSignedUp extends AuthEvent {
  final String email;
  final String password;
  final String fullName;
  AuthSignedUp({required this.email, required this.password, required this.fullName});
  @override
  List<Object?> get props => [email, password, fullName];
}

class AuthSignedIn extends AuthEvent {
  final String email;
  final String password;
  AuthSignedIn({required this.email, required this.password});
  @override
  List<Object?> get props => [email, password];
}

class AuthSignedOut extends AuthEvent {}

class AuthPasswordReset extends AuthEvent {
  final String email;
  AuthPasswordReset({required this.email});
  @override
  List<Object?> get props => [email];
}

class AuthCompanyCreated extends AuthEvent {
  final String name;
  final String slug;
  final String? industry;
  AuthCompanyCreated({required this.name, required this.slug, this.industry});
  @override
  List<Object?> get props => [name, slug, industry];
}

// States
abstract class AuthState extends Equatable {
  @override
  List<Object?> get props => [];
}

class AuthInitial extends AuthState {}

class AuthLoading extends AuthState {}

class Authenticated extends AuthState {
  final Profile profile;
  Authenticated(this.profile);
  @override
  List<Object?> get props => [profile.id];
}

class Unauthenticated extends AuthState {}

class AuthError extends AuthState {
  final String message;
  AuthError(this.message);
  @override
  List<Object?> get props => [message];
}

class AuthPasswordResetSent extends AuthState {
  final String email;
  AuthPasswordResetSent(this.email);
  @override
  List<Object?> get props => [email];
}

class AuthNeedsCompany extends AuthState {
  final User user;
  AuthNeedsCompany(this.user);
  @override
  List<Object?> get props => [user.id];
}

class AuthCompanyCreateError extends AuthState {
  final String message;
  AuthCompanyCreateError(this.message);
  @override
  List<Object?> get props => [message];
}

// BLoC
class AuthBloc extends Bloc<AuthEvent, AuthState> {
  final AuthRepository _repository;
  StreamSubscription<AuthState>? _authSubscription;

  AuthBloc({required AuthRepository repository})
      : _repository = repository,
        super(AuthInitial()) {
    on<AuthStarted>(_onStarted);
    on<AuthSignedUp>(_onSignUp);
    on<AuthSignedIn>(_onSignIn);
    on<AuthSignedOut>(_onSignOut);
    on<AuthPasswordReset>(_onPasswordReset);
    on<AuthCompanyCreated>(_onCompanyCreated);
  }

  Future<void> _onStarted(AuthStarted event, Emitter<AuthState> emit) async {
    emit(AuthLoading());
    try {
      final user = _repository.currentUser;
      if (user == null) {
        emit(Unauthenticated());
        return;
      }

      final profile = await _repository.getCurrentProfile();
      if (profile == null) {
        // User exists but no profile → needs to create/join company
        emit(AuthNeedsCompany(user));
      } else {
        emit(Authenticated(profile));
      }
    } catch (e) {
      emit(Unauthenticated());
    }
  }

  Future<void> _onSignUp(AuthSignedUp event, Emitter<AuthState> emit) async {
    emit(AuthLoading());
    try {
      await _repository.signUp(
        email: event.email,
        password: event.password,
        fullName: event.fullName,
      );

      // After signup, user needs to verify email or create company
      final profile = await _repository.getCurrentProfile();
      if (profile == null) {
        final user = _repository.currentUser;
        if (user != null) {
          emit(AuthNeedsCompany(user));
        } else {
          emit(Unauthenticated());
        }
      } else {
        emit(Authenticated(profile));
      }
    } on AuthException catch (e) {
      emit(AuthError(e.message));
    } catch (e) {
      emit(AuthError(e.toString()));
    }
  }

  Future<void> _onSignIn(AuthSignedIn event, Emitter<AuthState> emit) async {
    emit(AuthLoading());
    try {
      final profile = await _repository.signIn(
        email: event.email,
        password: event.password,
      );

      if (profile == null) {
        final user = _repository.currentUser;
        if (user != null) {
          emit(AuthNeedsCompany(user));
        } else {
          emit(Unauthenticated());
        }
      } else {
        emit(Authenticated(profile));
      }
    } on AuthException catch (e) {
      emit(AuthError(e.message));
    } catch (e) {
      emit(AuthError(e.toString()));
    }
  }

  Future<void> _onSignOut(AuthSignedOut event, Emitter<AuthState> emit) async {
    emit(AuthLoading());
    await _repository.signOut();
    emit(Unauthenticated());
  }

  Future<void> _onPasswordReset(AuthPasswordReset event, Emitter<AuthState> emit) async {
    emit(AuthLoading());
    try {
      await _repository.resetPassword(event.email);
      emit(AuthPasswordResetSent(event.email));
    } on AuthException catch (e) {
      emit(AuthError(e.message));
    } catch (e) {
      emit(AuthError(e.toString()));
    }
  }

  Future<void> _onCompanyCreated(AuthCompanyCreated event, Emitter<AuthState> emit) async {
    emit(AuthLoading());
    try {
      await _repository.createCompany(
        name: event.name,
        slug: event.slug,
        industry: event.industry,
      );

      final profile = await _repository.getCurrentProfile();
      if (profile != null) {
        emit(Authenticated(profile));
      } else {
        emit(AuthCompanyCreateError('Company was created but profile could not be loaded.'));
      }
    } on AuthException catch (e) {
      emit(AuthCompanyCreateError(e.message));
    } catch (e) {
      emit(AuthCompanyCreateError(e.toString()));
    }
  }

  @override
  Future<void> close() {
    _authSubscription?.cancel();
    return super.close();
  }
}
