class ProfessionalSummary {
  const ProfessionalSummary({
    required this.id,
    required this.displayName,
    required this.verificationStatus,
    required this.reviewCount,
    required this.currency,
    this.bio,
    this.experienceYears,
    this.averageRating,
    this.minPrice,
    this.nextAvailableAt,
    this.cityId,
    this.cityName,
    this.districtId,
    this.districtName,
    this.languages = const [],
  });

  final String id;
  final String displayName;
  final String? bio;
  final int? experienceYears;
  final List<String> languages;
  final String verificationStatus;
  final double? averageRating;
  final int reviewCount;
  final double? minPrice;
  final String currency;
  final DateTime? nextAvailableAt;

  final int? cityId;
  final String? cityName;
  final int? districtId;
  final String? districtName;

  String? get locationLabel {
    final district = districtName?.trim();
    final city = cityName?.trim();

    if (district != null &&
        district.isNotEmpty &&
        city != null &&
        city.isNotEmpty) {
      return '$district, $city';
    }

    if (city != null && city.isNotEmpty) return city;
    if (district != null && district.isNotEmpty) return district;

    return null;
  }

  factory ProfessionalSummary.fromJson(Map<String, dynamic> json) {
    final rawLocation = json['location'];
    final location = rawLocation is Map<String, dynamic>
        ? rawLocation
        : const <String, dynamic>{};

    return ProfessionalSummary(
      id: json['id']?.toString() ?? '',
      displayName: json['displayName']?.toString() ?? '',
      bio: json['bio']?.toString(),
      experienceYears: json['experienceYears'] is int
          ? json['experienceYears'] as int
          : int.tryParse(json['experienceYears']?.toString() ?? ''),
      languages: (json['languages'] as List<dynamic>? ?? const [])
          .map((item) => item.toString())
          .toList(),
      verificationStatus: json['verificationStatus']?.toString() ?? 'UNKNOWN',
      averageRating: _toDouble(json['averageRating']),
      reviewCount: int.tryParse(json['reviewCount']?.toString() ?? '') ?? 0,
      minPrice: _toDouble(json['minPrice']),
      currency: json['currency']?.toString() ?? 'TMT',
      nextAvailableAt: _toDateTime(json['nextAvailableAt']),
      cityId: int.tryParse(location['cityId']?.toString() ?? ''),
      cityName: location['cityName']?.toString(),
      districtId: int.tryParse(location['districtId']?.toString() ?? ''),
      districtName: location['districtName']?.toString(),
    );
  }

  static double? _toDouble(dynamic value) {
    if (value == null) return null;
    if (value is num) return value.toDouble();
    return double.tryParse(value.toString());
  }

  static DateTime? _toDateTime(dynamic value) {
    if (value == null) return null;
    return DateTime.tryParse(value.toString());
  }
}
