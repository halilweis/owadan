class ProfessionalPortfolioItem {
  const ProfessionalPortfolioItem({
    required this.id,
    required this.imageUrl,
    required this.featured,
    this.title,
    this.description,
    this.serviceId,
    this.serviceName,
  });

  final String id;
  final String imageUrl;
  final String? title;
  final String? description;
  final String? serviceId;
  final String? serviceName;
  final bool featured;

  factory ProfessionalPortfolioItem.fromJson(Map<String, dynamic> json) {
    return ProfessionalPortfolioItem(
      id: json['id']?.toString() ?? '',
      imageUrl: json['imageUrl']?.toString() ?? '',
      title: json['title']?.toString(),
      description: json['description']?.toString(),
      serviceId: json['serviceId']?.toString(),
      serviceName: json['serviceName']?.toString(),
      featured: json['featured'] == true,
    );
  }
}
