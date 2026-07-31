class Conversation {
  final int id;
  final int companyId;
  final String channel;
  final String contactIdentifier;
  final String contactName;
  final String status;
  final String lastMessage;
  final String lastMessageType;
  final String lastDirection;
  final DateTime? lastMessageAt;
  final int unreadCount;
  final DateTime? createdAt;
  final DateTime? updatedAt;

  const Conversation({
    required this.id,
    required this.companyId,
    required this.channel,
    required this.contactIdentifier,
    required this.contactName,
    required this.status,
    required this.lastMessage,
    required this.lastMessageType,
    required this.lastDirection,
    required this.lastMessageAt,
    required this.unreadCount,
    required this.createdAt,
    required this.updatedAt,
  });

  factory Conversation.fromJson(Map<String, dynamic> json) {
    return Conversation(
      id: _parseInt(json['id']),
      companyId: _parseInt(json['company_id']),
      channel: json['channel']?.toString() ?? '',
      contactIdentifier:
          json['contact_identifier']?.toString() ?? '',
      contactName: json['contact_name']?.toString() ?? '',
      status: json['status']?.toString() ?? '',
      lastMessage: json['last_message']?.toString() ?? '',
      lastMessageType:
          json['last_message_type']?.toString() ?? '',
      lastDirection:
          json['last_direction']?.toString() ?? '',
      lastMessageAt: _parseDateTime(json['last_message_at']),
      unreadCount: _parseInt(json['unread_count']),
      createdAt: _parseDateTime(json['created_at']),
      updatedAt: _parseDateTime(json['updated_at']),
    );
  }

  Conversation copyWith({
    int? id,
    int? companyId,
    String? channel,
    String? contactIdentifier,
    String? contactName,
    String? status,
    String? lastMessage,
    String? lastMessageType,
    String? lastDirection,
    DateTime? lastMessageAt,
    int? unreadCount,
    DateTime? createdAt,
    DateTime? updatedAt,
  }) {
    return Conversation(
      id: id ?? this.id,
      companyId: companyId ?? this.companyId,
      channel: channel ?? this.channel,
      contactIdentifier:
          contactIdentifier ?? this.contactIdentifier,
      contactName: contactName ?? this.contactName,
      status: status ?? this.status,
      lastMessage: lastMessage ?? this.lastMessage,
      lastMessageType:
          lastMessageType ?? this.lastMessageType,
      lastDirection: lastDirection ?? this.lastDirection,
      lastMessageAt: lastMessageAt ?? this.lastMessageAt,
      unreadCount: unreadCount ?? this.unreadCount,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
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