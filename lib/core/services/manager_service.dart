import 'dart:convert';
import 'package:http/http.dart' as http;

import 'session_service.dart';

class ManagerService {
  static const String baseUrl = 'https://taskflowapp.eu/pointagepro';

  static Future<Map<String, dynamic>> today() async {
    final companyId = await SessionService.getCompanyId();

    final url = Uri.parse(
      '$baseUrl/manager_today.php?company_id=$companyId',
    );

    final response = await http.get(url);

    return jsonDecode(response.body) as Map<String, dynamic>;
  }

  static Future<Map<String, dynamic>> employeeDay({
  required int userId,
  String? date,
}) async {
  final companyId = await SessionService.getCompanyId();

  final queryDate = date ?? DateTime.now().toIso8601String().substring(0, 10);

  final url = Uri.parse(
    '$baseUrl/manager_employee_day.php?company_id=$companyId&user_id=$userId&date=$queryDate',
  );

  final response = await http.get(url);

  return jsonDecode(response.body) as Map<String, dynamic>;
}


static Future<Map<String, dynamic>> employees() async {
  final companyId = await SessionService.getCompanyId();

  final url = Uri.parse(
    '$baseUrl/manager_employees.php?company_id=$companyId',
  );

  final response = await http.get(url);

  return jsonDecode(response.body) as Map<String, dynamic>;
}

}