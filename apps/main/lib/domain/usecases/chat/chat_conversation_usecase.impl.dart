import 'package:core/core.dart';
import 'package:data_source/data_source.dart';
import 'package:injectable/injectable.dart';

import '../../../data/data_source/local/local_data_manager.dart';
import '../../../data/repositories/chat/chat_local_repository.dart';
import '../../entities/chat/local_chat_message.dart';
import 'chat_conversation_usecase.dart';

@Injectable(as: ChatConversationUsecase)
class ChatConversationInteractorImpl extends ChatConversationUsecase {
  ChatConversationInteractorImpl(
    this._localDataManager,
    this._appApiService,
    this._localRepository,
  );

  final LocalDataManager _localDataManager;
  final AppApiService _appApiService;
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
      await _appApiService.getChatMessages(
        peerUserId,
        afterUpdatedAt:
            sync?.latestMessageUpdatedAt ??
            sync?.latestMessageCreatedAt ??
            fallbackNewest,
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

  @override
  Future<bool> hasMoreOlderMessages(String peerUserId) async {
    final sync = await _localRepository.getConversationSync(peerUserId);
    return sync?.hasMoreOlder ?? true;
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
      await _appApiService.getChatMessages(
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

  String? get _currentUserId => _localDataManager.userInfo?.id;
}
