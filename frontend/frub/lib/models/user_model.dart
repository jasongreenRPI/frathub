class User {
  final String id;
  final String username;
  final String email;
  final String? profilePicture;
  final List<String> roles;
  final DateTime createdAt;
  final DateTime updatedAt;

  User({
    required this.id,
    required this.username,
    required this.email,
    this.profilePicture,
    List<String>? roles,
    DateTime? createdAt,
    DateTime? updatedAt,
  })  : roles = roles ?? [],
        createdAt = createdAt ?? DateTime.now(),
        updatedAt = updatedAt ?? DateTime.now();

  factory User.fromJson(Map<String, dynamic> json) {
    return User(
      id: json['_id'] ?? json['id'],
      username: json['username'],
      email: json['email'],
      profilePicture: json['profilePicture'],
      roles: (json['roles'] as List?)?.map((e) => e.toString()).toList() ?? [],
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
      'username': username,
      'email': email,
      'profilePicture': profilePicture,
    };
  }

  bool hasRole(String role) {
    return roles.contains(role);
  }

  bool isAdmin() {
    return roles.contains('admin');
  }
} 