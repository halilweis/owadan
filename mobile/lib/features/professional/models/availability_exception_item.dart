class AvailabilityExceptionItem {
  const AvailabilityExceptionItem({
    required this.id,
    required this.startsAt,
    required this.endsAt,
    required this.type,
    this.note,
  });

  final String id;
  final DateTime startsAt;
  final DateTime endsAt;
  final String type;
  final String? note;

  bool get isBlocked => type == 'BLOCKED';

  factory AvailabilityExceptionItem.fromJson(Map<String, dynamic> json) {
    return AvailabilityExceptionItem(
      id: json['id']?.toString() ?? '',
      startsAt: DateTime.parse(json['startsAt'].toString()),
      endsAt: DateTime.parse(json['endsAt'].toString()),
      type: json['type']?.toString() ?? '',
      note: json['note']?.toString(),
    );
  }
}
