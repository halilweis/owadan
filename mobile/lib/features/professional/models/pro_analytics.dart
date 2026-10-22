class ProAnalytics {
  const ProAnalytics({
    required this.currency,
    required this.totalRevenue,
    required this.monthRevenue,
    required this.completedCount,
    required this.noShowCount,
    required this.totalCount,
    required this.completionRate,
    required this.noShowRate,
    required this.months,
    required this.topServices,
  });

  final String currency;
  final double totalRevenue;
  final double monthRevenue;
  final int completedCount;
  final int noShowCount;
  final int totalCount;
  final double completionRate;
  final double noShowRate;
  final List<ProAnalyticsMonth> months;
  final List<ProAnalyticsService> topServices;

  factory ProAnalytics.fromJson(Map<String, dynamic> json) {
    final monthsRaw = json['months'];
    final servicesRaw = json['topServices'];

    return ProAnalytics(
      currency: json['currency']?.toString() ?? 'TMT',
      totalRevenue: _toDouble(json['totalRevenue']),
      monthRevenue: _toDouble(json['monthRevenue']),
      completedCount: _toInt(json['completedCount']),
      noShowCount: _toInt(json['noShowCount']),
      totalCount: _toInt(json['totalCount']),
      completionRate: _toDouble(json['completionRate']),
      noShowRate: _toDouble(json['noShowRate']),
      months: monthsRaw is List
          ? monthsRaw
                .whereType<Map<String, dynamic>>()
                .map(ProAnalyticsMonth.fromJson)
                .toList()
          : const [],
      topServices: servicesRaw is List
          ? servicesRaw
                .whereType<Map<String, dynamic>>()
                .map(ProAnalyticsService.fromJson)
                .toList()
          : const [],
    );
  }

  static int _toInt(dynamic value) =>
      int.tryParse(value?.toString() ?? '') ?? 0;

  static double _toDouble(dynamic value) =>
      double.tryParse(value?.toString() ?? '') ?? 0;
}

class ProAnalyticsMonth {
  const ProAnalyticsMonth({
    required this.key,
    required this.label,
    required this.revenue,
    required this.completed,
    required this.noShows,
  });

  final String key;
  final String label;
  final double revenue;
  final int completed;
  final int noShows;

  factory ProAnalyticsMonth.fromJson(Map<String, dynamic> json) {
    return ProAnalyticsMonth(
      key: json['key']?.toString() ?? '',
      label: json['label']?.toString() ?? '',
      revenue: double.tryParse(json['revenue']?.toString() ?? '') ?? 0,
      completed: int.tryParse(json['completed']?.toString() ?? '') ?? 0,
      noShows: int.tryParse(json['noShows']?.toString() ?? '') ?? 0,
    );
  }
}

class ProAnalyticsService {
  const ProAnalyticsService({
    required this.name,
    required this.bookings,
    required this.completed,
    required this.revenue,
  });

  final String name;
  final int bookings;
  final int completed;
  final double revenue;

  factory ProAnalyticsService.fromJson(Map<String, dynamic> json) {
    return ProAnalyticsService(
      name: json['name']?.toString() ?? '',
      bookings: int.tryParse(json['bookings']?.toString() ?? '') ?? 0,
      completed: int.tryParse(json['completed']?.toString() ?? '') ?? 0,
      revenue: double.tryParse(json['revenue']?.toString() ?? '') ?? 0,
    );
  }
}
