class BookingMessage {
  const BookingMessage({
    required this.id,
    required this.bookingId,
    required this.senderRole,
    required this.body,
    required this.createdAt,
  });

  final String id;
  final String bookingId;
  final String senderRole;
  final String body;
  final DateTime createdAt;

  bool get fromCustomer => senderRole == 'CUSTOMER';
  bool get fromProfessional => senderRole == 'PROFESSIONAL';

  factory BookingMessage.fromJson(Map<String, dynamic> json) {
    return BookingMessage(
      id: json['id']?.toString() ?? '',
      bookingId: json['bookingId']?.toString() ?? '',
      senderRole: json['senderRole']?.toString() ?? '',
      body: json['body']?.toString() ?? '',
      createdAt: DateTime.parse(json['createdAt'].toString()),
    );
  }
}
