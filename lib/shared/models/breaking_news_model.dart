class BreakingNewsModel {
  const BreakingNewsModel({required this.id, required this.title});

  final int id;
  final String title;

  factory BreakingNewsModel.fromJson(Map<String, dynamic> json) {
    return BreakingNewsModel(
      id: json['id'] as int? ?? 0,
      title: (json['title'] ?? '').toString(),
    );
  }
}
