class BookingModel {
  const BookingModel({
    required this.id,
    required this.professionalId,
    required this.serviceId,
    required this.serviceName,
    required this.startsAt,
    required this.endsAt,
    required this.status,
    required this.priceType,
    required this.currency,
    this.price,
    this.note,
  });

  final String id;
  final String professionalId;
  final String serviceId;
  final String serviceName;
  final DateTime startsAt;
  final DateTime endsAt;
  final String status;
  final String priceType;
  final double? price;
  final String currency;
  final String? note;

  factory BookingModel.fromJson(Map<String, dynamic> json) {
    return BookingModel(
      id: json['id']?.toString() ?? '',
      professionalId: json['professionalId']?.toString() ?? '',
      serviceId: json['serviceId']?.toString() ?? '',
      serviceName: json['serviceName']?.toString() ?? '',
      startsAt: DateTime.parse(json['startsAt'].toString()),
      endsAt: DateTime.parse(json['endsAt'].toString()),
      status: json['status']?.toString() ?? '',
      priceType: json['priceType']?.toString() ?? '',
      price: _toDouble(json['price']),
      currency: json['currency']?.toString() ?? 'TMT',
      note: json['note']?.toString(),
    );
  }

  static double? _toDouble(dynamic value) {
    if (value == null) return null;
    if (value is num) return value.toDouble();
    return double.tryParse(value.toString());
  }
}
