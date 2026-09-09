import 'activity_point.dart';
import 'leaderboard_entry.dart';

class DashboardStats {
  final String myProfileId;
  final String fullName;
  final String role;
  final String companyName;

  final int totalTeam;
  final int totalTeams;
  final int totalTasks;
  final int completed;
  final int inProgress;
  final int pending;
  final int overdue;
  final int allTodo;
  final int allInProgress;
  final int allCompleted;

  final double targetAchievement;
  final double targetAchieved;
  final double targetTotal;

  final List<ActivityPoint> weeklyActivity;
  final List<LeaderboardEntry> leaderboard;

  const DashboardStats({
    this.myProfileId = '',
    this.fullName = '',
    this.role = '',
    this.companyName = '',
    this.totalTeam = 0,
    this.totalTeams = 0,
    this.totalTasks = 0,
    this.completed = 0,
    this.inProgress = 0,
    this.pending = 0,
    this.overdue = 0,
    this.allTodo = 0,
    this.allInProgress = 0,
    this.allCompleted = 0,
    this.targetAchievement = 0,
    this.targetAchieved = 0,
    this.targetTotal = 0,
    this.weeklyActivity = const [],
    this.leaderboard = const [],
  });

  double get completionRate => totalTasks > 0 ? (completed / totalTasks * 100) : 0;

  factory DashboardStats.fromJson(Map<String, dynamic> json) {
    return DashboardStats(
      myProfileId: json['my_profile_id'] as String? ?? '',
      fullName: json['full_name'] as String? ?? '',
      role: json['role'] as String? ?? '',
      companyName: json['company_name'] as String? ?? '',
      totalTeam: (json['total_team'] as num?)?.toInt() ?? 0,
      totalTeams: (json['total_teams'] as num?)?.toInt() ?? 0,
      totalTasks: (json['total_tasks'] as num?)?.toInt() ?? 0,
      completed: (json['completed'] as num?)?.toInt() ?? 0,
      inProgress: (json['in_progress'] as num?)?.toInt() ?? 0,
      pending: (json['pending'] as num?)?.toInt() ?? 0,
      overdue: (json['overdue'] as num?)?.toInt() ?? 0,
      allTodo: (json['all_todo'] as num?)?.toInt() ?? 0,
      allInProgress: (json['all_in_progress'] as num?)?.toInt() ?? 0,
      allCompleted: (json['all_completed'] as num?)?.toInt() ?? 0,
      targetAchievement: (json['target_achievement'] as num?)?.toDouble() ?? 0,
      targetAchieved: (json['target_achieved'] as num?)?.toDouble() ?? 0,
      targetTotal: (json['target_total'] as num?)?.toDouble() ?? 0,
    );
  }
}