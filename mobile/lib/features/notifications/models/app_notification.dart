class AppNotification {
  const AppNotification({
    required this.id,
    required this.type,
    required this.title,
    required this.read,
    required this.createdAt,
    required this.data,
    this.message,
  });

  final String id;
  final String type;
  final String title;
  final String? message;
  final Map<String, dynamic> data;
  final bool read;
  final DateTime createdAt;

  String? get bookingId => data['bookingId']?.toString();

  factory AppNotification.fromJson(Map<String, dynamic> json) {
    final rawData = json['data'];

    return AppNotification(
      id: json['id']?.toString() ?? '',
      type: json['type']?.toString() ?? '',
      title: json['title']?.toString() ?? '',
      message: json['message']?.toString(),
      data: rawData is Map<String, dynamic>
          ? rawData
          : rawData is Map
          ? rawData.map((key, value) => MapEntry(key.toString(), value))
          : const {},
      read: json['read'] == true,
      createdAt:
          DateTime.tryParse(json['createdAt']?.toString() ?? '')?.toLocal() ??
          DateTime.now(),
    );
  }

  AppNotification copyWith({bool? read}) {
    return AppNotification(
      id: id,
      type: type,
      title: title,
      message: message,
      data: data,
      read: read ?? this.read,
      createdAt: createdAt,
    );
  }
}
