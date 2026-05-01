class AuthorModel {
  const AuthorModel({required this.id, required this.name, this.avatarUrl});

  final int id;
  final String name;
  final String? avatarUrl;

  factory AuthorModel.fromJson(Map<String, dynamic> json) {
    final avatars = json['avatar_urls'] as Map<String, dynamic>?;
    return AuthorModel(
      id: json['id'] as int? ?? 0,
      name: (json['name'] ?? 'كاتب غير معروف').toString(),
      avatarUrl: avatars?['96']?.toString() ?? avatars?['48']?.toString(),
    );
  }
}
