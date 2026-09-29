class ProfessionalReview {
  const ProfessionalReview({
    required this.id,
    required this.bookingId,
    required this.professionalId,
    required this.rating,
    required this.createdAt,
    this.comment,
  });

  final String id;
  final String bookingId;
  final String professionalId;
  final int rating;
  final String? comment;
  final DateTime? createdAt;

  factory ProfessionalReview.fromJson(Map<String, dynamic> json) {
    return ProfessionalReview(
      id: json['id']?.toString() ?? '',
      bookingId: json['bookingId']?.toString() ?? '',
      professionalId: json['professionalId']?.toString() ?? '',
      rating: json['rating'] as int? ?? 0,
      comment: json['comment']?.toString(),
      createdAt: DateTime.tryParse(json['createdAt']?.toString() ?? ''),
    );
  }
}
