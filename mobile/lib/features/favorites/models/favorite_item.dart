class FavoriteItem {
  const FavoriteItem({
    required this.id,
    required this.professionalId,
    required this.displayName,
    required this.createdAt,
  });

  final String id;
  final String professionalId;
  final String displayName;
  final DateTime? createdAt;

  factory FavoriteItem.fromJson(Map<String, dynamic> json) {
    return FavoriteItem(
      id: json['id']?.toString() ?? '',
      professionalId: json['professionalId']?.toString() ?? '',
      displayName: json['displayName']?.toString() ?? '',
      createdAt: DateTime.tryParse(json['createdAt']?.toString() ?? ''),
    );
  }
}
