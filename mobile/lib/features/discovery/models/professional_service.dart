class ProfessionalService {
  const ProfessionalService({
    required this.id,
    required this.categoryId,
    required this.name,
    required this.durationMinutes,
    required this.priceType,
    required this.price,
    required this.currency,
    this.description,
  });

  final String id;
  final int categoryId;
  final String name;
  final String? description;
  final int durationMinutes;
  final String priceType;
  final double price;
  final String currency;

  factory ProfessionalService.fromJson(Map<String, dynamic> json) {
    return ProfessionalService(
      id: json['id']?.toString() ?? '',
      categoryId: json['categoryId'] as int? ?? 0,
      name: json['name']?.toString() ?? '',
      description: json['description']?.toString(),
      durationMinutes: json['durationMinutes'] as int? ?? 0,
      priceType: json['priceType']?.toString() ?? 'FIXED',
      price: _toDouble(json['price']) ?? 0,
      currency: json['currency']?.toString() ?? 'TMT',
    );
  }

  static double? _toDouble(dynamic value) {
    if (value == null) return null;
    if (value is num) return value.toDouble();
    return double.tryParse(value.toString());
  }
}
