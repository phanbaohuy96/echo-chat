import 'package:data_source/data_source.dart';
import 'package:injectable/injectable.dart';

import '../../../domain/entities/chat/chat_conversation_sync.dart';
import '../../../domain/entities/chat/chat_local_storage_summary.dart';
import '../../../domain/entities/chat/local_chat_message.dart';
import '../../data_source/local/sqlite/chat_conversation_sync_dao.dart';
import '../../data_source/local/sqlite/chat_message_dao.dart';
import '../../data_source/local/sqlite/chat_peer_dao.dart';

@injectable
class ChatLocalRepository {
  ChatLocalRepository(this._peerDao, this._messageDao, this._syncDao);

  final ChatPeerDao _peerDao;
  final ChatMessageDao _messageDao;
  final ChatConversationSyncDao _syncDao;

  Future<List<UserModel>> getCachedPeers() => _peerDao.getPeers();

  Future<void> cachePeers(List<UserModel> peers) => _peerDao.upsertPeers(peers);

  Future<UserModel?> getCachedPeer(String userId) => _peerDao.getPeer(userId);

  Future<List<LocalChatMessage>> getCachedConversation(
    String peerUserId, {
    int limit = 80,
  }) {
    return _messageDao.getConversation(peerUserId, limit: limit);
  }

  Future<List<LocalChatMessage>> getOlderConversationPage(
    String peerUserId, {
    required DateTime beforeCreatedAt,
    int limit = 50,
  }) {
    return _messageDao.getOlderConversationPage(
      peerUserId,
      beforeCreatedAt: beforeCreatedAt,
      limit: limit,
    );
  }

  Future<ChatConversationSync?> getConversationSync(String peerUserId) {
    return _syncDao.getSync(peerUserId);
  }

  Future<DateTime?> getNewestMessageCreatedAt(String peerUserId) {
    return _messageDao.getNewestCreatedAt(peerUserId);
  }

  Future<DateTime?> getOldestMessageCreatedAt(String peerUserId) {
    return _messageDao.getOldestCreatedAt(peerUserId);
  }

  Future<LocalChatMessage> enqueueMessage({
    required String clientMessageId,
    required String senderUserId,
    required String recipientUserId,
    required String message,
  }) {
    return _messageDao.insertPending(
      clientMessageId: clientMessageId,
      conversationPeerUserId: recipientUserId,
      senderUserId: senderUserId,
      recipientUserId: recipientUserId,
      message: message,
      createdAt: DateTime.now(),
    );
  }

  Future<void> cacheRemoteConversation({
    required UserModel peer,
    required List<ChatMessageDto> messages,
    required ChatConversationSyncMetadataDto syncMetadata,
    required String currentUserId,
  }) async {
    await _peerDao.upsertPeers([peer]);
    await _messageDao.upsertRemoteMessages(
      messages,
      currentUserId: currentUserId,
    );
    final peerUserId = peer.id;
    if (peerUserId != null) {
      await _syncDao.updateFromRemote(
        peerUserId: peerUserId,
        metadata: syncMetadata,
        fallbackLatestCreatedAt: messages.isEmpty
            ? null
            : messages.last.createdAt,
        fallbackOldestCreatedAt: messages.isEmpty
            ? null
            : messages.first.createdAt,
      );
    }
  }

  Future<void> deleteLocalOnlyMessage(String clientMessageId) {
    return _messageDao.deleteLocalOnly(clientMessageId);
  }

  Future<void> cacheRemoteMessage({
    required ChatMessageDto message,
    required String currentUserId,
  }) {
    return _messageDao.upsertRemoteMessages([
      message,
    ], currentUserId: currentUserId);
  }

  Future<void> markSent({
    required String clientMessageId,
    required ChatMessageDto remoteMessage,
    required String currentUserId,
  }) async {
    await _messageDao.markSent(
      clientMessageId: clientMessageId,
      remoteMessage: remoteMessage,
      currentUserId: currentUserId,
    );
    final peerUserId = remoteMessage.senderUserId == currentUserId
        ? remoteMessage.recipientUserId
        : remoteMessage.senderUserId;
    await _syncDao.updateAfterLocalSent(
      peerUserId: peerUserId,
      createdAt: remoteMessage.createdAt,
    );
  }

  Future<void> markPending(String clientMessageId) {
    return _messageDao.markPending(clientMessageId);
  }

  Future<void> markFailed({
    required String clientMessageId,
    required String errorMessage,
  }) {
    return _messageDao.markFailed(
      clientMessageId: clientMessageId,
      errorMessage: errorMessage,
    );
  }

  Future<LocalChatMessage?> getMessage(String clientMessageId) {
    return _messageDao.getMessage(clientMessageId);
  }

  Future<List<LocalChatMessage>> getOutbox({String? peerUserId}) {
    return _messageDao.getOutbox(peerUserId: peerUserId);
  }

  /// Returns aggregate counts and message date bounds for cached chat data.
  Future<ChatLocalStorageSummary> getStorageSummary() async {
    final results = await Future.wait<Object?>([
      _peerDao.countPeers(),
      _messageDao.countMessages(),
      _messageDao.countPendingMessages(),
      _messageDao.countFailedMessages(),
      _messageDao.getGlobalOldestCreatedAt(),
      _messageDao.getGlobalNewestCreatedAt(),
    ]);
    return ChatLocalStorageSummary(
      peerCount: results[0] as int,
      messageCount: results[1] as int,
      pendingMessageCount: results[2] as int,
      failedMessageCount: results[3] as int,
      oldestMessageCreatedAt: results[4] as DateTime?,
      newestMessageCreatedAt: results[5] as DateTime?,
    );
  }

  /// Deletes cached chat sync metadata, messages, and peers from local storage.
  Future<void> clearAllCachedData() async {
    await _syncDao.clearAll();
    await _messageDao.clearAll();
    await _peerDao.clearAll();
  }
}
