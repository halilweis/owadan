class ProProfile {
  const ProProfile({
    required this.id,
    required this.displayName,
    required this.languages,
    required this.verificationStatus,
    required this.active,
    this.bio,
    this.experienceYears,
    this.districtId,
    this.districtName,
    this.cityName,
  });

  final String id;
  final String displayName;
  final String? bio;
  final int? experienceYears;
  final List<String> languages;
  final String verificationStatus;
  final bool active;
  final int? districtId;
  final String? districtName;
  final String? cityName;

  factory ProProfile.fromJson(Map<String, dynamic> json) {
    return ProProfile(
      id: json['id']?.toString() ?? '',
      displayName: json['displayName']?.toString() ?? '',
      bio: json['bio']?.toString(),
      experienceYears: int.tryParse(json['experienceYears']?.toString() ?? ''),
      languages: (json['languages'] as List<dynamic>? ?? const [])
          .map((value) => value.toString())
          .toList(),
      verificationStatus: json['verificationStatus']?.toString() ?? 'DRAFT',
      active: json['active'] == true,
      districtId: int.tryParse(json['districtId']?.toString() ?? ''),
      districtName: json['districtName']?.toString(),
      cityName: json['cityName']?.toString(),
    );
  }
}

class ProDistrict {
  const ProDistrict({
    required this.id,
    required this.name,
    required this.cityId,
    required this.cityName,
  });

  final int id;
  final String name;
  final int cityId;
  final String cityName;

  factory ProDistrict.fromJson(Map<String, dynamic> json) {
    return ProDistrict(
      id: int.tryParse(json['id']?.toString() ?? '') ?? 0,
      name: json['name']?.toString() ?? '',
      cityId: int.tryParse(json['cityId']?.toString() ?? '') ?? 0,
      cityName: json['cityName']?.toString() ?? '',
    );
  }
}
