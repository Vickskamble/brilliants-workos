class DashboardStats {
  final int totalTeam;
  final int totalTasks;
  final int completed;
  final int pending;
  final int overdue;
  final double targetAchievement;
  final double targetAchieved;
  final double targetTotal;

  const DashboardStats({
    this.totalTeam = 0,
    this.totalTasks = 0,
    this.completed = 0,
    this.pending = 0,
    this.overdue = 0,
    this.targetAchievement = 0,
    this.targetAchieved = 0,
    this.targetTotal = 0,
  });

  double get completionRate =>
      totalTasks > 0 ? (completed / totalTasks * 100) : 0;

  factory DashboardStats.fromJson(Map<String, dynamic> json) {
    return DashboardStats(
      totalTeam: (json['total_team'] as num?)?.toInt() ?? 0,
      totalTasks: (json['total_tasks'] as num?)?.toInt() ?? 0,
      completed: (json['completed'] as num?)?.toInt() ?? 0,
      pending: (json['pending'] as num?)?.toInt() ?? 0,
      overdue: (json['overdue'] as num?)?.toInt() ?? 0,
      targetAchievement: (json['target_achievement'] as num?)?.toDouble() ?? 0,
      targetAchieved: (json['target_achieved'] as num?)?.toDouble() ?? 0,
      targetTotal: (json['target_total'] as num?)?.toDouble() ?? 0,
    );
  }
}
