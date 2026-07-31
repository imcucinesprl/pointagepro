import 'dart:async';
import 'dart:convert';

import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter/foundation.dart';
import 'package:http/http.dart' as http;
import 'package:package_info_plus/package_info_plus.dart';

import 'api_service.dart';
import 'communication_events.dart';
import 'device_service.dart';
import 'session_service.dart';

class PushNotificationService {
  PushNotificationService._();

  /*
  |--------------------------------------------------------------------------
  | Configuration Firebase Web
  |--------------------------------------------------------------------------
  */

  /// Clé publique VAPID disponible dans :
  ///
  /// Firebase Console
  /// → Paramètres du projet
  /// → Cloud Messaging
  /// → Certificats Web Push
  ///
  /// Ne jamais utiliser une clé privée ici.
  static const String _webVapidKey =
      'BClB9jJjsVv12Ho4a23oTXcOrxAWNDNQarUS3dLEpDJ9eQFclP6zFCD_CzViXJ6Z09NWbkxvSVaAQWUUdIqRLAQ';

  /// Mets cette valeur à true uniquement pour forcer une fois la
  /// régénération du token Web.
  ///
  /// Après le premier test réussi, remets impérativement false.
  static const bool _forceWebTokenRefresh = false;

  static final FirebaseMessaging _messaging =
      FirebaseMessaging.instance;

  static StreamSubscription<String>? _tokenSubscription;

  static StreamSubscription<RemoteMessage>?
      _foregroundMessageSubscription;

  static StreamSubscription<RemoteMessage>?
      _notificationOpenSubscription;

  static bool _initialized = false;

  /*
  |--------------------------------------------------------------------------
  | Initialisation
  |--------------------------------------------------------------------------
  */

  static Future<void> initialize() async {
    if (_initialized) {
      return;
    }

    _initialized = true;

    try {
      debugPrint(
        'Initialisation du service de notifications.',
      );

      debugPrint(
        'Firebase projectId : '
        '${Firebase.app().options.projectId}',
      );

      debugPrint(
        'Firebase messagingSenderId : '
        '${Firebase.app().options.messagingSenderId}',
      );

      final settings = await _requestPermission();

      final permissionGranted =
          settings.authorizationStatus ==
                  AuthorizationStatus.authorized ||
              settings.authorizationStatus ==
                  AuthorizationStatus.provisional;

      if (!permissionGranted) {
        debugPrint(
          'Les notifications ne sont pas autorisées.',
        );

        _initialized = false;
        return;
      }

      /*
       * Sur iOS et macOS natifs, le token APNs doit parfois
       * être disponible avant la récupération du token FCM.
       */
      if (!kIsWeb &&
          (defaultTargetPlatform ==
                  TargetPlatform.iOS ||
              defaultTargetPlatform ==
                  TargetPlatform.macOS)) {
        await _waitForApnsToken();
      }

      /*
       * Régénération temporaire du token Web.
       *
       * Cette opération est utile lorsqu’un ancien token
       * a été refusé par Firebase.
       */
      if (kIsWeb && _forceWebTokenRefresh) {
        await _deleteFirebaseToken();
      }

      final registered =
          await registerCurrentDevice();

      if (!registered) {
        debugPrint(
          'L’appareil n’a pas pu être enregistré '
          'pour les notifications.',
        );
      }

      await _listenToTokenRefresh();

      _listenToForegroundMessages();
      _listenToNotificationOpen();

      debugPrint(
        'Service de notifications initialisé.',
      );
    } catch (error, stackTrace) {
      _initialized = false;

      debugPrint(
        'Erreur initialisation notifications : '
        '$error',
      );

      debugPrint(
        'StackTrace notifications : '
        '$stackTrace',
      );
    }
  }

  /*
  |--------------------------------------------------------------------------
  | Autorisations
  |--------------------------------------------------------------------------
  */

  static Future<NotificationSettings>
      _requestPermission() async {
    final settings =
        await _messaging.requestPermission(
      alert: true,
      announcement: false,
      badge: true,
      carPlay: false,
      criticalAlert: false,
      provisional: false,
      sound: true,
    );

    debugPrint(
      'Autorisation notifications : '
      '${settings.authorizationStatus}',
    );

    return settings;
  }

  /*
  |--------------------------------------------------------------------------
  | Attente du token APNs
  |--------------------------------------------------------------------------
  */

  static Future<void> _waitForApnsToken() async {
    const maximumAttempts = 10;

    for (
      var attempt = 0;
      attempt < maximumAttempts;
      attempt++
    ) {
      final apnsToken =
          await _messaging.getAPNSToken();

      if (apnsToken != null &&
          apnsToken.trim().isNotEmpty) {
        debugPrint(
          'Token APNs disponible.',
        );

        return;
      }

      await Future<void>.delayed(
        const Duration(milliseconds: 500),
      );
    }

    debugPrint(
      'Le token APNs n’est pas encore disponible.',
    );
  }

  /*
  |--------------------------------------------------------------------------
  | Suppression du token Firebase
  |--------------------------------------------------------------------------
  */

  static Future<void> _deleteFirebaseToken() async {
    try {
      await _messaging.deleteToken();

      debugPrint(
        'Ancien token Firebase supprimé.',
      );
    } catch (error, stackTrace) {
      debugPrint(
        'Impossible de supprimer l’ancien token '
        'Firebase : $error',
      );

      debugPrint(
        'StackTrace suppression token Firebase : '
        '$stackTrace',
      );
    }
  }

  /*
  |--------------------------------------------------------------------------
  | Renouvellement du token Firebase
  |--------------------------------------------------------------------------
  */

  static Future<void> _listenToTokenRefresh() async {
    await _tokenSubscription?.cancel();

    _tokenSubscription =
        _messaging.onTokenRefresh.listen(
      (String newToken) async {
        final normalizedToken =
            newToken.trim();

        if (normalizedToken.isEmpty) {
          debugPrint(
            'Firebase a retourné un token renouvelé vide.',
          );

          return;
        }

        debugPrint(
          'Le token FCM a été renouvelé.',
        );

        debugPrint(
          'Longueur du nouveau token FCM : '
          '${normalizedToken.length}',
        );

        final registered =
            await registerCurrentDevice(
          fcmToken: normalizedToken,
        );

        if (!registered) {
          debugPrint(
            'Le nouveau token FCM n’a pas pu être '
            'enregistré sur le serveur.',
          );
        }
      },
      onError: (Object error) {
        debugPrint(
          'Erreur renouvellement token FCM : '
          '$error',
        );
      },
    );
  }

  /*
  |--------------------------------------------------------------------------
  | Enregistrement de l’appareil
  |--------------------------------------------------------------------------
  */

  static Future<bool> registerCurrentDevice({
    String? fcmToken,
  }) async {
    try {
      final companyId =
          await SessionService.getCompanyId();

      final userId =
          await SessionService.getUserId();

      final clientKey =
          (await SessionService
                      .getSynkroClientKey())
                  ?.trim() ??
              '';

      final authToken =
          (await SessionService.getToken())
                  ?.trim() ??
              '';

      if (companyId == null ||
          companyId <= 0) {
        debugPrint(
          'Enregistrement push ignoré : '
          'company_id absent.',
        );

        return false;
      }

      if (clientKey.isEmpty) {
        debugPrint(
          'Enregistrement push ignoré : '
          'clé Synkro absente.',
        );

        return false;
      }

      final token =
          await _getFirebaseToken(
        suppliedToken: fcmToken,
      );

      if (token == null ||
          token.isEmpty) {
        debugPrint(
          'Enregistrement push impossible : '
          'token FCM absent.',
        );

        return false;
      }

      final deviceUuid =
          await DeviceService.getDeviceUuid();

      final deviceInformation =
          await DeviceService
              .getDeviceInformation();

      final packageInfo =
          await PackageInfo.fromPlatform();

      final headers = <String, String>{
        'Content-Type':
            'application/json; charset=UTF-8',
        'Accept': 'application/json',
        'X-Synkro-Client': clientKey,
        'X-Synkro-Company-Id':
            companyId.toString(),
      };

      if (authToken.isNotEmpty) {
        headers['Authorization'] =
            'Bearer $authToken';
      }

      final uri =
          ApiService.communications(
        'register_device.php',
      );

      final body = <String, dynamic>{
        'user_id': userId,
        'device_uuid': deviceUuid,
        'fcm_token': token,
        'platform':
            DeviceService.getPlatformName(),
        'app_name': 'pointagepro',
        'app_version':
            packageInfo.version,
        'app_build':
            packageInfo.buildNumber,
        'device_name':
            deviceInformation[
                'device_name'
            ],
        'device_model':
            deviceInformation[
                'device_model'
            ],
        'os_version':
            deviceInformation[
                'os_version'
            ],
        'notifications_enabled': true,
        'message_notifications_enabled':
            true,
        'message_sound_enabled': true,
      };

      debugPrint(
        'Enregistrement de l’appareil push : '
        '$uri',
      );

      debugPrint(
        'Client Synkro : $clientKey',
      );

      debugPrint(
        'Entreprise Synkro : $companyId',
      );

      debugPrint(
        'Utilisateur Synkro : $userId',
      );

      debugPrint(
        'Plateforme push : '
        '${DeviceService.getPlatformName()}',
      );

      debugPrint(
        'Longueur du token envoyé : '
        '${token.length}',
      );

      final response = await http
          .post(
            uri,
            headers: headers,
            body: jsonEncode(body),
          )
          .timeout(
            const Duration(seconds: 15),
          );

      final result =
          _decodeResponse(response);

      if (result == null) {
        return false;
      }

      if (result['success'] != true) {
        debugPrint(
          'Enregistrement push refusé : '
          '${result['message']}',
        );

        return false;
      }

      debugPrint(
        'Appareil enregistré pour les notifications.',
      );

      return true;
    } on TimeoutException {
      debugPrint(
        'Délai dépassé pendant l’enregistrement '
        'de l’appareil push.',
      );

      return false;
    } catch (error, stackTrace) {
      debugPrint(
        'Erreur registerCurrentDevice : '
        '$error',
      );

      debugPrint(
        'StackTrace registerCurrentDevice : '
        '$stackTrace',
      );

      return false;
    }
  }

  /*
  |--------------------------------------------------------------------------
  | Récupération du token Firebase
  |--------------------------------------------------------------------------
  */

  static Future<String?> _getFirebaseToken({
    String? suppliedToken,
  }) async {
    final provided =
        suppliedToken?.trim() ?? '';

    if (provided.isNotEmpty) {
      debugPrint(
        'Utilisation du token FCM fourni '
        'par onTokenRefresh.',
      );

      debugPrint(
        'Longueur du token fourni : '
        '${provided.length}',
      );

      return provided;
    }

    try {
      final String? firebaseToken;

      if (kIsWeb) {
        if (_webVapidKey.isEmpty ||
            _webVapidKey ==
                'COLLE_ICI_TA_CLE_VAPID_PUBLIQUE') {
          debugPrint(
            'La clé publique VAPID Web '
            'n’est pas configurée.',
          );

          return null;
        }

        firebaseToken =
            await _messaging.getToken(
          vapidKey: _webVapidKey,
        );
      } else {
        firebaseToken =
            await _messaging.getToken();
      }

      final normalizedToken =
          firebaseToken?.trim();

      final tokenAvailable =
          normalizedToken != null &&
              normalizedToken.isNotEmpty;

      debugPrint(
        'Token FCM généré : '
        '$tokenAvailable',
      );

      debugPrint(
        'Longueur token FCM : '
        '${normalizedToken?.length ?? 0}',
      );

      if (tokenAvailable) {
        final previewLength =
            normalizedToken.length > 20
                ? 20
                : normalizedToken.length;

        debugPrint(
          'Début token FCM : '
          '${normalizedToken.substring(0, previewLength)}...',
        );
      }

      return normalizedToken;
    } catch (error, stackTrace) {
      debugPrint(
        'Impossible de récupérer le token FCM : '
        '$error',
      );

      debugPrint(
        'StackTrace récupération token FCM : '
        '$stackTrace',
      );

      return null;
    }
  }

  /*
  |--------------------------------------------------------------------------
  | Régénération manuelle du token
  |--------------------------------------------------------------------------
  */

  static Future<bool>
      regenerateAndRegisterCurrentToken() async {
    try {
      await _deleteFirebaseToken();

      await Future<void>.delayed(
        const Duration(milliseconds: 500),
      );

      return registerCurrentDevice();
    } catch (error, stackTrace) {
      debugPrint(
        'Erreur régénération token Firebase : '
        '$error',
      );

      debugPrint(
        'StackTrace régénération token Firebase : '
        '$stackTrace',
      );

      return false;
    }
  }

  /*
  |--------------------------------------------------------------------------
  | Désenregistrement
  |--------------------------------------------------------------------------
  */

  static Future<bool> unregisterCurrentDevice({
    bool deleteFirebaseToken = false,
  }) async {
    try {
      final companyId =
          await SessionService.getCompanyId();

      final clientKey =
          (await SessionService
                      .getSynkroClientKey())
                  ?.trim() ??
              '';

      final authToken =
          (await SessionService.getToken())
                  ?.trim() ??
              '';

      if (companyId == null ||
          companyId <= 0 ||
          clientKey.isEmpty) {
        return false;
      }

      final deviceUuid =
          await DeviceService.getDeviceUuid();

      final headers = <String, String>{
        'Content-Type':
            'application/json; charset=UTF-8',
        'Accept': 'application/json',
        'X-Synkro-Client': clientKey,
        'X-Synkro-Company-Id':
            companyId.toString(),
      };

      if (authToken.isNotEmpty) {
        headers['Authorization'] =
            'Bearer $authToken';
      }

      final uri =
          ApiService.communications(
        'unregister_device.php',
      );

      final response = await http
          .post(
            uri,
            headers: headers,
            body: jsonEncode({
              'device_uuid': deviceUuid,
              'app_name': 'pointagepro',
            }),
          )
          .timeout(
            const Duration(seconds: 15),
          );

      final result =
          _decodeResponse(response);

      final success =
          result != null &&
              result['success'] == true;

      if (deleteFirebaseToken) {
        await _deleteFirebaseToken();
      }

      return success;
    } on TimeoutException {
      debugPrint(
        'Délai dépassé pendant le '
        'désenregistrement push.',
      );

      return false;
    } catch (error, stackTrace) {
      debugPrint(
        'Erreur unregisterCurrentDevice : '
        '$error',
      );

      debugPrint(
        'StackTrace unregisterCurrentDevice : '
        '$stackTrace',
      );

      return false;
    }
  }

  /*
  |--------------------------------------------------------------------------
  | Messages reçus lorsque l’application est ouverte
  |--------------------------------------------------------------------------
  */

  static void _listenToForegroundMessages() {
    _foregroundMessageSubscription?.cancel();

    _foregroundMessageSubscription =
        FirebaseMessaging.onMessage.listen(
      (RemoteMessage message) {
        debugPrint(
          'Notification reçue au premier plan.',
        );

        debugPrint(
          'Titre : '
          '${message.notification?.title}',
        );

        debugPrint(
          'Message : '
          '${message.notification?.body}',
        );

        debugPrint(
          'Données : ${message.data}',
        );

        if (_isCommunicationMessage(message)) {
          debugPrint(
            'Nouveau message Synkro détecté.',
          );

          debugPrint(
            'Actualisation immédiate '
            'de la messagerie.',
          );

          CommunicationEvents
              .notifyNewMessage();
        }
      },
      onError: (Object error) {
        debugPrint(
          'Erreur réception notification : '
          '$error',
        );
      },
    );
  }

  /*
  |--------------------------------------------------------------------------
  | Ouverture d’une notification
  |--------------------------------------------------------------------------
  */

  static void _listenToNotificationOpen() {
    _notificationOpenSubscription?.cancel();

    _notificationOpenSubscription =
        FirebaseMessaging
            .onMessageOpenedApp
            .listen(
      (RemoteMessage message) {
        debugPrint(
          'Notification ouverte : '
          '${message.data}',
        );

        if (_isCommunicationMessage(message)) {
          CommunicationEvents
              .notifyNewMessage();
        }
      },
      onError: (Object error) {
        debugPrint(
          'Erreur ouverture notification : '
          '$error',
        );
      },
    );

    _messaging.getInitialMessage().then(
      (RemoteMessage? message) {
        if (message == null) {
          return;
        }

        debugPrint(
          'Application ouverte depuis une '
          'notification : ${message.data}',
        );

        if (_isCommunicationMessage(message)) {
          CommunicationEvents
              .notifyNewMessage();
        }
      },
    ).catchError(
      (Object error) {
        debugPrint(
          'Erreur récupération notification '
          'initiale : $error',
        );
      },
    );
  }

  /*
  |--------------------------------------------------------------------------
  | Identification d’une notification de messagerie
  |--------------------------------------------------------------------------
  */

  static bool _isCommunicationMessage(
    RemoteMessage message,
  ) {
    final data = message.data;

    final notificationType = (
      data['type'] ??
      data['notification_type'] ??
      data['event'] ??
      data['action'] ??
      ''
    )
        .toString()
        .trim()
        .toLowerCase();

    final channel = (
      data['channel'] ??
      data['source'] ??
      ''
    )
        .toString()
        .trim()
        .toLowerCase();

    final conversationId = (
      data['conversation_id'] ??
      data['conversationId'] ??
      ''
    )
        .toString()
        .trim();

    if (conversationId.isNotEmpty) {
      return true;
    }

    const communicationTypes = {
      'new_message',
      'message',
      'communication_message',
      'whatsapp_message',
      'incoming_message',
      'new_whatsapp_message',
    };

    if (communicationTypes.contains(
      notificationType,
    )) {
      return true;
    }

    const communicationChannels = {
      'whatsapp',
      'sms',
      'email',
      'mail',
      'communication',
    };

    return communicationChannels.contains(
      channel,
    );
  }

  /*
  |--------------------------------------------------------------------------
  | Décodage JSON
  |--------------------------------------------------------------------------
  */

  static Map<String, dynamic>? _decodeResponse(
    http.Response response,
  ) {
    try {
      final body =
          response.body.trim();

      if (body.isEmpty) {
        debugPrint(
          'Réponse vide du serveur push.',
        );

        return null;
      }

      final dynamic decoded =
          jsonDecode(body);

      if (decoded is! Map) {
        debugPrint(
          'Réponse push invalide.',
        );

        return null;
      }

      final result =
          Map<String, dynamic>.from(
        decoded,
      );

      if (response.statusCode < 200 ||
          response.statusCode >= 300) {
        debugPrint(
          'Erreur HTTP push '
          '${response.statusCode} : '
          '${result['message']}',
        );

        return null;
      }

      return result;
    } on FormatException catch (error) {
      debugPrint(
        'Réponse JSON push invalide : '
        '$error',
      );

      debugPrint(
        'Réponse brute : '
        '${response.body}',
      );

      return null;
    } catch (error, stackTrace) {
      debugPrint(
        'Erreur décodage réponse push : '
        '$error',
      );

      debugPrint(
        'StackTrace décodage push : '
        '$stackTrace',
      );

      return null;
    }
  }

  /*
  |--------------------------------------------------------------------------
  | Nettoyage
  |--------------------------------------------------------------------------
  */

  static Future<void> dispose() async {
    await _tokenSubscription?.cancel();
    await _foregroundMessageSubscription
        ?.cancel();
    await _notificationOpenSubscription
        ?.cancel();

    _tokenSubscription = null;
    _foregroundMessageSubscription = null;
    _notificationOpenSubscription = null;

    _initialized = false;

    debugPrint(
      'Service de notifications arrêté.',
    );
  }
}