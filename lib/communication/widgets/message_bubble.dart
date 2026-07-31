import 'package:flutter/cupertino.dart';

import '../../core/theme/app_colors.dart';

class MessageBubble extends StatelessWidget {
  final Map<String, dynamic> message;
  final VoidCallback? onLongPress;

  const MessageBubble({
    super.key,
    required this.message,
    this.onLongPress,
  });

  bool get _isOutgoing {
    final direction = (
      message['direction'] ??
      message['type'] ??
      message['message_direction'] ??
      ''
    )
        .toString()
        .trim()
        .toLowerCase();

    if ([
      'outgoing',
      'outbound',
      'sent',
      'send',
    ].contains(direction)) {
      return true;
    }

    if ([
      'incoming',
      'inbound',
      'received',
      'receive',
    ].contains(direction)) {
      return false;
    }

    final candidates = [
      message['is_outgoing'],
      message['outgoing'],
      message['sent_by_me'],
      message['from_me'],
      message['is_sender'],
    ];

    for (final candidate in candidates) {
      if (candidate is bool) {
        return candidate;
      }

      final value =
          candidate?.toString().trim().toLowerCase();

      if (value == '1' || value == 'true') {
        return true;
      }

      if (value == '0' || value == 'false') {
        return false;
      }
    }

    return false;
  }

  String get _content {
    final candidates = [
      message['message'],
      message['content'],
      message['text'],
      message['body'],
      message['caption'],
    ];

    for (final candidate in candidates) {
      if (candidate is String &&
          candidate.trim().isNotEmpty) {
        return candidate.trim();
      }

      if (candidate is Map) {
        final map = Map<String, dynamic>.from(candidate);

        final nested =
            map['message'] ??
            map['content'] ??
            map['text'] ??
            map['body'];

        final value = nested?.toString().trim() ?? '';

        if (value.isNotEmpty) {
          return value;
        }
      }
    }

    return '';
  }

  String get _messageType {
    return (
      message['message_type'] ??
      message['content_type'] ??
      message['media_type'] ??
      'text'
    )
        .toString()
        .trim()
        .toLowerCase();
  }

  DateTime? get _createdAt {
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

  String get _status {
    return (
      message['status'] ??
      message['delivery_status'] ??
      message['message_status'] ??
      ''
    )
        .toString()
        .trim()
        .toLowerCase();
  }

  String _formatHour(DateTime? date) {
    if (date == null) {
      return '';
    }

    return '${date.hour.toString().padLeft(2, '0')}:'
        '${date.minute.toString().padLeft(2, '0')}';
  }

  String _statusSymbol() {
    switch (_status) {
      case 'pending':
      case 'queued':
      case 'sending':
        return '◷';

      case 'sent':
        return '✓';

      case 'delivered':
        return '✓✓';

      case 'read':
      case 'seen':
        return '✓✓';

      case 'failed':
      case 'error':
      case 'undelivered':
        return '!';

      default:
        return '';
    }
  }

  Color _statusColor(BuildContext context) {
    switch (_status) {
      case 'read':
      case 'seen':
        return CupertinoColors.activeBlue;

      case 'failed':
      case 'error':
      case 'undelivered':
        return CupertinoColors.systemRed;

      default:
        return _isOutgoing
            ? CupertinoColors.white.withOpacity(0.80)
            : CupertinoColors.secondaryLabel
                .resolveFrom(context);
    }
  }

  Widget _buildSpecialContent(BuildContext context) {
    switch (_messageType) {
      case 'image':
      case 'photo':
        return const _AttachmentPreview(
          icon: CupertinoIcons.photo_fill,
          label: 'Image',
        );

      case 'document':
      case 'file':
      case 'pdf':
        return const _AttachmentPreview(
          icon: CupertinoIcons.doc_fill,
          label: 'Document',
        );

      case 'audio':
      case 'voice':
        return const _AttachmentPreview(
          icon: CupertinoIcons.waveform,
          label: 'Message audio',
        );

      case 'location':
        return const _AttachmentPreview(
          icon: CupertinoIcons.location_fill,
          label: 'Position',
        );

      default:
        return const SizedBox.shrink();
    }
  }

  @override
  Widget build(BuildContext context) {
    final outgoing = _isOutgoing;
    final content = _content;
    final time = _formatHour(_createdAt);
    final status = _statusSymbol();

    final bubbleColor = outgoing
        ? AppColors.primary
        : CupertinoColors.systemGrey6.resolveFrom(context);

    final textColor = outgoing
        ? CupertinoColors.white
        : CupertinoColors.label.resolveFrom(context);

    return GestureDetector(
      onLongPress: onLongPress,
      child: Align(
        alignment: outgoing
            ? Alignment.centerRight
            : Alignment.centerLeft,
        child: Container(
          constraints: BoxConstraints(
            maxWidth:
                MediaQuery.sizeOf(context).width * 0.78,
          ),
          margin: EdgeInsets.only(
            top: 3,
            bottom: 3,
            left: outgoing ? 48 : 0,
            right: outgoing ? 0 : 48,
          ),
          padding: const EdgeInsets.fromLTRB(
            13,
            9,
            11,
            7,
          ),
          decoration: BoxDecoration(
            color: bubbleColor,
            borderRadius: BorderRadius.only(
              topLeft: const Radius.circular(18),
              topRight: const Radius.circular(18),
              bottomLeft: Radius.circular(
                outgoing ? 18 : 5,
              ),
              bottomRight: Radius.circular(
                outgoing ? 5 : 18,
              ),
            ),
            boxShadow: [
              BoxShadow(
                color: CupertinoColors.black.withOpacity(
                  0.035,
                ),
                blurRadius: 6,
                offset: const Offset(0, 2),
              ),
            ],
          ),
          child: Column(
            crossAxisAlignment:
                CrossAxisAlignment.start,
            children: [
              if (_messageType != 'text')
                _buildSpecialContent(context),
              if (_messageType != 'text' &&
                  content.isNotEmpty)
                const SizedBox(height: 7),
              if (content.isNotEmpty)
                Text(
                  content,
                  style: TextStyle(
                    color: textColor,
                    fontSize: 15,
                    height: 1.28,
                  ),
                ),
              const SizedBox(height: 4),
              Row(
                mainAxisSize: MainAxisSize.min,
                mainAxisAlignment:
                    MainAxisAlignment.end,
                children: [
                  if (time.isNotEmpty)
                    Text(
                      time,
                      style: TextStyle(
                        color: outgoing
                            ? CupertinoColors.white
                                .withOpacity(0.72)
                            : CupertinoColors
                                .secondaryLabel
                                .resolveFrom(context),
                        fontSize: 10,
                      ),
                    ),
                  if (outgoing &&
                      status.isNotEmpty) ...[
                    const SizedBox(width: 4),
                    Text(
                      status,
                      style: TextStyle(
                        color: _statusColor(context),
                        fontSize: 11,
                        fontWeight: FontWeight.w800,
                        letterSpacing: -2,
                      ),
                    ),
                  ],
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _AttachmentPreview extends StatelessWidget {
  final IconData icon;
  final String label;

  const _AttachmentPreview({
    required this.icon,
    required this.label,
  });

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Icon(
          icon,
          color: CupertinoColors.secondaryLabel
              .resolveFrom(context),
          size: 22,
        ),
        const SizedBox(width: 8),
        Flexible(
          child: Text(
            label,
            style: TextStyle(
              color: CupertinoColors.secondaryLabel
                  .resolveFrom(context),
              fontSize: 13,
              fontWeight: FontWeight.w600,
            ),
          ),
        ),
      ],
    );
  }
}