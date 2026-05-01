class CommentModel {
  const CommentModel({
    required this.id,
    required this.articleId,
    required this.parentId,
    required this.content,
    required this.status,
    required this.createdAt,
    required this.userId,
    required this.userName,
    this.userAvatarUrl,
    this.replies = const <CommentModel>[],
  });

  final int id;
  final int articleId;
  final int? parentId;
  final String content;
  final String status;
  final DateTime? createdAt;
  final int userId;
  final String userName;
  final String? userAvatarUrl;
  final List<CommentModel> replies;

  factory CommentModel.fromJson(Map<String, dynamic> json) {
    final userJson =
        Map<String, dynamic>.from((json['user'] ?? <String, dynamic>{}) as Map);
    final repliesRaw = json['replies'];

    return CommentModel(
      id: int.tryParse((json['id'] ?? 0).toString()) ?? 0,
      articleId: int.tryParse((json['article_id'] ?? 0).toString()) ?? 0,
      parentId: json['parent_id'] == null
          ? null
          : int.tryParse(json['parent_id'].toString()),
      content: (json['content'] ?? '').toString(),
      status: (json['status'] ?? '').toString(),
      createdAt: _parseDate((json['created_at'] ?? '').toString()),
      userId:
          int.tryParse((userJson['id'] ?? json['user_id'] ?? 0).toString()) ??
              0,
      userName: (userJson['name'] ?? 'مستخدم').toString(),
      userAvatarUrl: userJson['avatar_url']?.toString(),
      replies: repliesRaw is List
          ? repliesRaw
              .whereType<Map<String, dynamic>>()
              .map(CommentModel.fromJson)
              .toList(growable: false)
          : const <CommentModel>[],
    );
  }

  static DateTime? _parseDate(String raw) {
    final dt = DateTime.tryParse(raw);
    return dt?.toLocal();
  }
}
