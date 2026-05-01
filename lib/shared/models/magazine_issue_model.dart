class MagazineIssueModel {
  const MagazineIssueModel({
    required this.id,
    required this.title,
    required this.slug,
    this.coverImage,
    this.description,
    this.issueNumber,
    this.publishDate,
    required this.pdfSourceType,
    this.pdfUrl,
    this.fileSizeMb,
    this.pageCount,
    required this.status,
    required this.isFeatured,
    required this.sortOrder,
    required this.downloadCount,
  });

  final int id;
  final String title;
  final String slug;
  final String? coverImage;
  final String? description;
  final String? issueNumber;
  final DateTime? publishDate;
  final String pdfSourceType;
  final String? pdfUrl;
  final double? fileSizeMb;
  final int? pageCount;
  final String status;
  final bool isFeatured;
  final int sortOrder;
  final int downloadCount;

  factory MagazineIssueModel.fromJson(Map<String, dynamic> json) {
    return MagazineIssueModel(
      id: int.tryParse((json['id'] ?? 0).toString()) ?? 0,
      title: (json['title'] ?? '').toString(),
      slug: (json['slug'] ?? '').toString(),
      coverImage: json['cover_image']?.toString(),
      description: json['description']?.toString(),
      issueNumber: json['issue_number']?.toString(),
      publishDate: _parseDate((json['publish_date'] ?? '').toString()),
      pdfSourceType: (json['pdf_source_type'] ?? '').toString(),
      pdfUrl: json['pdf_url']?.toString(),
      fileSizeMb: double.tryParse((json['file_size_mb'] ?? '').toString()),
      pageCount: int.tryParse((json['page_count'] ?? '').toString()),
      status: (json['status'] ?? '').toString(),
      isFeatured: json['is_featured'] == true,
      sortOrder: int.tryParse((json['sort_order'] ?? 0).toString()) ?? 0,
      downloadCount:
          int.tryParse((json['download_count'] ?? 0).toString()) ?? 0,
    );
  }

  static DateTime? _parseDate(String raw) {
    final date = DateTime.tryParse(raw);
    return date?.toLocal();
  }
}

