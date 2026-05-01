class CategoryModel {
  const CategoryModel({required this.id, required this.name});

  final int id;
  final String name;

  factory CategoryModel.fromJson(Map<String, dynamic> json) {
    return CategoryModel(
      id: json['id'] as int? ?? 0,
      name: (json['name'] ?? 'قسم').toString(),
    );
  }
}
