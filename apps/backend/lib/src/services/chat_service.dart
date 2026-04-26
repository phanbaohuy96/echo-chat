import 'package:uuid/uuid.dart';

import '../models/chat_message.dart';
import '../models/user.dart';
import '../store/demo_store.dart';

class ChatConversationResult {
  const ChatConversationResult({
    required this.peer,
    required this.messages,
    required this.latestMessageCreatedAt,
    required this.oldestMessageCreatedAt,
    required this.hasMoreOlder,
  });

  final BackendUser peer;
  final List<BackendChatMessage> messages;
  final DateTime? latestMessageCreatedAt;
  final DateTime? oldestMessageCreatedAt;
  final bool hasMoreOlder;

  Map<String, dynamic> get syncMetadata => {
    'latest_message_created_at': latestMessageCreatedAt
        ?.toUtc()
        .toIso8601String(),
    'oldest_message_created_at': oldestMessageCreatedAt
        ?.toUtc()
        .toIso8601String(),
    'has_more_older': hasMoreOlder,
  };
}

class ChatException implements Exception {
  const ChatException(this.statusCode, this.message);

  final int statusCode;
  final String message;
}

class ChatService {
  ChatService(this._store);

  static const _defaultConversationLimit = 50;
  static const _maxConversationLimit = 100;

  final DemoStore _store;
  final _uuid = const Uuid();

  List<BackendUser> listPeers({required BackendUser user}) {
    return _store.usersById.values.where((peer) => peer.id != user.id).toList()
      ..sort((a, b) => a.username.compareTo(b.username));
  }

  ChatConversationResult getConversation({
    required BackendUser user,
    required String peerUserId,
    DateTime? afterCreatedAt,
    DateTime? beforeCreatedAt,
    int? limit,
  }) {
    final peer = _getPeer(user: user, peerUserId: peerUserId);
    final conversationMessages = _conversationMessages(user.id, peer.id);
    final pageLimit = _normalizeLimit(limit);
    final messages = switch ((afterCreatedAt, beforeCreatedAt)) {
      (final after?, _) =>
        conversationMessages
            .where((message) => message.createdAt.isAfter(after))
            .take(pageLimit)
            .toList(),
      (null, final before?) => _latestPage(
        conversationMessages
            .where((message) => message.createdAt.isBefore(before))
            .toList(),
        pageLimit,
      ),
      _ => _latestPage(conversationMessages, pageLimit),
    };
    final oldestReturned = messages.isEmpty ? null : messages.first.createdAt;
    final hasMoreOlder =
        oldestReturned != null &&
        conversationMessages.any(
          (message) => message.createdAt.isBefore(oldestReturned),
        );
    return ChatConversationResult(
      peer: peer,
      messages: messages,
      latestMessageCreatedAt: messages.isEmpty ? null : messages.last.createdAt,
      oldestMessageCreatedAt: messages.isEmpty
          ? null
          : messages.first.createdAt,
      hasMoreOlder: hasMoreOlder,
    );
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
    return chatMessage;
  }

  List<BackendChatMessage> _conversationMessages(
    String firstUserId,
    String secondUserId,
  ) {
    final messageIds =
        _store.messageIdsByConversationKey[_conversationKey(
          firstUserId,
          secondUserId,
        )];
    return (messageIds ?? [])
        .map((id) => _store.messagesById[id])
        .nonNulls
        .toList();
  }

  List<BackendChatMessage> _latestPage(
    List<BackendChatMessage> messages,
    int limit,
  ) {
    if (messages.length <= limit) {
      return messages;
    }
    return messages.sublist(messages.length - limit);
  }

  int _normalizeLimit(int? limit) {
    if (limit == null || limit <= 0) {
      return _defaultConversationLimit;
    }
    if (limit > _maxConversationLimit) {
      return _maxConversationLimit;
    }
    return limit;
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
