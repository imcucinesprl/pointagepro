import 'dart:convert';
import 'dart:io';

import 'package:flutter/foundation.dart';
import 'package:http/http.dart' as http;
import 'package:package_info_plus/package_info_plus.dart';

class UpdateService {
  static Future<Map<String, dynamic>?> check() async {
    // La vérification de version mobile ne s’applique pas au Web.
    if (kIsWeb) {
      debugPrint(
        'UpdateService : vérification ignorée sur le Web.',
      );

      return null;
    }

    try {
      final info = await PackageInfo.fromPlatform();

      final currentVersion = info.version;

      String platform;

      if (Platform.isIOS) {
        platform = 'ios';
      } else if (Platform.isAndroid) {
        platform = 'android';
      } else {
        debugPrint(
          'UpdateService : plateforme non prise en charge.',
        );

        return null;
      }

      final uri = Uri.parse(
        'https://taskflowapp.eu/pointagepro/check_version.php'
        '?platform=$platform',
      );

      final response = await http.get(uri);

      if (response.statusCode != 200) {
        debugPrint(
          'UpdateService HTTP ${response.statusCode}',
        );

        return null;
      }

      final dynamic decoded = jsonDecode(response.body);

      if (decoded is! Map<String, dynamic>) {
        debugPrint(
          'UpdateService : réponse JSON invalide.',
        );

        return null;
      }

      if (decoded['success'] != true) {
        return null;
      }

      final dynamic rawData = decoded['data'];

      if (rawData is! Map) {
        return null;
      }

      final data = Map<String, dynamic>.from(rawData);

      return {
        'current_version': currentVersion,
        ...data,
      };
    } catch (error, stackTrace) {
      debugPrint(
        'Erreur UpdateService.check : $error',
      );

      debugPrint(
        'StackTrace UpdateService : $stackTrace',
      );

      return null;
    }
  }

  static bool isVersionLower(
    String current,
    String minimum,
  ) {
    final currentParts = _parseVersion(current);
    final minimumParts = _parseVersion(minimum);

    final maximumLength = currentParts.length > minimumParts.length
        ? currentParts.length
        : minimumParts.length;

    for (var i = 0; i < maximumLength; i++) {
      final currentValue =
          i < currentParts.length ? currentParts[i] : 0;

      final minimumValue =
          i < minimumParts.length ? minimumParts[i] : 0;

      if (currentValue < minimumValue) {
        return true;
      }

      if (currentValue > minimumValue) {
        return false;
      }
    }

    return false;
  }

  static List<int> _parseVersion(String version) {
    return version
        .split('.')
        .map((part) {
          final cleanPart = part.replaceAll(
            RegExp(r'[^0-9]'),
            '',
          );

          return int.tryParse(cleanPart) ?? 0;
        })
        .toList();
  }
}