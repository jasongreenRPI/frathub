import 'package:frub/models/user_model.dart';

class Organization {
  final String id;
  final String name;
  final String description;
  final String? logo;
  final List<OrganizationMember> members;
  final List<String> events;
  final DateTime createdAt;
  final DateTime updatedAt;

  Organization({
    required this.id,
    required this.name,
    required this.description,
    this.logo,
    List<OrganizationMember>? members,
    List<String>? events,
    DateTime? createdAt,
    DateTime? updatedAt,
  })  : members = members ?? [],
        events = events ?? [],
        createdAt = createdAt ?? DateTime.now(),
        updatedAt = updatedAt ?? DateTime.now();

  factory Organization.fromJson(Map<String, dynamic> json) {
    return Organization(
      id: json['_id'] ?? json['id'],
      name: json['name'],
      description: json['description'],
      logo: json['logo'],
      members: (json['members'] as List?)
              ?.map((member) => OrganizationMember.fromJson(member))
              .toList() ??
          [],
      events: (json['events'] as List?)?.map((e) => e.toString()).toList() ?? [],
      createdAt: json['createdAt'] != null
          ? DateTime.parse(json['createdAt'])
          : DateTime.now(),
      updatedAt: json['updatedAt'] != null
          ? DateTime.parse(json['updatedAt'])
          : DateTime.now(),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'name': name,
      'description': description,
      'logo': logo,
    };
  }
}

class OrganizationMember {
  final String userId;
  final String role;
  final DateTime joinedAt;
  User? user; // Populated user data

  OrganizationMember({
    required this.userId,
    required this.role,
    DateTime? joinedAt,
    this.user,
  }) : joinedAt = joinedAt ?? DateTime.now();

  factory OrganizationMember.fromJson(Map<String, dynamic> json) {
    return OrganizationMember(
      userId: json['user'] ?? json['userId'],
      role: json['role'],
      joinedAt: json['joinedAt'] != null
          ? DateTime.parse(json['joinedAt'])
          : DateTime.now(),
      user: json['user'] is Map<String, dynamic>
          ? User.fromJson(json['user'])
          : null,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'user': userId,
      'role': role,
    };
  }
} 