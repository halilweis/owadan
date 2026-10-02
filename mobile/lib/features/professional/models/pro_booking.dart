class ProBooking {
  const ProBooking({
    required this.id,
    required this.customerId,
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
  final String customerId;
  final String serviceName;
  final DateTime startsAt;
  final DateTime endsAt;
  final String status;
  final String priceType;
  final double? price;
  final String currency;
  final String? note;

  bool get isPending => status == 'PENDING';
  bool get isConfirmed => status == 'CONFIRMED';

  factory ProBooking.fromJson(Map<String, dynamic> json) {
    return ProBooking(
      id: json['id']?.toString() ?? '',
      customerId: json['customerId']?.toString() ?? '',
      serviceName: json['serviceName']?.toString() ?? '',
      startsAt: DateTime.parse(json['startsAt'].toString()),
      endsAt: DateTime.parse(json['endsAt'].toString()),
      status: json['status']?.toString() ?? '',
      priceType: json['priceType']?.toString() ?? '',
      price: double.tryParse(json['price']?.toString() ?? ''),
      currency: json['currency']?.toString() ?? 'TMT',
      note: json['note']?.toString(),
    );
  }
}
