import 'dart:convert';

import 'package:http/http.dart' as http;

import 'api_service.dart';
import 'session_service.dart';
import 'location_service.dart';

class PointageService {
static Future<Map<String, dynamic>> me() async {
  try {
    final userId = await SessionService.getUserId();
    final companyId = await SessionService.getCompanyId();
    final position = await LocationService.getCurrentPosition();

    final response = await http.post(
      ApiService.pointage("me.php"),
      headers: {"Content-Type": "application/json"},
      body: jsonEncode({
        "user_id": userId,
        "company_id": companyId,
        "latitude": position?.latitude,
        "longitude": position?.longitude,
        "gps_accuracy": position?.accuracy,
      }),
    );

    print("ME STATUS: ${response.statusCode}");
    print("ME BODY: ${response.body}");

    if (response.statusCode != 200) {
      return {"success": false};
    }

    return jsonDecode(response.body);
  } catch (e) {
    return {"success": false, "message": e.toString()};
  }
}

  static Future<Map<String, dynamic>> clock() async {
    try {
      final userId = await SessionService.getUserId();
      final companyId = await SessionService.getCompanyId();
      final position = await LocationService.getCurrentPosition();

      final response = await http.post(
        ApiService.pointage("clock.php"),
        headers: {"Content-Type": "application/json"},
        body: jsonEncode({
          "user_id": userId,
          "company_id": companyId,
          "latitude": position?.latitude,
          "longitude": position?.longitude,
          "gps_accuracy": position?.accuracy,
        }),
      );

      print("CLOCK STATUS: ${response.statusCode}");
      print("CLOCK BODY: ${response.body}");

      return jsonDecode(response.body);
    } catch (e) {
      return {"success": false, "message": e.toString()};
    }
  }

  static Future<Map<String, dynamic>> clockOut() async {
    try {
      final userId = await SessionService.getUserId();
      final companyId = await SessionService.getCompanyId();
      final position = await LocationService.getCurrentPosition();

      final response = await http.post(
        ApiService.pointage("clock_out.php"),
        headers: {"Content-Type": "application/json"},
        body: jsonEncode({
          "user_id": userId,
          "company_id": companyId,
          "latitude": position?.latitude,
          "longitude": position?.longitude,
          "gps_accuracy": position?.accuracy,
        }),
      );

      print("CLOCK OUT STATUS: ${response.statusCode}");
      print("CLOCK OUT BODY: ${response.body}");

      return jsonDecode(response.body);
    } catch (e) {
      return {"success": false, "message": e.toString()};
    }
  }

  static Future<Map<String, dynamic>> clockWithQr(
    String qrToken, {
    String? action,
  }) async {
    try {
      final userId = await SessionService.getUserId();
      final companyId = await SessionService.getCompanyId();
      final position = await LocationService.getCurrentPosition();

      final body = {
        "user_id": userId,
        "company_id": companyId,
        "qr_token": qrToken,
        "latitude": position?.latitude,
        "longitude": position?.longitude,
        "gps_accuracy": position?.accuracy,
      };

      if (action != null) {
        body["action"] = action;
      }

      final response = await http.post(
        ApiService.pointage("clock.php"),
        headers: {"Content-Type": "application/json"},
        body: jsonEncode(body),
      );

      print("CLOCK QR STATUS: ${response.statusCode}");
      print("CLOCK QR BODY: ${response.body}");

      return jsonDecode(response.body);
    } catch (e) {
      return {
        "success": false,
        "message": e.toString(),
      };
    }
  }
}