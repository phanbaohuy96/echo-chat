import 'package:data_source/data_source.dart';

enum ChatMessageStatus { pending, sent, failed }

class LocalChatMessage {
  const LocalChatMessage({
    required this.clientMessageId,
    required this.conversationPeerUserId,
    required this.senderUserId,
    required this.recipientUserId,
    required this.message,
    required this.createdAt,
    required this.status,
    this.localId,
    this.remoteId,
    this.errorMessage,
  });

  factory LocalChatMessage.fromRemote(
    ChatMessageDto message, {
    required String currentUserId,
  }) {
    final conversationPeerUserId = message.senderUserId == currentUserId
        ? message.recipientUserId
        : message.senderUserId;
    return LocalChatMessage(
      remoteId: message.id,
      clientMessageId: message.clientMessageId,
      conversationPeerUserId: conversationPeerUserId,
      senderUserId: message.senderUserId,
      recipientUserId: message.recipientUserId,
      message: message.message,
      createdAt: message.createdAt,
      status: ChatMessageStatus.sent,
    );
  }

  final int? localId;
  final String? remoteId;
  final String clientMessageId;
  final String conversationPeerUserId;
  final String senderUserId;
  final String recipientUserId;
  final String message;
  final DateTime createdAt;
  final ChatMessageStatus status;
  final String? errorMessage;

  bool isMine(String? currentUserId) => senderUserId == currentUserId;
}
