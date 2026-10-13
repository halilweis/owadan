class ProDashboard {
  const ProDashboard({
    required this.todayAppointments,
    required this.pendingBookings,
    required this.completedBookings,
    required this.reviewCount,
    required this.totalRevenue,
    required this.monthRevenue,
    required this.currency,
    this.averageRating,
    this.nextAppointment,
  });

  final int todayAppointments;
  final int pendingBookings;
  final int completedBookings;
  final int reviewCount;
  final double? averageRating;
  final double totalRevenue;
  final double monthRevenue;
  final String currency;
  final ProDashboardAppointment? nextAppointment;

  factory ProDashboard.fromJson(Map<String, dynamic> json) {
    final next = json['nextAppointment'];

    return ProDashboard(
      todayAppointments:
          int.tryParse(json['todayAppointments']?.toString() ?? '') ?? 0,
      pendingBookings:
          int.tryParse(json['pendingBookings']?.toString() ?? '') ?? 0,
      completedBookings:
          int.tryParse(json['completedBookings']?.toString() ?? '') ?? 0,
      reviewCount: int.tryParse(json['reviewCount']?.toString() ?? '') ?? 0,
      averageRating: _toDouble(json['averageRating']),
      totalRevenue: _toDouble(json['totalRevenue']) ?? 0,
      monthRevenue: _toDouble(json['monthRevenue']) ?? 0,
      currency: json['currency']?.toString() ?? 'TMT',
      nextAppointment: next is Map<String, dynamic>
          ? ProDashboardAppointment.fromJson(next)
          : null,
    );
  }

  static double? _toDouble(dynamic value) {
    if (value == null) return null;
    if (value is num) return value.toDouble();
    return double.tryParse(value.toString());
  }
}

class ProDashboardAppointment {
  const ProDashboardAppointment({
    required this.id,
    required this.serviceName,
    required this.startsAt,
    required this.endsAt,
    required this.status,
  });

  final String id;
  final String serviceName;
  final DateTime startsAt;
  final DateTime endsAt;
  final String status;

  factory ProDashboardAppointment.fromJson(Map<String, dynamic> json) {
    return ProDashboardAppointment(
      id: json['id']?.toString() ?? '',
      serviceName: json['serviceName']?.toString() ?? '',
      startsAt: DateTime.parse(json['startsAt'].toString()),
      endsAt: DateTime.parse(json['endsAt'].toString()),
      status: json['status']?.toString() ?? '',
    );
  }
}
