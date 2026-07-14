import 'dart:convert';

import 'package:http/http.dart' as http;

import 'api_service.dart';
import 'session_service.dart';

class ManagerService {
  static const String baseUrl =
      'https://taskflowapp.eu/pointagepro';

  static Future<Map<String, dynamic>> today() async {
    try {
      final companyId = await SessionService.getCompanyId();

      if (companyId == null || companyId <= 0) {
        return {
          "success": false,
          "message": "Entreprise introuvable dans la session.",
        };
      }

      final url = Uri.parse(
        '$baseUrl/manager_today.php?company_id=$companyId',
      );

      final response = await http.get(url);

      return _decodeResponse(response);
    } catch (e) {
      return {
        "success": false,
        "message": "Erreur de connexion : $e",
      };
    }
  }

  static Future<Map<String, dynamic>> employeeDay({
    required int userId,
    String? date,
  }) async {
    try {
      final companyId = await SessionService.getCompanyId();

      if (companyId == null || companyId <= 0) {
        return {
          "success": false,
          "message": "Entreprise introuvable dans la session.",
        };
      }

      final queryDate =
          date ??
          DateTime.now().toIso8601String().substring(0, 10);

      final url = Uri.parse(
        '$baseUrl/manager_employee_day.php'
        '?company_id=$companyId'
        '&user_id=$userId'
        '&date=$queryDate',
      );

      final response = await http.get(url);

      return _decodeResponse(response);
    } catch (e) {
      return {
        "success": false,
        "message": "Erreur de connexion : $e",
      };
    }
  }

  static Future<Map<String, dynamic>> employees() async {
    try {
      final companyId = await SessionService.getCompanyId();

      if (companyId == null || companyId <= 0) {
        return {
          "success": false,
          "message": "Entreprise introuvable dans la session.",
        };
      }

      final url = Uri.parse(
        '$baseUrl/manager_employees.php'
        '?company_id=$companyId',
      );

      final response = await http.get(url);

      return _decodeResponse(response);
    } catch (e) {
      return {
        "success": false,
        "message": "Erreur de connexion : $e",
      };
    }
  }

static Future<Map<String, dynamic>> createEmployee({
  required String firstname,
  required String lastname,
  required String email,
  required String password,
  required String role,
  required String permissionLevel,
  required bool canClock,
}) async {
  try {
    final companyId =
        await SessionService.getCompanyId();

    final createdBy =
        await SessionService.getUserId();

    if (companyId == null || companyId <= 0) {
      return {
        "success": false,
        "message":
            "Entreprise introuvable dans la session.",
      };
    }

    if (createdBy == null || createdBy <= 0) {
      return {
        "success": false,
        "message":
            "Utilisateur connecté introuvable.",
      };
    }

    final url = Uri.parse(
      'https://taskflowapp.eu/users/create_user.php',
    );

    final response = await http.post(
      url,
      headers: {
        "Content-Type": "application/json",
        "Accept": "application/json",
      },
body: jsonEncode({
  "company_id": companyId,
  "created_by": createdBy,
  "firstname": firstname,
  "lastname": lastname,
  "email": email,
  "password": password,

  // TF_users.role
  "role": role,

  // Active uniquement la partie PointagePro du PHP
  "product": "pointagepro",

  // PP_employee_settings.permission_level
  "permission_level": permissionLevel,

  // PP_employee_settings.can_clock
  "can_clock": canClock ? 1 : 0,
}),
    );

    return _decodeResponse(response);
  } catch (e) {
    return {
      "success": false,
      "message": "Erreur de connexion : $e",
    };
  }
}

  static Map<String, dynamic> _decodeResponse(
    http.Response response,
  ) {
    try {
      final decoded = jsonDecode(response.body);

      if (decoded is! Map<String, dynamic>) {
        return {
          "success": false,
          "message": "Réponse invalide du serveur.",
        };
      }

      if (response.statusCode < 200 ||
          response.statusCode >= 300) {
        return {
          "success": false,
          "message":
              decoded["message"]?.toString() ??
              "Erreur serveur ${response.statusCode}.",
        };
      }

      return decoded;
    } catch (e) {
      return {
        "success": false,
        "message":
            "Réponse serveur illisible "
            "(${response.statusCode}).",
        "server_response": response.body,
      };
    }
  }

 static Future<Map<String, dynamic>> deleteUser({
  required int userId,
}) async {
  try {
    final deletedBy = await SessionService.getUserId();

    if (deletedBy == null || deletedBy <= 0) {
      return {
        "success": false,
        "message": "Session utilisateur invalide.",
      };
    }

    final response = await http.post(
      ApiService.users("delete_user.php"),
      headers: {
        "Content-Type": "application/json",
      },
      body: jsonEncode({
        "user_id": userId,
        "deleted_by": deletedBy,
      }),
    );

    if (response.body.trim().isEmpty) {
      return {
        "success": false,
        "message": "Le serveur a renvoyé une réponse vide.",
      };
    }

    final decoded = jsonDecode(response.body);

    if (decoded is! Map<String, dynamic>) {
      return {
        "success": false,
        "message": "Réponse invalide du serveur.",
      };
    }

    return decoded;
  } catch (e) {
    return {
      "success": false,
      "message": "Erreur de connexion : $e",
    };
  }
}

static Future<Map<String, dynamic>> updateUser({
  required int userId,
  required String firstname,
  required String lastname,
  required String email,
  required String role,
  required bool isActive,
  required bool canClock,
  String password = '',
}) async {
  try {
    final companyId = await SessionService.getCompanyId();
    final updatedBy = await SessionService.getUserId();

    if (companyId == null || companyId <= 0) {
      return {
        "success": false,
        "message": "Entreprise introuvable dans la session.",
      };
    }

    if (updatedBy == null || updatedBy <= 0) {
      return {
        "success": false,
        "message": "Utilisateur connecté introuvable.",
      };
    }

    final response = await http.post(
      ApiService.users("update_user.php"),
      headers: {
        "Content-Type": "application/json",
        "Accept": "application/json",
      },
      body: jsonEncode({
        "id": userId,
        "company_id": companyId,
        "updated_by": updatedBy,
        "firstname": firstname,
        "lastname": lastname,
        "email": email,
        "password": password,
        "role": role,
        "is_active": isActive ? 1 : 0,
        "can_clock": canClock ? 1 : 0,
      }),
    );

    return _decodeResponse(response);
  } catch (e) {
    return {
      "success": false,
      "message": "Erreur de connexion : $e",
    };
  }
}

}