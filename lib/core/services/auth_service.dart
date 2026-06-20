import 'dart:convert';
import 'package:http/http.dart' as http;

import 'api_service.dart';
import 'session_service.dart';

class AuthService {
  static Future<bool> login({
    required String email,
    required String password,
  }) async {
    try {
      final response = await http.post(
        ApiService.uri("login.php"),
        headers: {"Content-Type": "application/json"},
        body: jsonEncode({"email": email, "password": password}),
      );

      print("STATUS: ${response.statusCode}");
      print("BODY: ${response.body}");

      final data = jsonDecode(response.body);

      if (response.statusCode == 200 && data["success"] == true) {
        final user = data["user"];

        await SessionService.saveSession(
          userId: int.tryParse(user["id"].toString()) ?? 0,
          companyId: int.tryParse(user["company_id"].toString()) ?? 0,
          role: user["role"]?.toString() ?? "",
          token: "",
          firstName: user["firstname"]?.toString(),
          lastName: user["lastname"]?.toString(),
          companyName: user["company_name"]?.toString(),
        );

        return true;
      }

      return false;
    } catch (e) {
      print("Erreur login: $e");
      return false;
    }
  }
}
