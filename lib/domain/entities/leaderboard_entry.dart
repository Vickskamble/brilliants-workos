class LeaderboardEntry {
  final String profileId;
  final String fullName;
  final String role;
  final String department;
  final double score;
  final String band;
  final double taskCompletion;
  final double targetAchievement;
  final double onTimeRate;
  final int completed;
  final int assigned;

  const LeaderboardEntry({
    required this.profileId,
    required this.fullName,
    required this.role,
    required this.department,
    required this.score,
    required this.band,
    required this.taskCompletion,
    required this.targetAchievement,
    required this.onTimeRate,
    required this.completed,
    required this.assigned,
  });

  factory LeaderboardEntry.fromJson(Map<String, dynamic> json) {
    return LeaderboardEntry(
      profileId: json['profile_id'] as String? ?? '',
      fullName: json['full_name'] as String? ?? '—',
      role: json['role'] as String? ?? 'MEMBER',
      department: json['department'] as String? ?? 'OTHER',
      score: (json['score'] as num?)?.toDouble() ?? 0,
      band: json['band'] as String? ?? 'AVERAGE',
      taskCompletion: (json['task_completion'] as num?)?.toDouble() ?? 0,
      targetAchievement: (json['target_achievement'] as num?)?.toDouble() ?? 0,
      onTimeRate: (json['on_time_rate'] as num?)?.toDouble() ?? 0,
      completed: (json['completed'] as num?)?.toInt() ?? 0,
      assigned: (json['assigned'] as num?)?.toInt() ?? 0,
    );
  }
}