class Team {
  final String id;
  final String companyId;
  final String name;
  final String? description;
  final String? managerId;
  final DateTime createdAt;
  final int memberCount;

  const Team({
    required this.id,
    required this.companyId,
    required this.name,
    this.description,
    this.managerId,
    required this.createdAt,
    this.memberCount = 0,
  });

  Team copyWith({
    String? name,
    String? description,
    String? managerId,
    int? memberCount,
  }) {
    return Team(
      id: id,
      companyId: companyId,
      name: name ?? this.name,
      description: description ?? this.description,
      managerId: managerId ?? this.managerId,
      createdAt: createdAt,
      memberCount: memberCount ?? this.memberCount,
    );
  }

  factory Team.fromJson(Map<String, dynamic> json) {
    return Team(
      id: json['id'] as String,
      companyId: json['company_id'] as String,
      name: json['name'] as String,
      description: json['description'] as String?,
      managerId: json['manager_id'] as String?,
      createdAt: DateTime.parse(json['created_at'] as String),
      memberCount: json['member_count'] as int? ?? 0,
    );
  }

  Map<String, dynamic> toJson() => {
        'id': id,
        'company_id': companyId,
        'name': name,
        'description': description,
        'manager_id': managerId,
      };
}
