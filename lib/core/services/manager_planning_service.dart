import 'dart:convert';
import 'package:http/http.dart' as http;

import '../models/planning_comparison.dart';

class ManagerPlanningService {
  static const String baseUrl = "https://taskflowapp.eu/pointagepro";

  static Future<PlanningComparisonResponse> fetchPlanningComparison({
    required int companyId,
    required String weekStart,
  }) async {
    final uri = Uri.parse(
      "$baseUrl/planning_comparison.php?company_id=$companyId&week_start=$weekStart",
    );

    final response = await http.get(uri);

    final data = jsonDecode(response.body);

    return PlanningComparisonResponse.fromJson(data);
  }
}