import 'dart:convert';
import 'package:http/http.dart' as http;

import 'api_service.dart';
import 'session_service.dart';

class AuthService {
  static String? lastErrorMessage;

  static Future<bool> login({
    required String email,
    required String password,
  }) async {
    try {
      lastErrorMessage = null;

      final response = await http.post(
        ApiService.auth("login.php"),
        headers: {"Content-Type": "application/json"},
        body: jsonEncode({"email": email, "password": password}),
      );

      final data = jsonDecode(response.body);

      lastErrorMessage = data["message"]?.toString();

      if (response.statusCode == 200 && data["success"] == true) {
        final user = data["user"];

        final userId = int.tryParse(user["id"].toString());
        final companyId = int.tryParse(user["company_id"].toString());

        if (userId == null ||
            userId <= 0 ||
            companyId == null ||
            companyId <= 0) {
          lastErrorMessage = "Session invalide. Veuillez contacter le support.";
          return false;
        }

        final company = data["company"];

        await SessionService.saveSession(
          userId: userId,
          companyId: companyId,
          role: user["role"]?.toString() ?? "",
          token: data["token"]?.toString() ?? "",
          firstName: user["firstname"]?.toString(),
          lastName: user["lastname"]?.toString(),
          companyName:
              company?["name"]?.toString() ?? user["company_name"]?.toString(),
        );

        return true;
      }

      lastErrorMessage ??= "Email ou mot de passe incorrect.";
      return false;
    } catch (e) {
      lastErrorMessage = "Erreur de connexion au serveur.";
      return false;
    }
  }

  static Future<bool> forgotPassword({required String email}) async {
    try {
      final response = await http.post(
        ApiService.auth("forgot_password2.php"),
        headers: {"Content-Type": "application/json"},
        body: jsonEncode({"email": email}),
      );

      final data = jsonDecode(response.body);

      lastErrorMessage = data["message"]?.toString();

      return data["success"] == true;
    } catch (e) {
      lastErrorMessage = "Erreur de connexion au serveur.";
      return false;
    }
  }
}
