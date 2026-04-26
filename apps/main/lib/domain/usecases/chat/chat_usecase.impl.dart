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
  Future<List<LocalChatMessage>> getCachedConversation(String peerUserId) {
    return _localRepository.getCachedConversation(peerUserId);
  }

  @override
  Future<List<LocalChatMessage>> syncConversation(String peerUserId) async {
    final currentUserId = _currentUserId;
    if (currentUserId == null) {
      return _localRepository.getCachedConversation(peerUserId);
    }
    final response = ChatConversationResponse.fromJson(
      await appApiService.getChatMessages(peerUserId),
    );
    await _localRepository.cacheRemoteConversation(
      peer: response.peer,
      messages: response.messages,
      currentUserId: currentUserId,
    );
    return _localRepository.getCachedConversation(peerUserId);
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

  List<UserModel> _withoutCurrentUser(List<UserModel> peers) {
    final currentUserId = _currentUserId;
    if (currentUserId == null) {
      return peers;
    }
    return peers.where((peer) => peer.id != currentUserId).toList();
  }

  String? get _currentUserId => _localDataManager.userInfo?.id;
}
