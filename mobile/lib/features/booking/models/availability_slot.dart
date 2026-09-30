class AvailabilitySlot {
  const AvailabilitySlot({
    required this.startsAtIso,
    required this.endsAtIso,
    required this.startsAt,
    required this.endsAt,
  });

  final String startsAtIso;
  final String endsAtIso;
  final DateTime startsAt;
  final DateTime endsAt;

  factory AvailabilitySlot.fromJson(Map<String, dynamic> json) {
    final startsAtIso = json['startsAt']?.toString() ?? '';
    final endsAtIso = json['endsAt']?.toString() ?? '';

    return AvailabilitySlot(
      startsAtIso: startsAtIso,
      endsAtIso: endsAtIso,
      startsAt: DateTime.parse(startsAtIso),
      endsAt: DateTime.parse(endsAtIso),
    );
  }
}
