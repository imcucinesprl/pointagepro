import 'dart:async';

import 'package:flutter/cupertino.dart';

import '../../core/services/communication_service.dart';
import '../../core/theme/app_colors.dart';
import '../widgets/chat_day_separator.dart';
import '../widgets/message_bubble.dart';
import '../widgets/message_input.dart';

class ConversationScreen extends StatefulWidget {
  final int conversationId;
  final String title;
  final String channel;

  final Future<void> Function()? onUnreadChanged;

  const ConversationScreen({
    super.key,
    required this.conversationId,
    required this.title,
    this.channel = 'message',
    this.onUnreadChanged,
  });

  @override
  State<ConversationScreen> createState() =>
      _ConversationScreenState();
}

class _ConversationScreenState
    extends State<ConversationScreen> {
  final ScrollController _scrollController =
      ScrollController();

  final List<Map<String, dynamic>> _messages = [];

  Timer? _refreshTimer;

  bool _isLoading = true;
  bool _isLoadingOlder = false;
  bool _isSending = false;
  bool _hasMore = true;

  int _currentPage = 1;

  String? _errorMessage;

  static const int _perPage = 50;

  @override
  void initState() {
    super.initState();

    _scrollController.addListener(_handleScroll);

    _loadInitialMessages();

    _refreshTimer = Timer.periodic(
      const Duration(seconds: 10),
      (_) => _refreshMessagesSilently(),
    );
  }

  @override
  void dispose() {
    _refreshTimer?.cancel();

    _scrollController
      ..removeListener(_handleScroll)
      ..dispose();

    super.dispose();
  }

  void _handleScroll() {
    if (!_scrollController.hasClients) {
      return;
    }

    if (_scrollController.position.pixels <= 140) {
      _loadOlderMessages();
    }
  }

  Future<void> _loadInitialMessages() async {
    setState(() {
      _isLoading = true;
      _errorMessage = null;
      _currentPage = 1;
      _hasMore = true;
    });

    final response =
        await CommunicationService.getMessages(
      conversationId: widget.conversationId,
      page: 1,
      perPage: _perPage,
    );

    if (!mounted) {
      return;
    }

    if (response == null) {
      setState(() {
        _isLoading = false;
        _errorMessage =
            CommunicationService.lastErrorMessage ??
            'Impossible de charger les messages.';
      });

      return;
    }

    final loadedMessages = _extractMessages(response);

    loadedMessages.sort(_compareMessages);

    setState(() {
      _messages
        ..clear()
        ..addAll(loadedMessages);

      _currentPage = 1;

      _hasMore = _extractHasMore(
        response,
        receivedCount: loadedMessages.length,
      );

      _isLoading = false;
      _errorMessage = null;
    });

    await CommunicationService.markConversationRead(
      conversationId: widget.conversationId,
    );

    await widget.onUnreadChanged?.call();

    _scrollToBottom(immediate: true);
  }

  Future<void> _refreshMessagesSilently() async {
    if (_isLoading || _isSending) {
      return;
    }

    final response =
        await CommunicationService.getMessages(
      conversationId: widget.conversationId,
      page: 1,
      perPage: _perPage,
    );

    if (!mounted || response == null) {
      return;
    }

    final loadedMessages = _extractMessages(response);

    if (loadedMessages.isEmpty) {
      return;
    }

    final wasNearBottom = _isNearBottom();

    final existingIds = _messages
        .map(_messageId)
        .where((id) => id > 0)
        .toSet();

    var added = false;

    for (final message in loadedMessages) {
      final id = _messageId(message);

      if (id <= 0 || !existingIds.contains(id)) {
        _messages.add(message);
        added = true;
      } else {
        final index = _messages.indexWhere(
          (existing) => _messageId(existing) == id,
        );

        if (index >= 0) {
          _messages[index] = message;
        }
      }
    }

    if (!added && mounted) {
      setState(() {});
      return;
    }

    _messages.sort(_compareMessages);

    setState(() {});

    await CommunicationService.markConversationRead(
      conversationId: widget.conversationId,
    );

    await widget.onUnreadChanged?.call();

    if (wasNearBottom) {
      _scrollToBottom();
    }
  }

  Future<void> _loadOlderMessages() async {
    if (_isLoading ||
        _isLoadingOlder ||
        !_hasMore) {
      return;
    }

    setState(() {
      _isLoadingOlder = true;
    });

    final oldMaxExtent = _scrollController.hasClients
        ? _scrollController.position.maxScrollExtent
        : 0.0;

    final nextPage = _currentPage + 1;

    final response =
        await CommunicationService.getMessages(
      conversationId: widget.conversationId,
      page: nextPage,
      perPage: _perPage,
    );

    if (!mounted) {
      return;
    }

    if (response == null) {
      setState(() {
        _isLoadingOlder = false;
      });

      return;
    }

    final olderMessages = _extractMessages(response);

    final existingIds = _messages
        .map(_messageId)
        .where((id) => id > 0)
        .toSet();

    for (final message in olderMessages) {
      final id = _messageId(message);

      if (id <= 0 || !existingIds.contains(id)) {
        _messages.add(message);
      }
    }

    _messages.sort(_compareMessages);

    setState(() {
      _currentPage = nextPage;

      _hasMore = _extractHasMore(
        response,
        receivedCount: olderMessages.length,
      );

      _isLoadingOlder = false;
    });

    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted ||
          !_scrollController.hasClients) {
        return;
      }

      final newMaxExtent =
          _scrollController.position.maxScrollExtent;

      final difference = newMaxExtent - oldMaxExtent;

      if (difference > 0) {
        _scrollController.jumpTo(difference);
      }
    });
  }

  Future<bool> _sendMessage(String text) async {
    if (_isSending) {
      return false;
    }

    setState(() {
      _isSending = true;
    });

    final response =
        await CommunicationService.sendMessage(
      conversationId: widget.conversationId,
      message: text,
    );

    if (!mounted) {
      return false;
    }

    setState(() {
      _isSending = false;
    });

    if (response == null) {
      await _showError(
        CommunicationService.lastErrorMessage ??
            'Impossible d’envoyer le message.',
      );

      return false;
    }

    final sentMessage = _extractSentMessage(response);

    if (sentMessage != null) {
      final sentId = _messageId(sentMessage);

      final exists = sentId > 0 &&
          _messages.any(
            (message) => _messageId(message) == sentId,
          );

      if (!exists) {
        setState(() {
          _messages.add(sentMessage);
          _messages.sort(_compareMessages);
        });
      }
    } else {
      await _refreshMessagesSilently();
    }

    _scrollToBottom();

    return true;
  }

  List<Map<String, dynamic>> _extractMessages(
    Map<String, dynamic> response,
  ) {
    dynamic rawList;

    if (response['messages'] is List) {
      rawList = response['messages'];
    } else if (response['items'] is List) {
      rawList = response['items'];
    } else if (response['data'] is List) {
      rawList = response['data'];
    } else if (response['data'] is Map) {
      final data = Map<String, dynamic>.from(
        response['data'] as Map,
      );

      if (data['messages'] is List) {
        rawList = data['messages'];
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

  Map<String, dynamic>? _extractSentMessage(
    Map<String, dynamic> response,
  ) {
    final candidates = [
      response['message'],
      response['data'],
      response['sent_message'],
    ];

    for (final candidate in candidates) {
      if (candidate is Map) {
        final map = Map<String, dynamic>.from(
          candidate,
        );

        if (map['message'] is Map) {
          return Map<String, dynamic>.from(
            map['message'] as Map,
          );
        }

        if (map.containsKey('id') ||
            map.containsKey('message_id') ||
            map.containsKey('content') ||
            map.containsKey('text')) {
          return map;
        }
      }
    }

    return null;
  }

  bool _extractHasMore(
    Map<String, dynamic> response, {
    required int receivedCount,
  }) {
    if (response['has_more'] is bool) {
      return response['has_more'] as bool;
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
    }

    return receivedCount >= _perPage;
  }

  int _messageId(Map<String, dynamic> message) {
    return _toInt(
      message['id'] ?? message['message_id'],
    );
  }

  int _toInt(dynamic value) {
    if (value is int) {
      return value;
    }

    return int.tryParse(value?.toString() ?? '') ?? 0;
  }

  DateTime? _messageDate(
    Map<String, dynamic> message,
  ) {
    final candidates = [
      message['created_at'],
      message['sent_at'],
      message['date'],
      message['timestamp'],
      message['updated_at'],
    ];

    for (final candidate in candidates) {
      final raw = candidate?.toString().trim() ?? '';

      if (raw.isEmpty) {
        continue;
      }

      final normalized = raw.contains('T')
          ? raw
          : raw.replaceFirst(' ', 'T');

      final parsed = DateTime.tryParse(normalized);

      if (parsed != null) {
        return parsed.toLocal();
      }
    }

    return null;
  }

  int _compareMessages(
    Map<String, dynamic> first,
    Map<String, dynamic> second,
  ) {
    final firstDate = _messageDate(first);
    final secondDate = _messageDate(second);

    if (firstDate != null && secondDate != null) {
      return firstDate.compareTo(secondDate);
    }

    return _messageId(first).compareTo(
      _messageId(second),
    );
  }

  bool _shouldShowDaySeparator(int index) {
    if (index == 0) {
      return true;
    }

    final currentDate = _messageDate(
      _messages[index],
    );

    final previousDate = _messageDate(
      _messages[index - 1],
    );

    if (currentDate == null ||
        previousDate == null) {
      return false;
    }

    return currentDate.year != previousDate.year ||
        currentDate.month != previousDate.month ||
        currentDate.day != previousDate.day;
  }

  bool _isNearBottom() {
    if (!_scrollController.hasClients) {
      return true;
    }

    final position = _scrollController.position;

    return position.maxScrollExtent -
            position.pixels <
        180;
  }

  void _scrollToBottom({
    bool immediate = false,
  }) {
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted ||
          !_scrollController.hasClients) {
        return;
      }

      final target =
          _scrollController.position.maxScrollExtent;

      if (immediate) {
        _scrollController.jumpTo(target);
      } else {
        _scrollController.animateTo(
          target,
          duration: const Duration(milliseconds: 280),
          curve: Curves.easeOut,
        );
      }
    });
  }

  Future<void> _showMessageDetails(
    Map<String, dynamic> message,
  ) async {
    await showCupertinoModalPopup<void>(
      context: context,
      builder: (popupContext) {
        final date = _messageDate(message);

        return CupertinoActionSheet(
          title: const Text('Détails du message'),
          message: Text(
            date == null
                ? 'Date inconnue'
                : '${_twoDigits(date.day)}/'
                    '${_twoDigits(date.month)}/'
                    '${date.year} à '
                    '${_twoDigits(date.hour)}:'
                    '${_twoDigits(date.minute)}:'
                    '${_twoDigits(date.second)}',
          ),
          actions: [
            CupertinoActionSheetAction(
              onPressed: () {
                Navigator.of(popupContext).pop();
              },
              child: const Text('Fermer'),
            ),
          ],
          cancelButton: CupertinoActionSheetAction(
            onPressed: () {
              Navigator.of(popupContext).pop();
            },
            child: const Text('Annuler'),
          ),
        );
      },
    );
  }

  Future<void> _showError(String message) async {
    await showCupertinoDialog<void>(
      context: context,
      builder: (dialogContext) {
        return CupertinoAlertDialog(
          title: const Text('Erreur'),
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

  String _twoDigits(int value) {
    return value.toString().padLeft(2, '0');
  }

  Widget _buildMessagesList() {
    if (_messages.isEmpty) {
      return Center(
        child: Padding(
          padding: const EdgeInsets.all(30),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Icon(
                CupertinoIcons.chat_bubble_2,
                color: AppColors.primary,
                size: 42,
              ),
              const SizedBox(height: 14),
              Text(
                'Aucun message',
                style: TextStyle(
                  color: CupertinoColors.label
                      .resolveFrom(context),
                  fontSize: 18,
                  fontWeight: FontWeight.w700,
                ),
              ),
              const SizedBox(height: 6),
              Text(
                'Envoyez le premier message '
                'de cette conversation.',
                textAlign: TextAlign.center,
                style: TextStyle(
                  color: CupertinoColors.secondaryLabel
                      .resolveFrom(context),
                  fontSize: 14,
                ),
              ),
            ],
          ),
        ),
      );
    }

    return ListView.builder(
      controller: _scrollController,
      physics: const AlwaysScrollableScrollPhysics(),
      padding: const EdgeInsets.fromLTRB(
        12,
        10,
        12,
        18,
      ),
      itemCount:
          _messages.length + (_isLoadingOlder ? 1 : 0),
      itemBuilder: (context, index) {
        if (_isLoadingOlder && index == 0) {
          return const Padding(
            padding: EdgeInsets.symmetric(vertical: 12),
            child: Center(
              child: CupertinoActivityIndicator(),
            ),
          );
        }

        final messageIndex =
            _isLoadingOlder ? index - 1 : index;

        final message = _messages[messageIndex];

        return Column(
          children: [
            if (_shouldShowDaySeparator(messageIndex))
              ChatDaySeparator(
                date: _messageDate(message),
              ),
            MessageBubble(
              message: message,
              onLongPress: () {
                _showMessageDetails(message);
              },
            ),
          ],
        );
      },
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
              size: 44,
            ),
            const SizedBox(height: 14),
            Text(
              _errorMessage ??
                  'Impossible de charger la conversation.',
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
              onPressed: _loadInitialMessages,
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
        middle: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(
              widget.title,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
            ),
            Text(
              widget.channel.toUpperCase(),
              style: TextStyle(
                color: CupertinoColors.secondaryLabel
                    .resolveFrom(context),
                fontSize: 10,
                fontWeight: FontWeight.w500,
              ),
            ),
          ],
        ),
        trailing: CupertinoButton(
          padding: EdgeInsets.zero,
          minSize: 32,
          onPressed: _refreshMessagesSilently,
          child: const Icon(
            CupertinoIcons.refresh,
            size: 20,
          ),
        ),
      ),
      child: SafeArea(
        child: Column(
          children: [
            Expanded(
              child: _isLoading
                  ? const Center(
                      child: CupertinoActivityIndicator(
                        radius: 14,
                      ),
                    )
                  : _errorMessage != null &&
                          _messages.isEmpty
                      ? _buildErrorState()
                      : _buildMessagesList(),
            ),
            MessageInput(
              isSending: _isSending,
              onSend: _sendMessage,
              onAttachmentPressed: () async {
                await _showError(
                  'L’envoi de pièces jointes '
                  'sera ajouté dans une prochaine étape.',
                );
              },
            ),
          ],
        ),
      ),
    );
  }
}