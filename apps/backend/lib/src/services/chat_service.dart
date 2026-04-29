import 'package:uuid/uuid.dart';

import '../models/chat_message.dart';
import '../models/user.dart';
import '../store/demo_store.dart';

class ChatConversationResult {
  const ChatConversationResult({
    required this.peer,
    required this.messages,
    required this.latestMessageCreatedAt,
    required this.latestMessageUpdatedAt,
    required this.oldestMessageCreatedAt,
    required this.hasMoreOlder,
  });

  final BackendUser peer;
  final List<BackendChatMessage> messages;
  final DateTime? latestMessageCreatedAt;
  final DateTime? latestMessageUpdatedAt;
  final DateTime? oldestMessageCreatedAt;
  final bool hasMoreOlder;

  Map<String, dynamic> get syncMetadata => {
    'latest_message_created_at': latestMessageCreatedAt
        ?.toUtc()
        .toIso8601String(),
    'latest_message_updated_at': latestMessageUpdatedAt
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
    DateTime? afterUpdatedAt,
    DateTime? beforeCreatedAt,
    int? limit,
  }) {
    final peer = _getPeer(user: user, peerUserId: peerUserId);
    final conversationMessages = _conversationMessages(user.id, peer.id);
    final pageLimit = _normalizeLimit(limit);
    final messages = switch ((
      afterCreatedAt,
      afterUpdatedAt,
      beforeCreatedAt,
    )) {
      (_, final afterUpdate?, _) => _updatedPage(
        conversationMessages
            .where((message) => _messageUpdatedAt(message).isAfter(afterUpdate))
            .toList(),
        pageLimit,
      ),
      (final afterCreate?, null, _) =>
        conversationMessages
            .where((message) => message.createdAt.isAfter(afterCreate))
            .take(pageLimit)
            .toList(),
      (null, null, final before?) => _latestPage(
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
      latestMessageCreatedAt: _latestCreatedAt(messages),
      latestMessageUpdatedAt: _latestUpdatedAt(messages),
      oldestMessageCreatedAt: messages.isEmpty
          ? null
          : messages.first.createdAt,
      hasMoreOlder: hasMoreOlder,
    );
  }

  BackendChatMessage deleteMessage({
    required BackendUser user,
    required String messageId,
  }) {
    final cleanMessageId = messageId.trim();
    if (cleanMessageId.isEmpty) {
      throw const ChatException(400, 'Message id is required.');
    }

    final existingMessage = _store.messagesById[cleanMessageId];
    if (existingMessage == null) {
      throw const ChatException(404, 'Message was not found.');
    }
    if (existingMessage.senderUserId != user.id) {
      throw const ChatException(
        403,
        'Only the sender can delete this message.',
      );
    }
    if (existingMessage.deletedAt != null) {
      return existingMessage;
    }

    final now = DateTime.now().toUtc();
    final deletedMessage = BackendChatMessage(
      id: existingMessage.id,
      senderUserId: existingMessage.senderUserId,
      recipientUserId: existingMessage.recipientUserId,
      clientMessageId: existingMessage.clientMessageId,
      message: '',
      createdAt: existingMessage.createdAt,
      updatedAt: now,
      deletedAt: now,
      version: existingMessage.version + 1,
    );
    _store.messagesById[cleanMessageId] = deletedMessage;
    return deletedMessage;
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

  List<BackendChatMessage> _updatedPage(
    List<BackendChatMessage> messages,
    int limit,
  ) {
    messages.sort((left, right) {
      final updatedCompare = _messageUpdatedAt(
        left,
      ).compareTo(_messageUpdatedAt(right));
      if (updatedCompare != 0) {
        return updatedCompare;
      }
      final createdCompare = left.createdAt.compareTo(right.createdAt);
      if (createdCompare != 0) {
        return createdCompare;
      }
      return left.id.compareTo(right.id);
    });
    if (messages.length <= limit) {
      return messages;
    }
    return messages.take(limit).toList();
  }

  DateTime _messageUpdatedAt(BackendChatMessage message) {
    return message.updatedAt ?? message.createdAt;
  }

  DateTime? _latestCreatedAt(List<BackendChatMessage> messages) {
    if (messages.isEmpty) {
      return null;
    }
    return messages
        .map((message) => message.createdAt)
        .reduce((left, right) => left.isAfter(right) ? left : right);
  }

  DateTime? _latestUpdatedAt(List<BackendChatMessage> messages) {
    if (messages.isEmpty) {
      return null;
    }
    return messages
        .map(_messageUpdatedAt)
        .reduce((left, right) => left.isAfter(right) ? left : right);
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
