class BackendChatMessage {
  const BackendChatMessage({
    required this.id,
    required this.senderUserId,
    required this.recipientUserId,
    required this.clientMessageId,
    required this.message,
    required this.createdAt,
  });

  final String id;
  final String senderUserId;
  final String recipientUserId;
  final String clientMessageId;
  final String message;
  final DateTime createdAt;

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'sender_user_id': senderUserId,
      'recipient_user_id': recipientUserId,
      'client_message_id': clientMessageId,
      'message': message,
      'created_at': createdAt.toUtc().toIso8601String(),
    };
  }
}
