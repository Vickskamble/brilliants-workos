class Task {
  final String id;
  final String companyId;
  final String title;
  final String? description;
  final String? assignedTo;
  final String? assignedBy;
  final String? teamId;
  final String priority;
  final String status;
  final DateTime? dueDate;
  final String? dueTime;
  final DateTime? completedAt;
  final String? result;
  final String? comment;
  final String? attachmentUrl;
  final double? actualValue;
  final double? targetValue;
  final bool isRecurring;
  final String? recurrenceId;
  final DateTime createdAt;
  final DateTime updatedAt;

  // Joined fields
  final String? assigneeName;
  final String? assignerName;
  final String? assigneeAvatarUrl;

  const Task({
    required this.id,
    required this.companyId,
    required this.title,
    this.description,
    this.assignedTo,
    this.assignedBy,
    this.teamId,
    required this.priority,
    required this.status,
    this.dueDate,
    this.dueTime,
    this.completedAt,
    this.result,
    this.comment,
    this.attachmentUrl,
    this.actualValue,
    this.targetValue,
    this.isRecurring = false,
    this.recurrenceId,
    required this.createdAt,
    required this.updatedAt,
    this.assigneeName,
    this.assignerName,
    this.assigneeAvatarUrl,
  });

  bool get isOverdue {
    if (dueDate == null) return false;
    if (status == 'COMPLETED' || status == 'CANCELLED') return false;
    return DateTime.now().isAfter(dueDate!);
  }

  int get daysOverdue {
    if (!isOverdue) return 0;
    return DateTime.now().difference(dueDate!).inDays;
  }

  bool get isCompleted => status == 'COMPLETED';
  bool get isInProgress => status == 'IN_PROGRESS';
  bool get isTodo => status == 'TODO';

  double? get achievementPercentage {
    if (targetValue == null || targetValue == 0) return null;
    if (actualValue == null) return 0;
    return (actualValue! / targetValue! * 100).clamp(0, 100);
  }

  Task copyWith({
    String? title,
    String? description,
    String? assignedTo,
    String? priority,
    String? status,
    DateTime? dueDate,
    DateTime? completedAt,
    String? result,
    String? comment,
    double? actualValue,
    double? targetValue,
  }) {
    return Task(
      id: id,
      companyId: companyId,
      title: title ?? this.title,
      description: description ?? this.description,
      assignedTo: assignedTo ?? this.assignedTo,
      assignedBy: assignedBy,
      teamId: teamId,
      priority: priority ?? this.priority,
      status: status ?? this.status,
      dueDate: dueDate ?? this.dueDate,
      dueTime: dueTime,
      completedAt: completedAt ?? this.completedAt,
      result: result ?? this.result,
      comment: comment ?? this.comment,
      attachmentUrl: attachmentUrl,
      actualValue: actualValue ?? this.actualValue,
      targetValue: targetValue ?? this.targetValue,
      isRecurring: isRecurring,
      recurrenceId: recurrenceId,
      createdAt: createdAt,
      updatedAt: DateTime.now(),
      assigneeName: assigneeName,
      assignerName: assignerName,
      assigneeAvatarUrl: assigneeAvatarUrl,
    );
  }

  factory Task.fromJson(Map<String, dynamic> json) {
    return Task(
      id: json['id'] as String,
      companyId: json['company_id'] as String,
      title: json['title'] as String,
      description: json['description'] as String?,
      assignedTo: json['assigned_to'] as String?,
      assignedBy: json['assigned_by'] as String?,
      teamId: json['team_id'] as String?,
      priority: json['priority'] as String? ?? 'MEDIUM',
      status: json['status'] as String? ?? 'TODO',
      dueDate: json['due_date'] != null ? DateTime.parse(json['due_date'] as String) : null,
      dueTime: json['due_time'] as String?,
      completedAt: json['completed_at'] != null ? DateTime.parse(json['completed_at'] as String) : null,
      result: json['result'] as String?,
      comment: json['comment'] as String?,
      attachmentUrl: json['attachment_url'] as String?,
      actualValue: (json['actual_value'] as num?)?.toDouble(),
      targetValue: (json['target_value'] as num?)?.toDouble(),
      isRecurring: json['is_recurring'] as bool? ?? false,
      recurrenceId: json['recurrence_id'] as String?,
      createdAt: DateTime.parse(json['created_at'] as String),
      updatedAt: DateTime.parse(json['updated_at'] as String),
      assigneeName: json['assignee_name'] as String?,
      assignerName: json['assigner_name'] as String?,
      assigneeAvatarUrl: json['assignee_avatar_url'] as String?,
    );
  }

  Map<String, dynamic> toJson() => {
        'id': id,
        'company_id': companyId,
        'title': title,
        'description': description,
        'assigned_to': assignedTo,
        'assigned_by': assignedBy,
        'team_id': teamId,
        'priority': priority,
        'status': status,
        'due_date': dueDate?.toIso8601String().split('T').first,
        'due_time': dueTime,
        'result': result,
        'comment': comment,
        'actual_value': actualValue,
        'target_value': targetValue,
      };
}
