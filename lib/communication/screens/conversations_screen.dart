import 'dart:async';

import 'package:flutter/cupertino.dart';

import '../../core/theme/app_colors.dart';
import 'conversation_screen.dart';
import '../../core/services/communication_events.dart';
import '../../core/services/communication_service.dart';

class ConversationsScreen
    extends StatefulWidget {
  final Future<void> Function()?
      onUnreadChanged;

  const ConversationsScreen({
    super.key,
    this.onUnreadChanged,
  });

  @override
  State<ConversationsScreen> createState() =>
      _ConversationsScreenState();
}

class _ConversationsScreenState
    extends State<ConversationsScreen> {
  final TextEditingController _searchController =
      TextEditingController();

  final ScrollController _scrollController = ScrollController();

  final List<Map<String, dynamic>> _conversations = [];

  Timer? _searchTimer;
  Timer? _refreshTimer;

  StreamSubscription<void>? _newMessageSubscription;

  bool _isLoading = true;
  bool _isLoadingMore = false;
  bool _hasMore = true;

  int _currentPage = 1;

  String _searchQuery = '';
  String? _errorMessage;

  static const int _perPage = 20;

@override
void initState() {
  super.initState();

  _scrollController.addListener(_handleScroll);

  _loadConversations(reset: true);

  _newMessageSubscription =
      CommunicationEvents.onNewMessage.listen(
    (_) async {
      debugPrint(
        'Événement nouveau message reçu '
        'dans ConversationsScreen.',
      );

      await _refreshConversationsSilently();
    },
  );

  /*
   * Sécurité temporaire :
   * recharge toutes les 10 secondes si Firebase
   * ne fonctionne pas encore sur le Web.
   */
  _refreshTimer = Timer.periodic(
    const Duration(seconds: 10),
    (_) {
      _refreshConversationsSilently();
    },
  );
}

@override
void dispose() {
  _searchTimer?.cancel();
  _refreshTimer?.cancel();
  _newMessageSubscription?.cancel();

  _searchController.dispose();

  _scrollController
    ..removeListener(_handleScroll)
    ..dispose();

  super.dispose();
}

  void _handleScroll() {
    if (!_scrollController.hasClients) {
      return;
    }

    final position = _scrollController.position;

    if (position.pixels >= position.maxScrollExtent - 250) {
      _loadMore();
    }
  }

  void _onSearchChanged(String value) {
    _searchTimer?.cancel();

    _searchTimer = Timer(
      const Duration(milliseconds: 450),
      () {
        final query = value.trim();

        if (query == _searchQuery) {
          return;
        }

        _searchQuery = query;
        _loadConversations(reset: true);
      },
    );
  }

Future<void> _refreshConversationsSilently() async {
  if (_isLoading || _isLoadingMore) {
    return;
  }

  Map<String, dynamic>? response;

  if (_searchQuery.isEmpty) {
    response = await CommunicationService.getConversations(
      page: 1,
      perPage: _perPage,
    );
  } else {
    response = await CommunicationService.searchConversations(
      query: _searchQuery,
      page: 1,
      perPage: _perPage,
    );
  }

  if (!mounted || response == null) {
    return;
  }

  final validResponse = response;

  final newConversations =
      _extractConversations(validResponse);

  setState(() {
    _conversations
      ..clear()
      ..addAll(newConversations);

    _currentPage = 1;

    _hasMore = _extractHasMore(
      validResponse,
      receivedCount: newConversations.length,
    );

    _errorMessage = null;
  });

  await widget.onUnreadChanged?.call();
}

  Future<void> _loadMore() async {
    if (_isLoading ||
        _isLoadingMore ||
        !_hasMore) {
      return;
    }

    await _loadConversations(reset: false);
  }

  Future<void> _loadConversations({
    required bool reset,
  }) async {
    if (reset) {
      setState(() {
        _isLoading = true;
        _isLoadingMore = false;
        _currentPage = 1;
        _hasMore = true;
        _errorMessage = null;
      });
    } else {
      setState(() {
        _isLoadingMore = true;
      });
    }

    final requestedPage = reset ? 1 : _currentPage + 1;

    Map<String, dynamic>? response;

    if (_searchQuery.isEmpty) {
      response = await CommunicationService.getConversations(
        page: requestedPage,
        perPage: _perPage,
      );
    } else {
      response =
          await CommunicationService.searchConversations(
        query: _searchQuery,
        page: requestedPage,
        perPage: _perPage,
      );
    }

    if (!mounted) {
      return;
    }

if (response == null) {
  setState(() {
    _isLoading = false;
    _isLoadingMore = false;
    _errorMessage =
        CommunicationService.lastErrorMessage ??
        'Impossible de charger les conversations.';
  });

  return;
}

final Map<String, dynamic> validResponse = response;

final newConversations =
    _extractConversations(validResponse);

setState(() {
  if (reset) {
    _conversations
      ..clear()
      ..addAll(newConversations);
  } else {
    final existingIds = _conversations
        .map(_conversationId)
        .where((id) => id > 0)
        .toSet();

    for (final conversation in newConversations) {
      final id = _conversationId(conversation);

      if (id <= 0 || !existingIds.contains(id)) {
        _conversations.add(conversation);
        existingIds.add(id);
      }
    }
  }

  _currentPage = requestedPage;

  _hasMore = _extractHasMore(
    validResponse,
    receivedCount: newConversations.length,
  );

  _isLoading = false;
  _isLoadingMore = false;
  _errorMessage = null;
});
  }

  List<Map<String, dynamic>> _extractConversations(
    Map<String, dynamic> response,
  ) {
    dynamic rawList;

    if (response['conversations'] is List) {
      rawList = response['conversations'];
    } else if (response['items'] is List) {
      rawList = response['items'];
    } else if (response['data'] is List) {
      rawList = response['data'];
    } else if (response['data'] is Map) {
      final data = Map<String, dynamic>.from(
        response['data'] as Map,
      );

      if (data['conversations'] is List) {
        rawList = data['conversations'];
      } else if (data['items'] is List) {
        rawList = data['items'];
      } else if (data['data'] is List) {
        rawList = data['data'];
      }
    }

    if (rawList is! List) {
      return [];
    }

    return rawList
        .whereType<Map>()
        .map(
          (item) => Map<String, dynamic>.from(item),
        )
        .toList();
  }

  bool _extractHasMore(
    Map<String, dynamic> response, {
    required int receivedCount,
  }) {
    final directHasMore = response['has_more'];

    if (directHasMore is bool) {
      return directHasMore;
    }

    if (response['pagination'] is Map) {
      final pagination = Map<String, dynamic>.from(
        response['pagination'] as Map,
      );

      if (pagination['has_more'] is bool) {
        return pagination['has_more'] as bool;
      }

      final currentPage = _toInt(
        pagination['current_page'] ??
            pagination['page'],
      );

      final lastPage = _toInt(
        pagination['last_page'] ??
            pagination['total_pages'],
      );

      if (currentPage > 0 && lastPage > 0) {
        return currentPage < lastPage;
      }
    }

    if (response['data'] is Map) {
      final data = Map<String, dynamic>.from(
        response['data'] as Map,
      );

      if (data['has_more'] is bool) {
        return data['has_more'] as bool;
      }

      if (data['pagination'] is Map) {
        final pagination = Map<String, dynamic>.from(
          data['pagination'] as Map,
        );

        if (pagination['has_more'] is bool) {
          return pagination['has_more'] as bool;
        }
      }
    }

    return receivedCount >= _perPage;
  }

  int _conversationId(Map<String, dynamic> conversation) {
    return _toInt(
      conversation['id'] ??
          conversation['conversation_id'],
    );
  }

  int _toInt(dynamic value) {
    if (value is int) {
      return value;
    }

    return int.tryParse(value?.toString() ?? '') ?? 0;
  }

  String _conversationTitle(
    Map<String, dynamic> conversation,
  ) {
    final candidates = [
      conversation['contact_name'],
      conversation['name'],
      conversation['title'],
      conversation['display_name'],
      conversation['recipient_name'],
      conversation['phone'],
      conversation['email'],
    ];

    for (final candidate in candidates) {
      final value = candidate?.toString().trim() ?? '';

      if (value.isNotEmpty) {
        return value;
      }
    }

    return 'Conversation';
  }

  String _conversationPreview(
    Map<String, dynamic> conversation,
  ) {
    final candidates = [
      conversation['last_message'],
      conversation['message'],
      conversation['preview'],
      conversation['last_message_text'],
      conversation['subject'],
    ];

    for (final candidate in candidates) {
      if (candidate is Map) {
        final map = Map<String, dynamic>.from(candidate);

        final nestedValue =
            map['message'] ??
            map['content'] ??
            map['text'] ??
            map['body'];

        final value =
            nestedValue?.toString().trim() ?? '';

        if (value.isNotEmpty) {
          return value;
        }
      }

      final value = candidate?.toString().trim() ?? '';

      if (value.isNotEmpty) {
        return value;
      }
    }

    return 'Aucun message';
  }

  int _unreadCount(
    Map<String, dynamic> conversation,
  ) {
    return _toInt(
      conversation['unread_count'] ??
          conversation['unread'] ??
          conversation['unread_messages'],
    );
  }

  String _channel(
    Map<String, dynamic> conversation,
  ) {
    return (
      conversation['channel'] ??
      conversation['type'] ??
      conversation['source'] ??
      'message'
    )
        .toString()
        .trim()
        .toLowerCase();
  }

  DateTime? _conversationDate(
    Map<String, dynamic> conversation,
  ) {
    final candidates = [
      conversation['last_message_at'],
      conversation['updated_at'],
      conversation['created_at'],
      conversation['date'],
    ];

    for (final candidate in candidates) {
      final parsed = _parseDate(candidate);

      if (parsed != null) {
        return parsed;
      }
    }

    return null;
  }

  DateTime? _parseDate(dynamic value) {
    final raw = value?.toString().trim() ?? '';

    if (raw.isEmpty) {
      return null;
    }

    final normalized = raw.contains('T')
        ? raw
        : raw.replaceFirst(' ', 'T');

    return DateTime.tryParse(normalized);
  }

  String _formatConversationDate(DateTime? date) {
    if (date == null) {
      return '';
    }

    final localDate = date.toLocal();
    final now = DateTime.now();

    final today = DateTime(
      now.year,
      now.month,
      now.day,
    );

    final messageDay = DateTime(
      localDate.year,
      localDate.month,
      localDate.day,
    );

    final difference = today.difference(
      messageDay,
    ).inDays;

    if (difference == 0) {
      return _formatHour(localDate);
    }

    if (difference == 1) {
      return 'Hier';
    }

    if (localDate.year == now.year) {
      return '${_twoDigits(localDate.day)}/'
          '${_twoDigits(localDate.month)}';
    }

    return '${_twoDigits(localDate.day)}/'
        '${_twoDigits(localDate.month)}/'
        '${localDate.year}';
  }

  String _formatHour(DateTime date) {
    return '${_twoDigits(date.hour)}:'
        '${_twoDigits(date.minute)}';
  }

  String _twoDigits(int value) {
    return value.toString().padLeft(2, '0');
  }

  IconData _channelIcon(String channel) {
    switch (channel) {
      case 'whatsapp':
        return CupertinoIcons.chat_bubble_2_fill;

      case 'sms':
        return CupertinoIcons.text_bubble_fill;

      case 'email':
      case 'mail':
        return CupertinoIcons.mail_solid;

      case 'phone':
        return CupertinoIcons.phone_fill;

      case 'push':
      case 'notification':
        return CupertinoIcons.bell_fill;

      default:
        return CupertinoIcons.chat_bubble_fill;
    }
  }

Future<void> _openConversation(
  Map<String, dynamic> conversation,
) async {
  final conversationId =
      _conversationId(conversation);

  if (conversationId <= 0) {
    await _showError(
      'Cette conversation ne possède pas '
      'd’identifiant valide.',
    );

    return;
  }

  // Marque la conversation comme lue
  final marked =
      await CommunicationService.markConversationRead(
    conversationId: conversationId,
  );

  if (marked) {
    // Met à jour le badge de la navbar
    await widget.onUnreadChanged?.call();
  }

  if (!mounted) {
    return;
  }

  await Navigator.of(context).push(
    CupertinoPageRoute<void>(
builder: (_) => ConversationScreen(
  conversationId: conversationId,
  title: _conversationTitle(conversation),
  channel: _channel(conversation),
  onUnreadChanged: widget.onUnreadChanged,
),
    ),
  );

  if (!mounted) {
    return;
  }

  // Recharge la liste des conversations
  await _loadConversations(reset: true);

  // Met à jour à nouveau le badge au retour
  await widget.onUnreadChanged?.call();
}

  Future<void> _showError(String message) async {
    await showCupertinoDialog<void>(
      context: context,
      builder: (dialogContext) {
        return CupertinoAlertDialog(
          title: const Text('Messagerie'),
          content: Padding(
            padding: const EdgeInsets.only(top: 8),
            child: Text(message),
          ),
          actions: [
            CupertinoDialogAction(
              onPressed: () {
                Navigator.of(dialogContext).pop();
              },
              child: const Text('Fermer'),
            ),
          ],
        );
      },
    );
  }

  Widget _buildConversationTile(
    Map<String, dynamic> conversation,
  ) {
    final title = _conversationTitle(conversation);
    final preview = _conversationPreview(conversation);
    final unreadCount = _unreadCount(conversation);
    final channel = _channel(conversation);

    final date = _formatConversationDate(
      _conversationDate(conversation),
    );

    return CupertinoButton(
      padding: EdgeInsets.zero,
      onPressed: () => _openConversation(conversation),
      child: Container(
        padding: const EdgeInsets.symmetric(
          horizontal: 16,
          vertical: 13,
        ),
        decoration: BoxDecoration(
          color: CupertinoColors.systemBackground
              .resolveFrom(context),
          border: Border(
            bottom: BorderSide(
              color: CupertinoColors.separator
                  .resolveFrom(context)
                  .withOpacity(0.35),
              width: 0.5,
            ),
          ),
        ),
        child: Row(
          children: [
            _buildAvatar(
              title: title,
              channel: channel,
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment:
                    CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Expanded(
                        child: Text(
                          title,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: TextStyle(
                            color: CupertinoColors.label
                                .resolveFrom(context),
                            fontSize: 16,
                            fontWeight: unreadCount > 0
                                ? FontWeight.w700
                                : FontWeight.w600,
                          ),
                        ),
                      ),
                      if (date.isNotEmpty) ...[
                        const SizedBox(width: 8),
                        Text(
                          date,
                          style: TextStyle(
                            color: unreadCount > 0
                                ? AppColors.primary
                                : CupertinoColors
                                    .secondaryLabel
                                    .resolveFrom(context),
                            fontSize: 12,
                            fontWeight: unreadCount > 0
                                ? FontWeight.w700
                                : FontWeight.w400,
                          ),
                        ),
                      ],
                    ],
                  ),
                  const SizedBox(height: 5),
                  Row(
                    children: [
                      Expanded(
                        child: Text(
                          preview,
                          maxLines: 2,
                          overflow: TextOverflow.ellipsis,
                          style: TextStyle(
                            color: CupertinoColors
                                .secondaryLabel
                                .resolveFrom(context),
                            fontSize: 14,
                            height: 1.25,
                            fontWeight: unreadCount > 0
                                ? FontWeight.w600
                                : FontWeight.w400,
                          ),
                        ),
                      ),
                      if (unreadCount > 0) ...[
                        const SizedBox(width: 10),
                        Container(
                          constraints: const BoxConstraints(
                            minWidth: 22,
                            minHeight: 22,
                          ),
                          padding: const EdgeInsets.symmetric(
                            horizontal: 7,
                            vertical: 3,
                          ),
                          decoration: BoxDecoration(
                            color: AppColors.primary,
                            borderRadius:
                                BorderRadius.circular(20),
                          ),
                          alignment: Alignment.center,
                          child: Text(
                            unreadCount > 99
                                ? '99+'
                                : unreadCount.toString(),
                            style: const TextStyle(
                              color: CupertinoColors.white,
                              fontSize: 11,
                              fontWeight: FontWeight.w800,
                            ),
                          ),
                        ),
                      ],
                    ],
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildAvatar({
    required String title,
    required String channel,
  }) {
    final initials = title
        .split(RegExp(r'\s+'))
        .where((part) => part.isNotEmpty)
        .take(2)
        .map((part) => part.substring(0, 1).toUpperCase())
        .join();

    return Stack(
      clipBehavior: Clip.none,
      children: [
        Container(
          width: 52,
          height: 52,
          alignment: Alignment.center,
          decoration: BoxDecoration(
            color: AppColors.primary.withOpacity(0.12),
            shape: BoxShape.circle,
          ),
          child: Text(
            initials.isEmpty ? '?' : initials,
            style: const TextStyle(
              color: AppColors.primary,
              fontSize: 17,
              fontWeight: FontWeight.w800,
            ),
          ),
        ),
        Positioned(
          right: -2,
          bottom: -2,
          child: Container(
            width: 21,
            height: 21,
            decoration: BoxDecoration(
              color: CupertinoColors.systemBackground
                  .resolveFrom(context),
              shape: BoxShape.circle,
              border: Border.all(
                color: CupertinoColors.systemBackground
                    .resolveFrom(context),
                width: 2,
              ),
            ),
            child: Icon(
              _channelIcon(channel),
              color: AppColors.primary,
              size: 16,
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildEmptyState() {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(30),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              width: 76,
              height: 76,
              decoration: BoxDecoration(
                color: AppColors.primary.withOpacity(0.10),
                shape: BoxShape.circle,
              ),
              child: const Icon(
                CupertinoIcons.chat_bubble_2,
                color: AppColors.primary,
                size: 36,
              ),
            ),
            const SizedBox(height: 18),
            Text(
              _searchQuery.isEmpty
                  ? 'Aucune conversation'
                  : 'Aucun résultat',
              style: TextStyle(
                color: CupertinoColors.label
                    .resolveFrom(context),
                fontSize: 19,
                fontWeight: FontWeight.w700,
              ),
            ),
            const SizedBox(height: 7),
            Text(
              _searchQuery.isEmpty
                  ? 'Les conversations Synkro '
                      'apparaîtront ici.'
                  : 'Aucune conversation ne correspond '
                      'à votre recherche.',
              textAlign: TextAlign.center,
              style: TextStyle(
                color: CupertinoColors.secondaryLabel
                    .resolveFrom(context),
                fontSize: 14,
                height: 1.35,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildErrorState() {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(28),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Icon(
              CupertinoIcons.exclamationmark_circle_fill,
              color: AppColors.danger,
              size: 46,
            ),
            const SizedBox(height: 15),
            Text(
              _errorMessage ??
                  'Une erreur est survenue.',
              textAlign: TextAlign.center,
              style: TextStyle(
                color: CupertinoColors.label
                    .resolveFrom(context),
                fontSize: 15,
                height: 1.35,
              ),
            ),
            const SizedBox(height: 18),
            CupertinoButton.filled(
              onPressed: () {
                _loadConversations(reset: true);
              },
              child: const Text('Réessayer'),
            ),
          ],
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return CupertinoPageScaffold(
      backgroundColor: AppColors.background,
      navigationBar: CupertinoNavigationBar(
        middle: const Text('Messages'),
        trailing: CupertinoButton(
          padding: EdgeInsets.zero,
          minSize: 32,
          onPressed: _isLoading
              ? null
              : () {
                  _loadConversations(reset: true);
                },
          child: const Icon(
            CupertinoIcons.refresh,
            size: 21,
          ),
        ),
      ),
      child: SafeArea(
        child: Column(
          children: [
            Padding(
              padding: const EdgeInsets.fromLTRB(
                14,
                12,
                14,
                10,
              ),
              child: CupertinoSearchTextField(
                controller: _searchController,
                placeholder:
                    'Rechercher un contact ou un message',
                onChanged: _onSearchChanged,
                onSuffixTap: () {
                  _searchController.clear();
                  _onSearchChanged('');
                },
              ),
            ),
            Expanded(
              child: _isLoading
                  ? const Center(
                      child: CupertinoActivityIndicator(
                        radius: 14,
                      ),
                    )
                  : _errorMessage != null &&
                          _conversations.isEmpty
                      ? _buildErrorState()
                      : _conversations.isEmpty
                          ? _buildEmptyState()
                          : CustomScrollView(
                              controller:
                                  _scrollController,
                              physics:
                                  const AlwaysScrollableScrollPhysics(),
                              slivers: [
                                CupertinoSliverRefreshControl(
                                  onRefresh: () =>
                                      _loadConversations(
                                    reset: true,
                                  ),
                                ),
                                SliverList(
                                  delegate:
                                      SliverChildBuilderDelegate(
                                    (context, index) {
                                      return _buildConversationTile(
                                        _conversations[index],
                                      );
                                    },
                                    childCount:
                                        _conversations.length,
                                  ),
                                ),
                                SliverToBoxAdapter(
                                  child: AnimatedSwitcher(
                                    duration: const Duration(
                                      milliseconds: 200,
                                    ),
                                    child: _isLoadingMore
                                        ? const Padding(
                                            padding:
                                                EdgeInsets.all(
                                              20,
                                            ),
                                            child: Center(
                                              child:
                                                  CupertinoActivityIndicator(),
                                            ),
                                          )
                                        : const SizedBox(
                                            height: 20,
                                          ),
                                  ),
                                ),
                              ],
                            ),
            ),
          ],
        ),
      ),
    );
  }
}