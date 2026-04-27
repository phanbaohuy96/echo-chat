part of 'chat_usecase.dart';

@Injectable(as: ChatUsecase)
class ChatInteractorImpl extends ChatUsecase {
  ChatInteractorImpl(
    this._localDataManager,
    this.appApiService,
    this._localRepository,
  );

  final LocalDataManager _localDataManager;
  final AppApiService appApiService;
  final ChatLocalRepository _localRepository;

  String? _olderMessagesPeerUserId;

  late final _olderMessagesListingUsecase =
      CursorListingUseCase<
        LocalChatMessage,
        String,
        ({List<LocalChatMessage> messages, DateTime? nextCursor}),
        DateTime
      >(
        _loadOlderMessagePage,
        (response) => response.messages,
        (response) => response.nextCursor,
      );

  @override
  Future<List<UserModel>> getCachedPeers() async {
    return _withoutCurrentUser(await _localRepository.getCachedPeers());
  }

  @override
  Future<List<UserModel>> syncPeers() async {
    final response = ChatUsersResponse.fromJson(
      await appApiService.getChatUsers(),
    );
    await _localRepository.cachePeers(response.users);
    return _withoutCurrentUser(await _localRepository.getCachedPeers());
  }

  @override
  Future<List<LocalChatMessage>> getCachedConversation(
    String peerUserId, {
    int limit = 80,
  }) {
    return _localRepository.getCachedConversation(peerUserId, limit: limit);
  }

  @override
  Future<List<LocalChatMessage>> refreshConversation(String peerUserId) async {
    final currentUserId = _currentUserId;
    if (currentUserId == null) {
      return _localRepository.getCachedConversation(peerUserId);
    }
    final sync = await _localRepository.getConversationSync(peerUserId);
    final fallbackNewest = await _localRepository.getNewestMessageCreatedAt(
      peerUserId,
    );
    final response = ChatConversationResponse.fromJson(
      await appApiService.getChatMessages(
        peerUserId,
        afterCreatedAt: sync?.latestMessageCreatedAt ?? fallbackNewest,
      ),
    );
    await _localRepository.cacheRemoteConversation(
      peer: response.peer,
      messages: response.messages,
      syncMetadata: response.syncMetadata,
      currentUserId: currentUserId,
    );
    return _localRepository.getCachedConversation(peerUserId);
  }

  @override
  Future<({List<LocalChatMessage> messages, bool hasMoreOlder})>
  loadOlderMessages(String peerUserId) async {
    final sync = await _localRepository.getConversationSync(peerUserId);
    if (_currentUserId == null || sync?.hasMoreOlder == false) {
      return (
        messages: await _localRepository.getCachedConversation(peerUserId),
        hasMoreOlder: sync?.hasMoreOlder ?? false,
      );
    }
    if (_olderMessagesPeerUserId != peerUserId) {
      _olderMessagesPeerUserId = peerUserId;
      await _olderMessagesListingUsecase.getData(peerUserId);
    } else {
      await _olderMessagesListingUsecase.loadMoreData(peerUserId);
    }
    final updatedSync = await _localRepository.getConversationSync(peerUserId);
    return (
      messages: await _localRepository.getCachedConversation(peerUserId),
      hasMoreOlder: updatedSync?.hasMoreOlder ?? false,
    );
  }

  Future<({List<LocalChatMessage> messages, DateTime? nextCursor})>
  _loadOlderMessagePage(
    DateTime? cursor,
    int limit, [
    String? peerUserId,
  ]) async {
    final currentUserId = _currentUserId;
    if (currentUserId == null || peerUserId == null) {
      return (messages: <LocalChatMessage>[], nextCursor: null);
    }
    final sync = await _localRepository.getConversationSync(peerUserId);
    final beforeCreatedAt =
        cursor ??
        sync?.oldestMessageCreatedAt ??
        await _localRepository.getOldestMessageCreatedAt(peerUserId);
    if (beforeCreatedAt == null) {
      return (messages: <LocalChatMessage>[], nextCursor: null);
    }
    final response = ChatConversationResponse.fromJson(
      await appApiService.getChatMessages(
        peerUserId,
        beforeCreatedAt: beforeCreatedAt,
        limit: limit,
      ),
    );
    await _localRepository.cacheRemoteConversation(
      peer: response.peer,
      messages: response.messages,
      syncMetadata: response.syncMetadata,
      currentUserId: currentUserId,
    );
    return (
      messages: response.messages
          .map(
            (message) => LocalChatMessage.fromRemote(
              message,
              currentUserId: currentUserId,
            ),
          )
          .toList(),
      nextCursor: response.syncMetadata.hasMoreOlder
          ? response.syncMetadata.oldestMessageCreatedAt
          : null,
    );
  }

  @override
  Future<bool> hasMoreOlderMessages(String peerUserId) async {
    final sync = await _localRepository.getConversationSync(peerUserId);
    return sync?.hasMoreOlder ?? true;
  }

  @override
  Future<LocalChatMessage> enqueueMessage({
    required String recipientUserId,
    required String clientMessageId,
    required String message,
    required String senderUserId,
  }) {
    return _localRepository.enqueueMessage(
      clientMessageId: clientMessageId,
      senderUserId: senderUserId,
      recipientUserId: recipientUserId,
      message: message,
    );
  }

  @override
  Future<List<LocalChatMessage>> sendQueuedMessage(
    String clientMessageId,
  ) async {
    final localMessage = await _localRepository.getMessage(clientMessageId);
    if (localMessage == null) {
      return [];
    }
    await syncQueuedMessage(clientMessageId);
    return _localRepository.getCachedConversation(
      localMessage.conversationPeerUserId,
    );
  }

  @override
  Future<List<LocalChatMessage>> retryMessage(String clientMessageId) async {
    final localMessage = await _localRepository.getMessage(clientMessageId);
    if (localMessage == null) {
      return [];
    }
    await _localRepository.markPending(clientMessageId);
    await syncQueuedMessage(clientMessageId);
    return _localRepository.getCachedConversation(
      localMessage.conversationPeerUserId,
    );
  }

  @override
  Future<void> syncQueuedMessage(String clientMessageId) async {
    final localMessage = await _localRepository.getMessage(clientMessageId);
    final currentUserId = _currentUserId;
    if (localMessage == null || currentUserId == null) {
      return;
    }
    try {
      final response = SendMessageResponse.fromJson(
        await appApiService.sendChatMessage(
          SendMessageRequest(
            recipientUserId: localMessage.recipientUserId,
            clientMessageId: localMessage.clientMessageId,
            message: localMessage.message,
          ).toJson(),
        ),
      );
      await _localRepository.markSent(
        clientMessageId: localMessage.clientMessageId,
        remoteMessage: response.message,
        currentUserId: currentUserId,
      );
    } catch (error) {
      await _localRepository.markFailed(
        clientMessageId: localMessage.clientMessageId,
        errorMessage: error.toString(),
      );
    }
  }

  @override
  Future<void> syncOutbox({String? peerUserId}) async {
    final outbox = await _localRepository.getOutbox(peerUserId: peerUserId);
    for (final message in outbox) {
      await syncQueuedMessage(message.clientMessageId);
    }
  }

  @override
  Future<ChatLocalStorageSummary> getLocalStorageSummary() {
    return _localRepository.getStorageSummary();
  }

  @override
  Future<void> clearLocalStorage() {
    return _localRepository.clearAllCachedData();
  }

  List<UserModel> _withoutCurrentUser(List<UserModel> peers) {
    final currentUserId = _currentUserId;
    if (currentUserId == null) {
      return peers;
    }
    return peers.where((peer) => peer.id != currentUserId).toList();
  }

  String? get _currentUserId => _localDataManager.userInfo?.id;
}
