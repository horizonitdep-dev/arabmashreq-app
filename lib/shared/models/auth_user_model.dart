class AuthUserModel {
  const AuthUserModel({
    required this.id,
    required this.name,
    required this.email,
    this.phone,
    this.avatarUrl,
    this.role,
    this.createdAt,
    required this.isActive,
    required this.roles,
  });

  final int id;
  final String name;
  final String email;
  final String? phone;
  final String? avatarUrl;
  final String? role;
  final DateTime? createdAt;
  final bool isActive;
  final List<String> roles;

  factory AuthUserModel.fromJson(Map<String, dynamic> json) {
    final rawRoles = json['roles'];
    return AuthUserModel(
      id: int.tryParse((json['id'] ?? 0).toString()) ?? 0,
      name: (json['name'] ?? '').toString(),
      email: (json['email'] ?? '').toString(),
      phone: json['phone']?.toString(),
      avatarUrl: json['avatar_url']?.toString(),
      role: json['role']?.toString(),
      createdAt: DateTime.tryParse((json['created_at'] ?? '').toString()),
      isActive: json['is_active'] as bool? ?? true,
      roles: rawRoles is List
          ? rawRoles.map((e) => e.toString()).toList(growable: false)
          : const <String>[],
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'name': name,
      'email': email,
      'phone': phone,
      'avatar_url': avatarUrl,
      'role': role,
      'created_at': createdAt?.toIso8601String(),
      'is_active': isActive,
      'roles': roles,
    };
  }
}
