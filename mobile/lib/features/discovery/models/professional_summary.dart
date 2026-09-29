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

  factory ProfessionalSummary.fromJson(Map<String, dynamic> json) {
    return ProfessionalSummary(
      id: json['id']?.toString() ?? '',
      displayName: json['displayName']?.toString() ?? '',
      bio: json['bio']?.toString(),
      experienceYears: json['experienceYears'] as int?,
      languages: (json['languages'] as List<dynamic>? ?? const [])
          .map((item) => item.toString())
          .toList(),
      verificationStatus: json['verificationStatus']?.toString() ?? 'UNKNOWN',
      averageRating: _toDouble(json['averageRating']),
      reviewCount: json['reviewCount'] as int? ?? 0,
      minPrice: _toDouble(json['minPrice']),
      currency: json['currency']?.toString() ?? 'TMT',
      nextAvailableAt: _toDateTime(json['nextAvailableAt']),
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
