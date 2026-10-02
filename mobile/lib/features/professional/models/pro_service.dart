class ProService {
  const ProService({
    required this.id,
    required this.categoryId,
    required this.name,
    required this.durationMinutes,
    required this.priceType,
    required this.currency,
    required this.active,
    this.description,
    this.price,
  });

  final String id;
  final int categoryId;
  final String name;
  final String? description;
  final int durationMinutes;
  final String priceType;
  final double? price;
  final String currency;
  final bool active;

  factory ProService.fromJson(Map<String, dynamic> json) {
    return ProService(
      id: json['id']?.toString() ?? '',
      categoryId: int.tryParse(json['categoryId']?.toString() ?? '') ?? 0,
      name: json['name']?.toString() ?? '',
      description: json['description']?.toString(),
      durationMinutes:
          int.tryParse(json['durationMinutes']?.toString() ?? '') ?? 0,
      priceType: json['priceType']?.toString() ?? 'FIXED',
      price: _toDouble(json['price']),
      currency: json['currency']?.toString() ?? 'TMT',
      active: json['active'] == true,
    );
  }

  static double? _toDouble(dynamic value) {
    if (value == null) {
      return null;
    }
    if (value is num) {
      return value.toDouble();
    }
    return double.tryParse(value.toString());
  }
}
