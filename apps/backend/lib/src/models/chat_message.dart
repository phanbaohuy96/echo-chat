class BackendChatMessage {
  const BackendChatMessage({
    required this.id,
    required this.senderUserId,
    required this.recipientUserId,
    required this.clientMessageId,
    required this.message,
    required this.createdAt,
    this.updatedAt,
    this.deletedAt,
    this.version = 1,
  });

  final String id;
  final String senderUserId;
  final String recipientUserId;
  final String clientMessageId;
  final String message;
  final DateTime createdAt;
  final DateTime? updatedAt;
  final DateTime? deletedAt;
  final int version;

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'sender_user_id': senderUserId,
      'recipient_user_id': recipientUserId,
      'client_message_id': clientMessageId,
      'message': message,
      'created_at': createdAt.toUtc().toIso8601String(),
      'updated_at': updatedAt?.toUtc().toIso8601String(),
      'deleted_at': deletedAt?.toUtc().toIso8601String(),
      'version': version,
    };
  }
}
