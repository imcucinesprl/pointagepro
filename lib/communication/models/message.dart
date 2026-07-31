class CommunicationMessage {
  final int id;
  final int conversationId;
  final int companyId;
  final String channel;
  final String direction;
  final String messageType;
  final String message;
  final String providerMessageId;
  final String providerReplyToId;
  final String status;
  final String errorCode;
  final String errorMessage;
  final DateTime? sentAt;
  final DateTime? deliveredAt;
  final DateTime? readAt;
  final DateTime? failedAt;
  final DateTime? createdAt;
  final DateTime? updatedAt;

  const CommunicationMessage({
    required this.id,
    required this.conversationId,
    required this.companyId,
    required this.channel,
    required this.direction,
    required this.messageType,
    required this.message,
    required this.providerMessageId,
    required this.providerReplyToId,
    required this.status,
    required this.errorCode,
    required this.errorMessage,
    required this.sentAt,
    required this.deliveredAt,
    required this.readAt,
    required this.failedAt,
    required this.createdAt,
    required this.updatedAt,
  });

  bool get isOutgoing => direction == 'outgoing';

  bool get isIncoming => direction == 'incoming';

  bool get isFailed => status == 'failed';

  bool get isRead => readAt != null || status == 'read';

  bool get isDelivered =>
      deliveredAt != null ||
      status == 'delivered' ||
      status == 'read';

  factory CommunicationMessage.fromJson(
    Map<String, dynamic> json,
  ) {
    return CommunicationMessage(
      id: _parseInt(json['id']),
      conversationId: _parseInt(json['conversation_id']),
      companyId: _parseInt(json['company_id']),
      channel: json['channel']?.toString() ?? '',
      direction: json['direction']?.toString() ?? '',
      messageType: json['message_type']?.toString() ?? '',
      message: json['message']?.toString() ?? '',
      providerMessageId:
          json['provider_message_id']?.toString() ?? '',
      providerReplyToId:
          json['provider_reply_to_id']?.toString() ?? '',
      status: json['status']?.toString() ?? '',
      errorCode: json['error_code']?.toString() ?? '',
      errorMessage: json['error_message']?.toString() ?? '',
      sentAt: _parseDateTime(json['sent_at']),
      deliveredAt: _parseDateTime(json['delivered_at']),
      readAt: _parseDateTime(json['read_at']),
      failedAt: _parseDateTime(json['failed_at']),
      createdAt: _parseDateTime(json['created_at']),
      updatedAt: _parseDateTime(json['updated_at']),
    );
  }

  static int _parseInt(dynamic value) {
    if (value is int) {
      return value;
    }

    return int.tryParse(value?.toString() ?? '') ?? 0;
  }

static DateTime? _parseDateTime(dynamic value) {
  final rawValue = value?.toString().trim() ?? '';

  if (rawValue.isEmpty) {
    return null;
  }

  final normalizedValue = rawValue.contains('T')
      ? rawValue
      : rawValue.replaceFirst(' ', 'T');

  return DateTime.tryParse(normalizedValue);
}
}