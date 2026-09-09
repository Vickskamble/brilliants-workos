import 'dart:async';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:equatable/equatable.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../../../data/repositories/dashboard_repository.dart';
import '../../../domain/entities/dashboard_stats.dart';
import '../../../domain/entities/notification.dart';

// Events
abstract class DashboardEvent extends Equatable {
  @override
  List<Object?> get props => [];
}

class LoadDashboard extends DashboardEvent {}

class LoadNotifications extends DashboardEvent {
  final bool unreadOnly;
  LoadNotifications({this.unreadOnly = false});
  @override
  List<Object?> get props => [unreadOnly];
}

class MarkNotificationRead extends DashboardEvent {
  final String notificationId;
  MarkNotificationRead(this.notificationId);
  @override
  List<Object?> get props => [notificationId];
}

class MarkAllNotificationsRead extends DashboardEvent {}

class NewNotificationReceived extends DashboardEvent {
  final AppNotification notification;
  NewNotificationReceived(this.notification);
  @override
  List<Object?> get props => [notification.id];
}

// States
abstract class DashboardState extends Equatable {
  @override
  List<Object?> get props => [];
}

class DashboardInitial extends DashboardState {}

class DashboardLoading extends DashboardState {}

class DashboardLoaded extends DashboardState {
  final DashboardStats stats;
  final int unreadCount;
  DashboardLoaded(this.stats, {this.unreadCount = 0});
  @override
  List<Object?> get props => [stats, unreadCount];
}

class NotificationsLoaded extends DashboardState {
  final List<AppNotification> notifications;
  final int unreadCount;
  NotificationsLoaded(this.notifications, {this.unreadCount = 0});
  @override
  List<Object?> get props => [notifications.length, unreadCount];
}

class DashboardError extends DashboardState {
  final String message;
  DashboardError(this.message);
  @override
  List<Object?> get props => [message];
}

// BLoC
class DashboardBloc extends Bloc<DashboardEvent, DashboardState> {
  final DashboardRepository _repository;
  RealtimeChannel? _notificationChannel;

  DashboardBloc({required DashboardRepository repository})
      : _repository = repository,
        super(DashboardInitial()) {
    on<LoadDashboard>(_onLoadDashboard);
    on<LoadNotifications>(_onLoadNotifications);
    on<MarkNotificationRead>(_onMarkRead);
    on<MarkAllNotificationsRead>(_onMarkAllRead);
    on<NewNotificationReceived>(_onNewNotification);
  }

  Future<void> _onLoadDashboard(LoadDashboard event, Emitter<DashboardState> emit) async {
    emit(DashboardLoading());
    try {
      final stats = await _repository.getDashboardStats();
      final unreadCount = await _repository.getUnreadCount();
      emit(DashboardLoaded(stats, unreadCount: unreadCount));
    } catch (e) {
      emit(DashboardError(e.toString()));
    }
  }

  Future<void> _onLoadNotifications(LoadNotifications event, Emitter<DashboardState> emit) async {
    try {
      final notifications = await _repository.getNotifications(unreadOnly: event.unreadOnly);
      final unreadCount = await _repository.getUnreadCount();
      emit(NotificationsLoaded(notifications, unreadCount: unreadCount));
    } catch (e) {
      emit(DashboardError(e.toString()));
    }
  }

  Future<void> _onMarkRead(MarkNotificationRead event, Emitter<DashboardState> emit) async {
    try {
      await _repository.markAsRead(event.notificationId);
      add(LoadNotifications());
    } catch (e) {
      emit(DashboardError(e.toString()));
    }
  }

  Future<void> _onMarkAllRead(MarkAllNotificationsRead event, Emitter<DashboardState> emit) async {
    try {
      await _repository.markAllAsRead();
      add(LoadNotifications());
    } catch (e) {
      emit(DashboardError(e.toString()));
    }
  }

  void _onNewNotification(NewNotificationReceived event, Emitter<DashboardState> emit) {
    if (state is DashboardLoaded) {
      final current = state as DashboardLoaded;
      emit(DashboardLoaded(current.stats, unreadCount: current.unreadCount + 1));
    }
  }

  void subscribeToNotifications() {
    _notificationChannel?.unsubscribe();
    _notificationChannel = _repository.subscribeToNotifications(
      onNotification: (notification) {
        add(NewNotificationReceived(notification));
      },
    );
  }

  @override
  Future<void> close() {
    _notificationChannel?.unsubscribe();
    return super.close();
  }
}
