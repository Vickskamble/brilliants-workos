/// Lightweight per-member stand-up status shown to managers on the dashboard.
class TeamStandup {
  final String profileId;
  final String fullName;
  final bool hasPlan;
  final bool hasReport;
  final String status;

  const TeamStandup({
    required this.profileId,
    required this.fullName,
    required this.hasPlan,
    required this.hasReport,
    required this.status,
  });

  factory TeamStandup.fromProfileAndStandup({
    required String profileId,
    required String fullName,
    Map<String, dynamic>? standup,
  }) {
    final s = standup;
    final hasPlan = s != null &&
        (((s['plan_task_1'] as String?)?.isNotEmpty ?? false) ||
            ((s['plan_task_2'] as String?)?.isNotEmpty ?? false) ||
            ((s['plan_task_3'] as String?)?.isNotEmpty ?? false));
    final hasReport = s != null &&
        (((s['completed_today'] as String?)?.isNotEmpty ?? false) ||
            ((s['pending_today'] as String?)?.isNotEmpty ?? false));
    return TeamStandup(
      profileId: profileId,
      fullName: fullName,
      hasPlan: hasPlan,
      hasReport: hasReport,
      status: s?['status'] as String? ?? 'NONE',
    );
  }
}