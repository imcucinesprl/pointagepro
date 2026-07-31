import 'dart:convert';

import 'package:flutter/foundation.dart';
import 'package:http/http.dart' as http;

import 'api_service.dart';
import 'session_service.dart';

class CommunicationService {
  static String? lastErrorMessage;

  /*
  |--------------------------------------------------------------------------
  | Construction des en-têtes Synkro
  |--------------------------------------------------------------------------
  */

static Future<Map<String, String>?> _buildHeaders() async {
  lastErrorMessage = null;

  final companyId =
      await SessionService.getCompanyId();

  final token =
      (await SessionService.getToken())?.trim() ?? '';

  final clientKey =
      (await SessionService.getSynkroClientKey())
              ?.trim() ??
          '';

  debugPrint('Synkro companyId : $companyId');

  debugPrint(
    'Synkro clientKey présent : '
    '${clientKey.isNotEmpty}',
  );

  debugPrint(
    'Token présent : ${token.isNotEmpty}',
  );

  if (companyId == null || companyId <= 0) {
    lastErrorMessage =
        'Entreprise introuvable dans la session.';

    return null;
  }

  if (clientKey.isEmpty) {
    lastErrorMessage =
        'La messagerie Synkro n’est pas configurée '
        'pour cette entreprise.';

    return null;
  }

  final headers = <String, String>{
    'Content-Type':
        'application/json; charset=UTF-8',
    'Accept': 'application/json',
    'X-Synkro-Client': clientKey,
    'X-Synkro-Company-Id':
        companyId.toString(),
  };

  if (token.isNotEmpty) {
    headers['Authorization'] =
        'Bearer $token';
  }

  return headers;
}

  /*
  |--------------------------------------------------------------------------
  | Liste des conversations
  |--------------------------------------------------------------------------
  */

  static Future<Map<String, dynamic>?> getConversations({
    int page = 1,
    int perPage = 20,
  }) async {
    try {
      lastErrorMessage = null;

      final headers = await _buildHeaders();

      if (headers == null) {
        return null;
      }

      final uri = ApiService.communications(
        'conversations.php',
      ).replace(
        queryParameters: {
          'page': page.toString(),
          'per_page': perPage.toString(),
        },
      );

      debugPrint('Synkro GET : $uri');

      final response = await http.get(
        uri,
        headers: headers,
      );

      debugPrint(
        'Synkro conversations HTTP : '
        '${response.statusCode}',
      );

      debugPrint(
        'Synkro conversations body : '
        '${response.body}',
      );

      return _decodeResponse(response);
    } catch (error, stackTrace) {
      debugPrint(
        'Erreur getConversations : $error',
      );

      debugPrint(
        'StackTrace getConversations : $stackTrace',
      );

      lastErrorMessage =
          'Impossible de charger les conversations.';

      return null;
    }
  }

  /*
  |--------------------------------------------------------------------------
  | Messages d’une conversation
  |--------------------------------------------------------------------------
  */

static Future<Map<String, dynamic>?> getMessages({
  required int conversationId,
  int page = 1,
  int perPage = 50,
}) async {
  try {
    lastErrorMessage = null;

    if (conversationId <= 0) {
      lastErrorMessage = 'Conversation invalide.';
      return null;
    }

    final headers = await _buildHeaders();

    if (headers == null) {
      return null;
    }

    final uri = ApiService.communications(
      'messages.php',
    ).replace(
      queryParameters: {
        'conversation_id': conversationId.toString(),
        'page': page.toString(),
        'per_page': perPage.toString(),
      },
    );

    debugPrint('Synkro messages URL : $uri');

    final response = await http.get(
      uri,
      headers: headers,
    );

    debugPrint(
      'Synkro messages HTTP : ${response.statusCode}',
    );

    debugPrint(
      'Synkro messages body : ${response.body}',
    );

    return _decodeResponse(response);
  } catch (error, stackTrace) {
    debugPrint('Erreur getMessages : $error');
    debugPrint('StackTrace getMessages : $stackTrace');

    lastErrorMessage =
        'Impossible de charger les messages : $error';

    return null;
  }
}

  /*
  |--------------------------------------------------------------------------
  | Recherche de conversations
  |--------------------------------------------------------------------------
  */

  static Future<Map<String, dynamic>?> searchConversations({
    required String query,
    int page = 1,
    int perPage = 20,
  }) async {
    try {
      lastErrorMessage = null;

      final cleanedQuery = query.trim();

      if (cleanedQuery.isEmpty) {
        return getConversations(
          page: page,
          perPage: perPage,
        );
      }

      final headers = await _buildHeaders();

      if (headers == null) {
        return null;
      }

      final uri = ApiService.communications(
        'search.php',
      ).replace(
        queryParameters: {
          'search': cleanedQuery,
          'page': page.toString(),
          'per_page': perPage.toString(),
        },
      );

      debugPrint('Synkro GET : $uri');

      final response = await http.get(
        uri,
        headers: headers,
      );

      debugPrint(
        'Synkro search HTTP : '
        '${response.statusCode}',
      );

      debugPrint(
        'Synkro search body : '
        '${response.body}',
      );

      return _decodeResponse(response);
    } catch (error, stackTrace) {
      debugPrint(
        'Erreur searchConversations : $error',
      );

      debugPrint(
        'StackTrace searchConversations : '
        '$stackTrace',
      );

      lastErrorMessage =
          'Impossible d’effectuer la recherche.';

      return null;
    }
  }

  /*
  |--------------------------------------------------------------------------
  | Envoi d’un message
  |--------------------------------------------------------------------------
  */

  static Future<Map<String, dynamic>?> sendMessage({
    required int conversationId,
    required String message,
  }) async {
    try {
      lastErrorMessage = null;

      final cleanedMessage = message.trim();

      if (conversationId <= 0) {
        lastErrorMessage =
            'Conversation invalide.';

        return null;
      }

      if (cleanedMessage.isEmpty) {
        lastErrorMessage =
            'Le message ne peut pas être vide.';

        return null;
      }

      final headers = await _buildHeaders();

      if (headers == null) {
        return null;
      }

      final uri = ApiService.communications(
        'send.php',
      );

      debugPrint('Synkro POST : $uri');

      final response = await http.post(
        uri,
        headers: headers,
        body: jsonEncode({
          'conversation_id': conversationId,
          'message': cleanedMessage,
        }),
      );

      debugPrint(
        'Synkro send HTTP : '
        '${response.statusCode}',
      );

      debugPrint(
        'Synkro send body : '
        '${response.body}',
      );

      return _decodeResponse(response);
    } catch (error, stackTrace) {
      debugPrint(
        'Erreur sendMessage : $error',
      );

      debugPrint(
        'StackTrace sendMessage : $stackTrace',
      );

      lastErrorMessage =
          'Impossible d’envoyer le message.';

      return null;
    }
  }

  /*
  |--------------------------------------------------------------------------
  | Marquer une conversation comme lue
  |--------------------------------------------------------------------------
  */

  static Future<bool> markConversationRead({
    required int conversationId,
  }) async {
    try {
      lastErrorMessage = null;

      if (conversationId <= 0) {
        lastErrorMessage =
            'Conversation invalide.';

        return false;
      }

      final headers = await _buildHeaders();

      if (headers == null) {
        return false;
      }

      final uri = ApiService.communications(
        'mark_read.php',
      );

      debugPrint('Synkro POST : $uri');

      final response = await http.post(
        uri,
        headers: headers,
        body: jsonEncode({
          'conversation_id': conversationId,
        }),
      );

      debugPrint(
        'Synkro mark-read HTTP : '
        '${response.statusCode}',
      );

      debugPrint(
        'Synkro mark-read body : '
        '${response.body}',
      );

      final data = _decodeResponse(response);

      return data != null &&
          data['success'] == true;
    } catch (error, stackTrace) {
      debugPrint(
        'Erreur markConversationRead : $error',
      );

      debugPrint(
        'StackTrace markConversationRead : '
        '$stackTrace',
      );

      lastErrorMessage =
          'Impossible de marquer la conversation '
          'comme lue.';

      return false;
    }
  }

  /*
  |--------------------------------------------------------------------------
  | Afficahge du nombre de messages a lire dans navbar 
  |--------------------------------------------------------------------------
  */

static Future<int> getTotalUnreadCount() async {
  try {
    lastErrorMessage = null;

    final headers = await _buildHeaders();

    if (headers == null) {
      return 0;
    }

    final uri = ApiService.communications(
      'conversations.php',
    );

    final response = await http.get(
      uri,
      headers: headers,
    );

    debugPrint(
      'Synkro unread HTTP : ${response.statusCode}',
    );

    final data = _decodeResponse(response);

    if (data == null || data['success'] != true) {
      return 0;
    }

    final rawConversations =
        data['conversations'] ??
        data['data'] ??
        [];

    if (rawConversations is! List) {
      return 0;
    }

    int total = 0;

    for (final item in rawConversations) {
      if (item is! Map) {
        continue;
      }

      final rawCount =
          item['unread_count'] ??
          item['unread_messages'] ??
          0;

      if (rawCount is int) {
        total += rawCount;
      } else {
        total += int.tryParse(
              rawCount.toString(),
            ) ??
            0;
      }
    }

    return total;
  } catch (error, stackTrace) {
    debugPrint(
      'Erreur getTotalUnreadCount : $error',
    );

    debugPrint(
      'StackTrace getTotalUnreadCount : '
      '$stackTrace',
    );

    return 0;
  }
}

  /*
  |--------------------------------------------------------------------------
  | Décodage commun des réponses
  |--------------------------------------------------------------------------
  */

  static Map<String, dynamic>? _decodeResponse(
    http.Response response,
  ) {
    try {
      final rawBody = response.body.trim();

      if (rawBody.isEmpty) {
        lastErrorMessage =
            'Le serveur a renvoyé une réponse vide.';

        return null;
      }

      final dynamic decoded = jsonDecode(rawBody);

      if (decoded is! Map) {
        lastErrorMessage =
            'Réponse invalide du serveur.';

        return null;
      }

      final data = Map<String, dynamic>.from(
        decoded,
      );

      if (
        response.statusCode < 200 ||
        response.statusCode >= 300
      ) {
        lastErrorMessage =
            data['message']?.toString().trim().isNotEmpty ==
                    true
                ? data['message'].toString()
                : 'Erreur serveur '
                    '(${response.statusCode}).';

        return null;
      }

      if (data['success'] != true) {
        lastErrorMessage =
            data['message']?.toString().trim().isNotEmpty ==
                    true
                ? data['message'].toString()
                : 'L’opération a échoué.';

        return null;
      }

      return data;
    } on FormatException catch (error) {
      debugPrint(
        'Erreur JSON Synkro : $error',
      );

      debugPrint(
        'Réponse brute Synkro : '
        '${response.body}',
      );

      lastErrorMessage =
          'Réponse JSON invalide du serveur.';

      return null;
    } catch (error, stackTrace) {
      debugPrint(
        'Erreur décodage Synkro : $error',
      );

      debugPrint(
        'StackTrace décodage Synkro : '
        '$stackTrace',
      );

      lastErrorMessage =
          'Impossible de lire la réponse du serveur.';

      return null;
    }
  }
}