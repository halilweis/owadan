class ProClientSummary {
  const ProClientSummary({
    required this.customerId,
    required this.phoneNumber,
    required this.appointmentCount,
    required this.completedCount,
    required this.noShowCount,
    required this.totalSpent,
    required this.currency,
    this.displayName,
    this.lastVisit,
  });

  final String customerId;
  final String? displayName;
  final String phoneNumber;
  final int appointmentCount;
  final int completedCount;
  final int noShowCount;
  final double totalSpent;
  final String currency;
  final DateTime? lastVisit;

  String get title => displayName != null && displayName!.trim().isNotEmpty
      ? displayName!.trim()
      : phoneNumber;

  factory ProClientSummary.fromJson(Map<String, dynamic> json) {
    return ProClientSummary(
      customerId: json['customerId']?.toString() ?? '',
      displayName: json['displayName']?.toString(),
      phoneNumber: json['phoneNumber']?.toString() ?? '',
      appointmentCount:
          int.tryParse(json['appointmentCount']?.toString() ?? '') ?? 0,
      completedCount:
          int.tryParse(json['completedCount']?.toString() ?? '') ?? 0,
      noShowCount: int.tryParse(json['noShowCount']?.toString() ?? '') ?? 0,
      totalSpent: double.tryParse(json['totalSpent']?.toString() ?? '') ?? 0,
      currency: json['currency']?.toString() ?? 'TMT',
      lastVisit: DateTime.tryParse(json['lastVisit']?.toString() ?? ''),
    );
  }
}

class ProClientDetail {
  const ProClientDetail({
    required this.id,
    required this.phoneNumber,
    required this.appointmentCount,
    required this.completedCount,
    required this.noShowCount,
    required this.totalSpent,
    required this.currency,
    required this.appointments,
    this.displayName,
    this.note,
  });

  final String id;
  final String? displayName;
  final String phoneNumber;
  final int appointmentCount;
  final int completedCount;
  final int noShowCount;
  final double totalSpent;
  final String currency;
  final String? note;
  final List<ProClientAppointment> appointments;

  String get title => displayName != null && displayName!.trim().isNotEmpty
      ? displayName!.trim()
      : phoneNumber;

  factory ProClientDetail.fromJson(Map<String, dynamic> json) {
    final rawAppointments = json['appointments'];

    return ProClientDetail(
      id: json['id']?.toString() ?? '',
      displayName: json['displayName']?.toString(),
      phoneNumber: json['phoneNumber']?.toString() ?? '',
      appointmentCount:
          int.tryParse(json['appointmentCount']?.toString() ?? '') ?? 0,
      completedCount:
          int.tryParse(json['completedCount']?.toString() ?? '') ?? 0,
      noShowCount: int.tryParse(json['noShowCount']?.toString() ?? '') ?? 0,
      totalSpent: double.tryParse(json['totalSpent']?.toString() ?? '') ?? 0,
      currency: json['currency']?.toString() ?? 'TMT',
      note: json['note']?.toString(),
      appointments: rawAppointments is List
          ? rawAppointments
                .whereType<Map<String, dynamic>>()
                .map(ProClientAppointment.fromJson)
                .toList()
          : const [],
    );
  }
}

class ProClientAppointment {
  const ProClientAppointment({
    required this.id,
    required this.serviceName,
    required this.startsAt,
    required this.endsAt,
    required this.status,
    required this.currency,
    this.price,
    this.note,
  });

  final String id;
  final String serviceName;
  final DateTime startsAt;
  final DateTime endsAt;
  final String status;
  final double? price;
  final String currency;
  final String? note;

  factory ProClientAppointment.fromJson(Map<String, dynamic> json) {
    return ProClientAppointment(
      id: json['id']?.toString() ?? '',
      serviceName: json['serviceName']?.toString() ?? '',
      startsAt: DateTime.parse(json['startsAt'].toString()),
      endsAt: DateTime.parse(json['endsAt'].toString()),
      status: json['status']?.toString() ?? '',
      price: double.tryParse(json['price']?.toString() ?? ''),
      currency: json['currency']?.toString() ?? 'TMT',
      note: json['note']?.toString(),
    );
  }
}
