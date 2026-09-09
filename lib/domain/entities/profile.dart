class Profile {
  final String id;
  final String userId;
  final String companyId;
  final String fullName;
  final String? phone;
  final String? avatarUrl;
  final String role;
  final String department;
  final bool isActive;
  final DateTime joinedAt;

  const Profile({
    required this.id,
    required this.userId,
    required this.companyId,
    required this.fullName,
    this.phone,
    this.avatarUrl,
    required this.role,
    required this.department,
    required this.isActive,
    required this.joinedAt,
  });

  String get initials {
    final parts = fullName.trim().split(' ');
    if (parts.length >= 2) return '${parts.first[0]}${parts.last[0]}'.toUpperCase();
    if (parts.isNotEmpty && parts.first.isNotEmpty) return parts.first[0].toUpperCase();
    return '?';
  }

  bool get isOwner => role == 'OWNER';
  bool get isAdmin => role == 'OWNER' || role == 'ADMIN';
  bool get isManager => role == 'OWNER' || role == 'ADMIN' || role == 'MANAGER';

  Profile copyWith({
    String? fullName,
    String? phone,
    String? avatarUrl,
    String? role,
    String? department,
    bool? isActive,
  }) {
    return Profile(
      id: id,
      userId: userId,
      companyId: companyId,
      fullName: fullName ?? this.fullName,
      phone: phone ?? this.phone,
      avatarUrl: avatarUrl ?? this.avatarUrl,
      role: role ?? this.role,
      department: department ?? this.department,
      isActive: isActive ?? this.isActive,
      joinedAt: joinedAt,
    );
  }

  factory Profile.fromJson(Map<String, dynamic> json) {
    return Profile(
      id: json['id'] as String,
      userId: json['user_id'] as String,
      companyId: json['company_id'] as String,
      fullName: json['full_name'] as String? ?? '',
      phone: json['phone'] as String?,
      avatarUrl: json['avatar_url'] as String?,
      role: json['role'] as String? ?? 'MEMBER',
      department: json['department'] as String? ?? 'OTHER',
      isActive: json['is_active'] as bool? ?? true,
      joinedAt: DateTime.parse(json['joined_at'] as String),
    );
  }

  Map<String, dynamic> toJson() => {
        'id': id,
        'user_id': userId,
        'company_id': companyId,
        'full_name': fullName,
        'phone': phone,
        'avatar_url': avatarUrl,
        'role': role,
        'department': department,
        'is_active': isActive,
        'joined_at': joinedAt.toIso8601String(),
      };
}
