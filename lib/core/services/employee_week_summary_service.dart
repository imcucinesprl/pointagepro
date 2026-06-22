import 'dart:convert';
import 'package:http/http.dart' as http;

import '../../models/employee_week_summary.dart';

class EmployeeWeekSummaryService {
  static const String baseUrl = 'https://taskflowapp.eu/pointagepro';

  static Future<List<EmployeeWeekDaySummary>> fetchWeekSummary({
    required int userId,
    required int companyId,
    required String weekStart,
  }) async {
    final uri = Uri.parse(
      '$baseUrl/employee_week_summary.php'
      '?user_id=$userId'
      '&company_id=$companyId'
      '&week_start=$weekStart',
    );

    final response = await http.get(uri);

    final data = jsonDecode(response.body);

    if (response.statusCode != 200 || data['success'] != true) {
      throw Exception(data['message'] ?? 'Erreur chargement semaine');
    }

    final days = data['days'] as List<dynamic>? ?? [];

    return days
        .map((e) => EmployeeWeekDaySummary.fromJson(e))
        .toList();
  }
}