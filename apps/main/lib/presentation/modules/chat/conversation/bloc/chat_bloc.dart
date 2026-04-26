import 'package:core/core.dart';
import 'package:data_source/data_source.dart';
import 'package:freezed_annotation/freezed_annotation.dart';
import 'package:injectable/injectable.dart';

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
    on<ChatMessageSubmittedEvent>(_onChatMessageSubmittedEvent);
  }

  static const _maxRetainedMessages = 80;

  final ChatUsecase _chatUsecase;
  final _uuid = const Uuid();

  Future<void> _onChatStartedEvent(
    ChatStartedEvent event,
    Emitter<ChatState> emit,
  ) async {
    emit(
      state.copyWith(
        data: state.data.copyWith(isLoadingPeers: true, errorMessage: null),
      ),
    );

    try {
      final response = await _chatUsecase.getPeers();
      final selectedPeer = state.selectedPeer ?? response.users.firstOrNull;
      emit(
        state.copyWith(
          data: state.data.copyWith(
            peers: response.users,
            selectedPeer: selectedPeer,
            messages: selectedPeer == null ? [] : state.messages,
            isLoadingPeers: false,
          ),
        ),
      );
      if (selectedPeer != null) {
        await _loadConversation(selectedPeer, emit);
      }
    } catch (_) {
      emit(
        state.copyWith(
          data: state.data.copyWith(
            isLoadingPeers: false,
            errorMessage: 'Could not load chat users.',
          ),
        ),
      );
    }
  }

  Future<void> _onChatPeerSelectedEvent(
    ChatPeerSelectedEvent event,
    Emitter<ChatState> emit,
  ) async {
    if (event.peer.id == state.selectedPeer?.id) {
      return;
    }
    emit(
      state.copyWith(
        data: state.data.copyWith(
          selectedPeer: event.peer,
          messages: [],
          errorMessage: null,
        ),
      ),
    );
    await _loadConversation(event.peer, emit);
  }

  Future<void> _onChatRefreshRequestedEvent(
    ChatRefreshRequestedEvent event,
    Emitter<ChatState> emit,
  ) async {
    final selectedPeer = state.selectedPeer;
    if (selectedPeer == null) {
      return;
    }
    await _loadConversation(selectedPeer, emit);
  }

  Future<void> _onChatMessageSubmittedEvent(
    ChatMessageSubmittedEvent event,
    Emitter<ChatState> emit,
  ) async {
    final message = event.message.trim();
    final selectedPeer = state.selectedPeer;
    final recipientUserId = selectedPeer?.id;
    if (message.isEmpty || recipientUserId == null || state.isSending) {
      return;
    }

    emit(
      state.copyWith(
        data: state.data.copyWith(isSending: true, errorMessage: null),
      ),
    );

    try {
      final response = await _chatUsecase.sendMessage(
        recipientUserId: recipientUserId,
        clientMessageId: _clientMessageId(),
        message: message,
      );
      emit(
        state.copyWith(
          data: state.data.copyWith(
            messages: _appendMessage(
              state.messages,
              ChatMessage.fromDto(
                response.message,
                currentUserId: localDataManager.userInfo?.id,
              ),
            ),
            isSending: false,
          ),
        ),
      );
    } catch (_) {
      emit(
        state.copyWith(
          data: state.data.copyWith(
            isSending: false,
            errorMessage: 'Could not send message.',
          ),
        ),
      );
    }
  }

  Future<void> _loadConversation(
    UserModel peer,
    Emitter<ChatState> emit,
  ) async {
    final peerUserId = peer.id;
    if (peerUserId == null) {
      emit(
        state.copyWith(
          data: state.data.copyWith(errorMessage: 'Could not load messages.'),
        ),
      );
      return;
    }

    emit(
      state.copyWith(
        data: state.data.copyWith(isLoadingMessages: true, errorMessage: null),
      ),
    );

    try {
      final response = await _chatUsecase.getConversation(peerUserId);
      final currentUserId = localDataManager.userInfo?.id;
      emit(
        state.copyWith(
          data: state.data.copyWith(
            selectedPeer: response.peer,
            messages: response.messages
                .map(
                  (message) => ChatMessage.fromDto(
                    message,
                    currentUserId: currentUserId,
                  ),
                )
                .toList(),
            isLoadingMessages: false,
          ),
        ),
      );
    } catch (_) {
      emit(
        state.copyWith(
          data: state.data.copyWith(
            isLoadingMessages: false,
            errorMessage: 'Could not load messages.',
          ),
        ),
      );
    }
  }

  List<ChatMessage> _appendMessage(
    List<ChatMessage> messages,
    ChatMessage message,
  ) {
    final nextMessages = [...messages, message];
    if (nextMessages.length <= _maxRetainedMessages) {
      return nextMessages;
    }
    return nextMessages.sublist(nextMessages.length - _maxRetainedMessages);
  }

  String _clientMessageId() => 'client_${_uuid.v4()}';
}
