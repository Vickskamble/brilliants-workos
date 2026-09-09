class Target {
  final String id;
  final String companyId;
  final String? profileId;
  final String? teamId;
  final String targetType;
  final String periodType;
  final DateTime periodStart;
  final DateTime periodEnd;
  final double targetValue;
  final double currentValue;
  final String currency;
  final DateTime createdAt;
  final DateTime updatedAt;

  // Joined fields
  final String? profileName;
  final String? teamName;

  const Target({
    required this.id,
    required this.companyId,
    this.profileId,
    this.teamId,
    required this.targetType,
    required this.periodType,
    required this.periodStart,
    required this.periodEnd,
    required this.targetValue,
    this.currentValue = 0,
    this.currency = 'INR',
    required this.createdAt,
    required this.updatedAt,
    this.profileName,
    this.teamName,
  });

  double get achievementPercentage =>
      targetValue > 0 ? (currentValue / targetValue * 100).clamp(0, 100) : 0;

  bool get isAchieved => currentValue >= targetValue;

  bool get isExpired => DateTime.now().isAfter(periodEnd);

  double get remaining => (targetValue - currentValue).clamp(0, targetValue);

  String get targetTypeLabel => switch (targetType) {
        'SALES' => 'Sales',
        'LEADS' => 'Leads',
        'CALLS' => 'Calls',
        'MEETINGS' => 'Meetings',
        'DEMOS' => 'Demos',
        'CONVERSIONS' => 'Conversions',
        'REVENUE' => 'Revenue',
        'POSTS' => 'Posts',
        'REELS' => 'Reels',
        'BLOGS' => 'Blogs',
        'BUGS_RESOLVED' => 'Bugs Resolved',
        'FEATURES' => 'Features',
        'TICKETS' => 'Tickets',
        'TASKS_COMPLETED' => 'Tasks Completed',
        'CUSTOM' => 'Custom',
        _ => targetType,
      };

  Target copyWith({
    double? currentValue,
    double? targetValue,
    String? targetType,
    String? periodType,
  }) {
    return Target(
      id: id,
      companyId: companyId,
      profileId: profileId,
      teamId: teamId,
      targetType: targetType ?? this.targetType,
      periodType: periodType ?? this.periodType,
      periodStart: periodStart,
      periodEnd: periodEnd,
      targetValue: targetValue ?? this.targetValue,
      currentValue: currentValue ?? this.currentValue,
      currency: currency,
      createdAt: createdAt,
      updatedAt: DateTime.now(),
      profileName: profileName,
      teamName: teamName,
    );
  }

  factory Target.fromJson(Map<String, dynamic> json) {
    return Target(
      id: json['id'] as String,
      companyId: json['company_id'] as String,
      profileId: json['profile_id'] as String?,
      teamId: json['team_id'] as String?,
      targetType: json['target_type'] as String,
      periodType: json['period_type'] as String,
      periodStart: DateTime.parse(json['period_start'] as String),
      periodEnd: DateTime.parse(json['period_end'] as String),
      targetValue: (json['target_value'] as num).toDouble(),
      currentValue: (json['current_value'] as num?)?.toDouble() ?? 0,
      currency: json['currency'] as String? ?? 'INR',
      createdAt: DateTime.parse(json['created_at'] as String),
      updatedAt: DateTime.parse(json['updated_at'] as String),
      profileName: json['profile_name'] as String?,
      teamName: json['team_name'] as String?,
    );
  }

  Map<String, dynamic> toJson() => {
        'company_id': companyId,
        'profile_id': profileId,
        'team_id': teamId,
        'target_type': targetType,
        'period_type': periodType,
        'period_start': periodStart.toIso8601String().split('T').first,
        'period_end': periodEnd.toIso8601String().split('T').first,
        'target_value': targetValue,
        'currency': currency,
      };
}
