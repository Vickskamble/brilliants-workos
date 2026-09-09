class Standup {
  final String id;
  final String companyId;
  final String profileId;
  final DateTime standupDate;
  final String? planTask1;
  final String? planTask2;
  final String? planTask3;
  final String? completedToday;
  final String? pendingToday;
  final String? blockers;
  final String status;
  final String? reviewedBy;
  final DateTime? reviewedAt;
  final DateTime createdAt;

  const Standup({
    required this.id,
    required this.companyId,
    required this.profileId,
    required this.standupDate,
    this.planTask1,
    this.planTask2,
    this.planTask3,
    this.completedToday,
    this.pendingToday,
    this.blockers,
    this.status = 'DRAFT',
    this.reviewedBy,
    this.reviewedAt,
    required this.createdAt,
  });

  bool get hasPlan => planTask1 != null && planTask1!.isNotEmpty;
  bool get hasReport => completedToday != null && completedToday!.isNotEmpty;
  bool get hasBlockers => blockers != null && blockers!.isNotEmpty;
  bool get isSubmitted => status == 'SUBMITTED';
  bool get isReviewed => status == 'REVIEWED';

  List<String> get plannedTasks =>
      [planTask1, planTask2, planTask3].where((t) => t != null && t.isNotEmpty).cast<String>().toList();

  Standup copyWith({
    String? planTask1,
    String? planTask2,
    String? planTask3,
    String? completedToday,
    String? pendingToday,
    String? blockers,
    String? status,
  }) {
    return Standup(
      id: id,
      companyId: companyId,
      profileId: profileId,
      standupDate: standupDate,
      planTask1: planTask1 ?? this.planTask1,
      planTask2: planTask2 ?? this.planTask2,
      planTask3: planTask3 ?? this.planTask3,
      completedToday: completedToday ?? this.completedToday,
      pendingToday: pendingToday ?? this.pendingToday,
      blockers: blockers ?? this.blockers,
      status: status ?? this.status,
      reviewedBy: reviewedBy,
      reviewedAt: reviewedAt,
      createdAt: createdAt,
    );
  }

  factory Standup.fromJson(Map<String, dynamic> json) {
    return Standup(
      id: json['id'] as String,
      companyId: json['company_id'] as String,
      profileId: json['profile_id'] as String,
      standupDate: DateTime.parse(json['standup_date'] as String),
      planTask1: json['plan_task_1'] as String?,
      planTask2: json['plan_task_2'] as String?,
      planTask3: json['plan_task_3'] as String?,
      completedToday: json['completed_today'] as String?,
      pendingToday: json['pending_today'] as String?,
      blockers: json['blockers'] as String?,
      status: json['status'] as String? ?? 'DRAFT',
      reviewedBy: json['reviewed_by'] as String?,
      reviewedAt: json['reviewed_at'] != null ? DateTime.parse(json['reviewed_at'] as String) : null,
      createdAt: DateTime.parse(json['created_at'] as String),
    );
  }

  Map<String, dynamic> toJson() => {
        'company_id': companyId,
        'profile_id': profileId,
        'standup_date': standupDate.toIso8601String().split('T').first,
        'plan_task_1': planTask1,
        'plan_task_2': planTask2,
        'plan_task_3': planTask3,
        'completed_today': completedToday,
        'pending_today': pendingToday,
        'blockers': blockers,
        'status': status,
      };
}
