import 'package:core/core.dart';
import 'package:data_source/data_source.dart';
import 'package:injectable/injectable.dart';

import '../../../data/data_source/local/local_data_manager.dart';
import '../../../data/repositories/chat/chat_local_repository.dart';
import '../../entities/chat/local_chat_message.dart';
import 'chat_outbox_usecase.dart';

@Injectable(as: ChatOutboxUsecase)
class ChatOutboxInteractorImpl extends ChatOutboxUsecase {
  ChatOutboxInteractorImpl(
    this._localDataManager,
    this._appApiService,
    this._localRepository,
  );

  final LocalDataManager _localDataManager;
  final AppApiService _appApiService;
  final ChatLocalRepository _localRepository;

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
    await _syncQueuedLocalMessage(localMessage);
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
    await _syncQueuedLocalMessage(localMessage);
    return _localRepository.getCachedConversation(
      localMessage.conversationPeerUserId,
    );
  }

  @override
  Future<void> syncQueuedMessage(String clientMessageId) async {
    final localMessage = await _localRepository.getMessage(clientMessageId);
    if (localMessage == null) {
      return;
    }
    await _syncQueuedLocalMessage(localMessage);
  }

  @override
  Future<void> syncOutbox({String? peerUserId}) async {
    final outbox = await _localRepository.getOutbox(peerUserId: peerUserId);
    for (final message in outbox) {
      await _syncQueuedLocalMessage(message);
    }
  }

  Future<void> _syncQueuedLocalMessage(LocalChatMessage localMessage) async {
    final currentUserId = _localDataManager.userInfo?.id;
    if (currentUserId == null) {
      return;
    }
    try {
      final response = SendMessageResponse.fromJson(
        await _appApiService.sendChatMessage(
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
}
