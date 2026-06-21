class PlanningComparisonResponse {
  final bool success;
  final String weekStart;
  final List<PlanningDay> days;
  final String? message;

  PlanningComparisonResponse({
    required this.success,
    required this.weekStart,
    required this.days,
    this.message,
  });

  factory PlanningComparisonResponse.fromJson(Map<String, dynamic> json) {
    return PlanningComparisonResponse(
      success: json["success"] == true,
      weekStart: json["week_start"]?.toString() ?? "",
      message: json["message"]?.toString(),
      days: (json["days"] as List? ?? [])
          .map((e) => PlanningDay.fromJson(e))
          .toList(),
    );
  }
}

class PlanningDay {
  final String date;
  final String dayOfWeek;
  final List<PlanningEmployee> employees;

  PlanningDay({
    required this.date,
    required this.dayOfWeek,
    required this.employees,
  });

  factory PlanningDay.fromJson(Map<String, dynamic> json) {
    return PlanningDay(
      date: json["date"]?.toString() ?? "",
      dayOfWeek: json["day_of_week"]?.toString() ?? "",
      employees: (json["employees"] as List? ?? [])
          .map((e) => PlanningEmployee.fromJson(e))
          .toList(),
    );
  }
}

class PlanningEmployee {
  final int userId;
  final int cashEmployeeId;
  final String firstname;
  final String lastname;
  final String fullName;

  final String plannedStatus;
  final String? plannedStart;
  final String? plannedEnd;

  final String? realClockIn;
  final String? realPauseStart;
  final String? realPauseEnd;
  final String? realClockOut;

  final int? differenceMinutes;

  PlanningEmployee({
    required this.userId,
    required this.cashEmployeeId,
    required this.firstname,
    required this.lastname,
    required this.fullName,
    required this.plannedStatus,
    this.plannedStart,
    this.plannedEnd,
    this.realClockIn,
    this.realPauseStart,
    this.realPauseEnd,
    this.realClockOut,
    this.differenceMinutes,
  });

  factory PlanningEmployee.fromJson(Map<String, dynamic> json) {
    return PlanningEmployee(
      userId: int.tryParse(json["user_id"].toString()) ?? 0,
      cashEmployeeId: int.tryParse(json["cash_employee_id"].toString()) ?? 0,
      firstname: json["firstname"]?.toString() ?? "",
      lastname: json["lastname"]?.toString() ?? "",
      fullName: json["full_name"]?.toString() ?? "",
      plannedStatus: json["planned_status"]?.toString() ?? "",
      plannedStart: json["planned_start"]?.toString(),
      plannedEnd: json["planned_end"]?.toString(),
      realClockIn: json["real_clock_in"]?.toString(),
      realPauseStart: json["real_pause_start"]?.toString(),
      realPauseEnd: json["real_pause_end"]?.toString(),
      realClockOut: json["real_clock_out"]?.toString(),
      differenceMinutes: json["difference_minutes"] == null
          ? null
          : int.tryParse(json["difference_minutes"].toString()),
    );
  }
}