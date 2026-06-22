class EmployeeWeekDaySummary {
  final String date;
  final String dayOfWeek;
  final String status;
  final String? plannedStart;
  final String? plannedEnd;
  final String? clockIn;
  final String? clockOut;
  final int pauseSeconds;
  final int plannedSeconds;
  final int workedSeconds;
  final int differenceSeconds;

  EmployeeWeekDaySummary({
    required this.date,
    required this.dayOfWeek,
    required this.status,
    required this.plannedStart,
    required this.plannedEnd,
    required this.clockIn,
    required this.clockOut,
    required this.pauseSeconds,
    required this.plannedSeconds,
    required this.workedSeconds,
    required this.differenceSeconds,
  });

  factory EmployeeWeekDaySummary.fromJson(Map<String, dynamic> json) {
    return EmployeeWeekDaySummary(
      date: json['date']?.toString() ?? '',
      dayOfWeek: json['day_of_week']?.toString() ?? '',
      status: json['status']?.toString() ?? '',
      plannedStart: json['planned_start']?.toString(),
      plannedEnd: json['planned_end']?.toString(),
      clockIn: json['clock_in']?.toString(),
      clockOut: json['clock_out']?.toString(),
      pauseSeconds: int.tryParse(json['pause_seconds'].toString()) ?? 0,
      plannedSeconds: int.tryParse(json['planned_seconds'].toString()) ?? 0,
      workedSeconds: int.tryParse(json['worked_seconds'].toString()) ?? 0,
      differenceSeconds: int.tryParse(json['difference_seconds'].toString()) ?? 0,
    );
  }
}