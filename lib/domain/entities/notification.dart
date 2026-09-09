class AppNotification {
  final String id;
  final String companyId;
  final String userId;
  final String title;
  final String body;
  final String type;
  final String? referenceId;
  final String? referenceType;
  final bool isRead;
  final String channel;
  final DateTime createdAt;

  const AppNotification({
    required this.id,
    required this.companyId,
    required this.userId,
    required this.title,
    required this.body,
    required this.type,
    this.referenceId,
    this.referenceType,
    this.isRead = false,
    this.channel = 'IN_APP',
    required this.createdAt,
  });

  AppNotification copyWith({bool? isRead}) {
    return AppNotification(
      id: id,
      companyId: companyId,
      userId: userId,
      title: title,
      body: body,
      type: type,
      referenceId: referenceId,
      referenceType: referenceType,
      isRead: isRead ?? this.isRead,
      channel: channel,
      createdAt: createdAt,
    );
  }

  factory AppNotification.fromJson(Map<String, dynamic> json) {
    return AppNotification(
      id: json['id'] as String,
      companyId: json['company_id'] as String,
      userId: json['user_id'] as String,
      title: json['title'] as String,
      body: json['body'] as String,
      type: json['type'] as String,
      referenceId: json['reference_id'] as String?,
      referenceType: json['reference_type'] as String?,
      isRead: json['is_read'] as bool? ?? false,
      channel: json['channel'] as String? ?? 'IN_APP',
      createdAt: DateTime.parse(json['created_at'] as String),
    );
  }

  Map<String, dynamic> toJson() => {
        'company_id': companyId,
        'user_id': userId,
        'title': title,
        'body': body,
        'type': type,
        'reference_id': referenceId,
        'reference_type': referenceType,
        'channel': channel,
      };
}
