import 'package:uuid/uuid.dart';

import '../models/chat_message.dart';
import '../models/user.dart';
import '../store/demo_store.dart';

class ChatException implements Exception {
  const ChatException(this.statusCode, this.message);

  final int statusCode;
  final String message;
}

class ChatService {
  ChatService(this._store);

  static const _maxMessagesPerConversation = 80;

  final DemoStore _store;
  final _uuid = const Uuid();

  List<BackendUser> listPeers({required BackendUser user}) {
    return _store.usersById.values.where((peer) => peer.id != user.id).toList()
      ..sort((a, b) => a.username.compareTo(b.username));
  }

  ({BackendUser peer, List<BackendChatMessage> messages}) getConversation({
    required BackendUser user,
    required String peerUserId,
  }) {
    final peer = _getPeer(user: user, peerUserId: peerUserId);
    final messageIds =
        _store.messageIdsByConversationKey[_conversationKey(user.id, peer.id)];
    final messages = (messageIds ?? [])
        .map((id) => _store.messagesById[id])
        .nonNulls
        .toList();
    return (peer: peer, messages: messages);
  }

  BackendChatMessage sendMessage({
    required BackendUser sender,
    required String recipientUserId,
    required String clientMessageId,
    required String message,
  }) {
    final cleanClientMessageId = clientMessageId.trim();
    if (cleanClientMessageId.isEmpty) {
      throw const ChatException(400, 'Client message id is required.');
    }

    final cleanMessage = message.trim();
    if (cleanMessage.isEmpty) {
      throw const ChatException(400, 'Message is required.');
    }

    final recipient = _getPeer(user: sender, peerUserId: recipientUserId);
    final idempotencyKey = _idempotencyKey(sender.id, cleanClientMessageId);
    final existingMessageId =
        _store.messageIdBySenderAndClientMessageId[idempotencyKey];
    if (existingMessageId != null) {
      return _store.messagesById[existingMessageId]!;
    }

    final chatMessage = BackendChatMessage(
      id: 'msg_${_uuid.v4()}',
      senderUserId: sender.id,
      recipientUserId: recipient.id,
      clientMessageId: cleanClientMessageId,
      message: cleanMessage,
      createdAt: DateTime.now().toUtc(),
    );
    _store.messagesById[chatMessage.id] = chatMessage;
    _store.messageIdBySenderAndClientMessageId[idempotencyKey] = chatMessage.id;

    final conversationMessageIds = _store.messageIdsByConversationKey
        .putIfAbsent(_conversationKey(sender.id, recipient.id), () => []);
    conversationMessageIds.add(chatMessage.id);
    if (conversationMessageIds.length > _maxMessagesPerConversation) {
      final removedIds = conversationMessageIds.sublist(
        0,
        conversationMessageIds.length - _maxMessagesPerConversation,
      );
      conversationMessageIds.removeRange(
        0,
        conversationMessageIds.length - _maxMessagesPerConversation,
      );
      for (final removedId in removedIds) {
        final removedMessage = _store.messagesById.remove(removedId);
        if (removedMessage != null) {
          _store.messageIdBySenderAndClientMessageId.remove(
            _idempotencyKey(
              removedMessage.senderUserId,
              removedMessage.clientMessageId,
            ),
          );
        }
      }
    }
    return chatMessage;
  }

  BackendUser _getPeer({
    required BackendUser user,
    required String peerUserId,
  }) {
    final cleanPeerUserId = peerUserId.trim();
    if (cleanPeerUserId.isEmpty) {
      throw const ChatException(400, 'Peer user id is required.');
    }
    if (cleanPeerUserId == user.id) {
      throw const ChatException(400, 'Choose another user to chat with.');
    }
    final peer = _store.usersById[cleanPeerUserId];
    if (peer == null) {
      throw const ChatException(404, 'Recipient user was not found.');
    }
    return peer;
  }

  String _conversationKey(String firstUserId, String secondUserId) {
    final ids = [firstUserId, secondUserId]..sort();
    return ids.join(':');
  }

  String _idempotencyKey(String senderUserId, String clientMessageId) {
    return '$senderUserId:$clientMessageId';
  }
}

final chatService = ChatService(demoStore);
