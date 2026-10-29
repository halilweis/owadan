class LocationCity {
  const LocationCity({
    required this.id,
    required this.name,
    required this.districts,
  });

  final int id;
  final String name;
  final List<LocationDistrict> districts;

  factory LocationCity.fromJson(Map<String, dynamic> json) {
    final rawDistricts = json['districts'];

    return LocationCity(
      id: int.tryParse(json['id']?.toString() ?? '') ?? 0,
      name: json['name']?.toString() ?? '',
      districts: rawDistricts is List
          ? rawDistricts
                .whereType<Map<String, dynamic>>()
                .map(LocationDistrict.fromJson)
                .toList()
          : const [],
    );
  }
}

class LocationDistrict {
  const LocationDistrict({
    required this.id,
    required this.cityId,
    required this.name,
  });

  final int id;
  final int cityId;
  final String name;

  factory LocationDistrict.fromJson(Map<String, dynamic> json) {
    return LocationDistrict(
      id: int.tryParse(json['id']?.toString() ?? '') ?? 0,
      cityId: int.tryParse(json['cityId']?.toString() ?? '') ?? 0,
      name: json['name']?.toString() ?? '',
    );
  }
}
