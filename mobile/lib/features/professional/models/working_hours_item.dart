class WorkingHoursItem {
  const WorkingHoursItem({
    required this.dayOfWeek,
    required this.startTime,
    required this.endTime,
  });

  final int dayOfWeek;
  final String startTime;
  final String endTime;

  factory WorkingHoursItem.fromJson(Map<String, dynamic> json) {
    return WorkingHoursItem(
      dayOfWeek: int.tryParse(json['dayOfWeek']?.toString() ?? '') ?? 0,
      startTime: json['startTime']?.toString() ?? '',
      endTime: json['endTime']?.toString() ?? '',
    );
  }

  Map<String, dynamic> toJson() => {
    'dayOfWeek': dayOfWeek,
    'startTime': startTime,
    'endTime': endTime,
  };
}
