import 'package:device_info_plus/device_info_plus.dart';
import 'package:flutter/foundation.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:uuid/uuid.dart';

class DeviceService {
  DeviceService._();

  static const String _deviceUuidKey =
      'pointagepro_device_uuid';

  static const Uuid _uuid = Uuid();

  /*
  |--------------------------------------------------------------------------
  | Identifiant permanent de l’installation
  |--------------------------------------------------------------------------
  */

  static Future<String> getDeviceUuid() async {
    final prefs =
        await SharedPreferences.getInstance();

    final existingUuid =
        prefs.getString(_deviceUuidKey)?.trim();

    if (existingUuid != null &&
        existingUuid.isNotEmpty) {
      return existingUuid;
    }

    final newUuid = _uuid.v4();

    await prefs.setString(
      _deviceUuidKey,
      newUuid,
    );

    return newUuid;
  }

  /*
  |--------------------------------------------------------------------------
  | Nom de la plateforme
  |--------------------------------------------------------------------------
  */

  static String getPlatformName() {
    if (kIsWeb) {
      return 'web';
    }

    switch (defaultTargetPlatform) {
      case TargetPlatform.android:
        return 'android';

      case TargetPlatform.iOS:
        return 'ios';

      case TargetPlatform.macOS:
        return 'macos';

      case TargetPlatform.windows:
        return 'windows';

      case TargetPlatform.linux:
        return 'linux';

      case TargetPlatform.fuchsia:
        return 'fuchsia';
    }
  }

  /*
  |--------------------------------------------------------------------------
  | Informations de l’appareil
  |--------------------------------------------------------------------------
  */

  static Future<Map<String, String?>>
      getDeviceInformation() async {
    final deviceInfo = DeviceInfoPlugin();

    try {
      /*
       * Flutter Web
       */
      if (kIsWeb) {
        final info =
            await deviceInfo.webBrowserInfo;

        final browserName =
            info.browserName.name;

        final platform =
            info.platform?.trim();

        final userAgent =
            info.userAgent?.trim();

        return {
          'device_name':
              _formatBrowserName(browserName),
          'device_model':
              platform == null || platform.isEmpty
                  ? 'Navigateur Web'
                  : platform,
          'os_version':
              userAgent == null || userAgent.isEmpty
                  ? 'Web'
                  : userAgent,
        };
      }

      /*
       * Android
       */
      if (defaultTargetPlatform ==
          TargetPlatform.android) {
        final info =
            await deviceInfo.androidInfo;

        final manufacturer =
            info.manufacturer.trim();

        final model =
            info.model.trim();

        return {
          'device_name':
              info.device.trim().isEmpty
                  ? 'Appareil Android'
                  : info.device.trim(),
          'device_model':
              '$manufacturer $model'.trim(),
          'os_version':
              'Android ${info.version.release}',
        };
      }

      /*
       * iPhone / iPad
       */
      if (defaultTargetPlatform ==
          TargetPlatform.iOS) {
        final info =
            await deviceInfo.iosInfo;

        return {
          'device_name':
              info.name.trim().isEmpty
                  ? 'Appareil iOS'
                  : info.name.trim(),
          'device_model':
              info.utsname.machine,
          'os_version':
              '${info.systemName} '
              '${info.systemVersion}'.trim(),
        };
      }

      /*
       * macOS
       */
      if (defaultTargetPlatform ==
          TargetPlatform.macOS) {
        final info =
            await deviceInfo.macOsInfo;

        return {
          'device_name':
              info.computerName.trim().isEmpty
                  ? 'Mac'
                  : info.computerName.trim(),
          'device_model':
              info.model.trim().isEmpty
                  ? 'macOS'
                  : info.model.trim(),
          'os_version':
              info.osRelease.trim().isEmpty
                  ? 'macOS'
                  : info.osRelease.trim(),
        };
      }

      /*
       * Windows
       */
      if (defaultTargetPlatform ==
          TargetPlatform.windows) {
        final info =
            await deviceInfo.windowsInfo;

        return {
          'device_name':
              info.computerName.trim().isEmpty
                  ? 'PC Windows'
                  : info.computerName.trim(),
          'device_model':
              info.productName.trim().isEmpty
                  ? 'Windows'
                  : info.productName.trim(),
          'os_version':
              '${info.displayVersion} '
              '${info.buildNumber}'.trim(),
        };
      }

      /*
       * Linux
       */
      if (defaultTargetPlatform ==
          TargetPlatform.linux) {
        final info =
            await deviceInfo.linuxInfo;

        return {
          'device_name':
              info.name.trim().isEmpty
                  ? 'Ordinateur Linux'
                  : info.name.trim(),
          'device_model':
              info.prettyName.trim().isEmpty
                  ? 'Linux'
                  : info.prettyName.trim(),
          'os_version':
              info.version?.trim().isNotEmpty == true
                  ? info.version!.trim()
                  : 'Linux',
        };
      }

      /*
       * Fuchsia ou plateforme inconnue
       */
      return {
        'device_name': 'Appareil',
        'device_model':
            getPlatformName(),
        'os_version':
            getPlatformName(),
      };
    } catch (error, stackTrace) {
      debugPrint(
        'Erreur récupération informations '
        'appareil : $error',
      );

      debugPrint(
        'StackTrace DeviceService : '
        '$stackTrace',
      );

      return {
        'device_name':
            kIsWeb
                ? 'Navigateur Web'
                : 'Appareil',
        'device_model':
            getPlatformName(),
        'os_version':
            getPlatformName(),
      };
    }
  }

  /*
  |--------------------------------------------------------------------------
  | Nom lisible du navigateur
  |--------------------------------------------------------------------------
  */

  static String _formatBrowserName(
    String browserName,
  ) {
    switch (browserName.toLowerCase()) {
      case 'chrome':
        return 'Google Chrome';

      case 'safari':
        return 'Safari';

      case 'firefox':
        return 'Mozilla Firefox';

      case 'edge':
        return 'Microsoft Edge';

      case 'opera':
        return 'Opera';

      case 'samsunginternet':
        return 'Samsung Internet';

      default:
        if (browserName.trim().isEmpty) {
          return 'Navigateur Web';
        }

        return browserName;
    }
  }
}