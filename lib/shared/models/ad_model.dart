class AdModel {
  const AdModel({
    required this.id,
    required this.title,
    required this.placement,
    this.image,
    this.externalUrl,
    this.ctaText,
  });

  final int id;
  final String title;
  final String placement;
  final String? image;
  final String? externalUrl;
  final String? ctaText;

  factory AdModel.fromJson(Map<String, dynamic> json) {
    return AdModel(
      id: json['id'] as int? ?? 0,
      title: (json['title'] ?? '').toString(),
      placement: (json['placement'] ?? '').toString(),
      image: json['image']?.toString(),
      externalUrl: json['external_url']?.toString(),
      ctaText: json['cta_text']?.toString(),
    );
  }
}
