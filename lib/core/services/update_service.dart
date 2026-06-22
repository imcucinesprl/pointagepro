import 'dart:convert';
import 'dart:io';

import 'package:http/http.dart' as http;
import 'package:package_info_plus/package_info_plus.dart';

class UpdateService {

  static Future<Map<String, dynamic>?> check() async {

    final info = await PackageInfo.fromPlatform();

    final currentVersion = info.version;

    final platform = Platform.isIOS ? 'ios' : 'android';

    final response = await http.get(
      Uri.parse(
        'https://taskflowapp.eu/pointagepro/check_version.php?platform=$platform',
      ),
    );

    if (response.statusCode != 200) {
      return null;
    }

    final json = jsonDecode(response.body);

    if (json['success'] != true) {
      return null;
    }

    final data = json['data'];

    return {
      'current_version': currentVersion,
      ...data,
    };
  }

  static bool isVersionLower(
  String current,
  String minimum,
) {
  final currentParts =
      current.split('.').map(int.parse).toList();

  final minimumParts =
      minimum.split('.').map(int.parse).toList();

  for (int i = 0; i < minimumParts.length; i++) {

    if (currentParts[i] < minimumParts[i]) {
      return true;
    }

    if (currentParts[i] > minimumParts[i]) {
      return false;
    }
  }

  return false;
}

}