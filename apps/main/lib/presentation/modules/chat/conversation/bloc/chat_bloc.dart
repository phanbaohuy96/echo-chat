import 'package:core/core.dart';
import 'package:data_source/data_source.dart';
import 'package:freezed_annotation/freezed_annotation.dart';
import 'package:injectable/injectable.dart';

import '../../../../../domain/entities/chat/local_chat_message.dart';
import '../../../../../domain/usecases/chat/chat_usecase.dart';
import '../../../../base/base.dart';

part 'chat_bloc.freezed.dart';
part 'chat_event.dart';
part 'chat_state.dart';

@Injectable()
class ChatBloc extends AppBlocBase<ChatEvent, ChatState> {
  ChatBloc(this._chatUsecase) : super(ChatInitial(data: _StateData.initial())) {
    on<ChatStartedEvent>(_onChatStartedEvent);
    on<ChatPeerSelectedEvent>(_onChatPeerSelectedEvent);
    on<ChatRefreshRequestedEvent>(_onChatRefreshRequestedEvent);
    on<ChatOlderMessagesRequestedEvent>(_onChatOlderMessagesRequestedEvent);
    on<ChatRetryRequestedEvent>(_onChatRetryRequestedEvent);
    on<ChatMessageSubmittedEvent>(_onChatMessageSubmittedEvent);
  }

  final ChatUsecase _chatUsecase;
  final _uuid = const Uuid();
  final _retryingMessageIds = <String>{};

  Future<void> _onChatStartedEvent(
    ChatStartedEvent event,
    Emitter<ChatState> emit,
  ) async {
    emit(state.copyWith(data: state.data.copyWith(isLoadingPeers: true)));

    try {
      final cachedPeers = await _chatUsecase.getCachedPeers();
      final cachedSelectedPeer = state.selectedPeer ?? cachedPeers.firstOrNull;
      final cachedPeerUserId = cachedSelectedPeer?.id;
      final cachedHasMoreOlder =
          cachedPeerUserId == null ||
          await _chatUsecase.hasMoreOlderMessages(cachedPeerUserId);
      emit(
        state.copyWith(
          data: state.data.copyWith(
            peers: cachedPeers,
            selectedPeer: cachedSelectedPeer,
            messages: cachedSelectedPeer == null
                ? []
                : await _messagesFor(cachedSelectedPeer),
            hasMoreOlder: cachedHasMoreOlder,
          ),
        ),
      );

      await _syncPeers(emit);
      final selectedPeer = state.selectedPeer;
      if (selectedPeer != null) {
        await _syncConversation(selectedPeer, emit);
      }
    } finally {
      emit(state.copyWith(data: state.data.copyWith(isLoadingPeers: false)));
    }
  }

  Future<void> _onChatPeerSelectedEvent(
    ChatPeerSelectedEvent event,
    Emitter<ChatState> emit,
  ) async {
    if (event.peer.id == state.selectedPeer?.id) {
      return;
    }
    final peerUserId = event.peer.id;
    emit(
      state.copyWith(
        data: state.data.copyWith(
          selectedPeer: event.peer,
          messages: await _messagesFor(event.peer),
          hasMoreOlder:
              peerUserId == null ||
              await _chatUsecase.hasMoreOlderMessages(peerUserId),
        ),
      ),
    );
    await _syncConversation(event.peer, emit);
  }

  Future<void> _onChatRefreshRequestedEvent(
    ChatRefreshRequestedEvent event,
    Emitter<ChatState> emit,
  ) async {
    final selectedPeer = state.selectedPeer;
    if (selectedPeer == null) {
      await _syncPeers(emit);
      final discoveredPeer = state.selectedPeer;
      if (discoveredPeer != null) {
        await _syncConversation(discoveredPeer, emit);
      }
      return;
    }
    await _syncConversation(selectedPeer, emit);
  }

  Future<void> _onChatOlderMessagesRequestedEvent(
    ChatOlderMessagesRequestedEvent event,
    Emitter<ChatState> emit,
  ) async {
    final peerUserId = state.selectedPeer?.id;
    if (peerUserId == null || state.isLoadingOlder || !state.hasMoreOlder) {
      return;
    }
    emit(state.copyWith(data: state.data.copyWith(isLoadingOlder: true)));
    try {
      final result = await _chatUsecase.loadOlderMessages(peerUserId);
      emit(
        state.copyWith(
          data: state.data.copyWith(
            messages: _mapMessages(result.messages),
            hasMoreOlder: result.hasMoreOlder,
          ),
        ),
      );
    } finally {
      emit(state.copyWith(data: state.data.copyWith(isLoadingOlder: false)));
    }
  }

  Future<void> _onChatMessageSubmittedEvent(
    ChatMessageSubmittedEvent event,
    Emitter<ChatState> emit,
  ) async {
    final message = event.message.trim();
    final selectedPeer = state.selectedPeer;
    final recipientUserId = selectedPeer?.id;
    final senderUserId = localDataManager.userInfo?.id;
    if (message.isEmpty || recipientUserId == null || senderUserId == null) {
      return;
    }

    final clientMessageId = _clientMessageId();
    emit(state.copyWith(data: state.data.copyWith(isSending: true)));

    try {
      final pendingMessage = await _chatUsecase.enqueueMessage(
        recipientUserId: recipientUserId,
        clientMessageId: clientMessageId,
        message: message,
        senderUserId: senderUserId,
      );
      emit(
        state.copyWith(
          data: state.data.copyWith(
            messages: [
              ...state.messages,
              ChatMessage.fromLocal(
                pendingMessage,
                currentUserId: senderUserId,
              ),
            ],
          ),
        ),
      );
      final messages = await _chatUsecase.sendQueuedMessage(clientMessageId);
      emit(
        state.copyWith(
          data: state.data.copyWith(messages: _mapMessages(messages)),
        ),
      );
    } finally {
      emit(state.copyWith(data: state.data.copyWith(isSending: false)));
    }
  }

  Future<void> _onChatRetryRequestedEvent(
    ChatRetryRequestedEvent event,
    Emitter<ChatState> emit,
  ) async {
    if (!_retryingMessageIds.add(event.clientMessageId)) {
      return;
    }
    try {
      final messages = await _chatUsecase.retryMessage(event.clientMessageId);
      if (messages.isNotEmpty) {
        emit(
          state.copyWith(
            data: state.data.copyWith(messages: _mapMessages(messages)),
          ),
        );
      }
    } finally {
      _retryingMessageIds.remove(event.clientMessageId);
    }
  }

  Future<void> _syncConversation(
    UserModel peer,
    Emitter<ChatState> emit,
  ) async {
    final peerUserId = peer.id;
    if (peerUserId == null) {
      return;
    }

    emit(
      state.copyWith(
        data: state.data.copyWith(isLoadingMessages: true, isSyncing: true),
      ),
    );

    try {
      await _chatUsecase.syncOutbox(peerUserId: peerUserId);
      final messages = await _chatUsecase.refreshConversation(peerUserId);
      final hasMoreOlder = await _chatUsecase.hasMoreOlderMessages(peerUserId);
      emit(
        state.copyWith(
          data: state.data.copyWith(
            messages: _mapMessages(messages),
            hasMoreOlder: hasMoreOlder,
          ),
        ),
      );
    } finally {
      emit(
        state.copyWith(
          data: state.data.copyWith(isLoadingMessages: false, isSyncing: false),
        ),
      );
    }
  }

  Future<void> _syncPeers(Emitter<ChatState> emit) async {
    final peers = await _chatUsecase.syncPeers();
    final selectedPeer = state.selectedPeer ?? peers.firstOrNull;
    final selectedPeerUserId = selectedPeer?.id;
    final hasMoreOlder =
        selectedPeerUserId == null ||
        await _chatUsecase.hasMoreOlderMessages(selectedPeerUserId);
    emit(
      state.copyWith(
        data: state.data.copyWith(
          peers: peers,
          selectedPeer: selectedPeer,
          messages: selectedPeer == null ? [] : state.messages,
          hasMoreOlder: hasMoreOlder,
        ),
      ),
    );
  }

  Future<List<ChatMessage>> _messagesFor(UserModel peer) async {
    final peerUserId = peer.id;
    if (peerUserId == null) {
      return [];
    }
    return _mapMessages(await _chatUsecase.getCachedConversation(peerUserId));
  }

  List<ChatMessage> _mapMessages(List<LocalChatMessage> messages) {
    final currentUserId = localDataManager.userInfo?.id;
    return messages
        .map(
          (message) =>
              ChatMessage.fromLocal(message, currentUserId: currentUserId),
        )
        .toList();
  }

  String _clientMessageId() => 'client_${_uuid.v4()}';
}
