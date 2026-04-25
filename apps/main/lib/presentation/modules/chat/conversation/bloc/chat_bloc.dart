import 'package:core/core.dart';
import 'package:freezed_annotation/freezed_annotation.dart';
import 'package:injectable/injectable.dart';

import '../../../../../domain/usecases/chat/chat_usecase.dart';
import '../../../../base/base.dart';

part 'chat_bloc.freezed.dart';
part 'chat_event.dart';
part 'chat_state.dart';

@Injectable()
class ChatBloc extends AppBlocBase<ChatEvent, ChatState> {
  ChatBloc(this._chatUsecase)
    : super(ChatInitial(data: _StateData.initial())) {
    on<ChatMessageSubmittedEvent>(_onChatMessageSubmittedEvent);
  }

  static const _maxRetainedMessages = 80;

  final ChatUsecase _chatUsecase;

  Future<void> _onChatMessageSubmittedEvent(
    ChatMessageSubmittedEvent event,
    Emitter<ChatState> emit,
  ) async {
    final message = event.message.trim();
    if (message.isEmpty || state.isSending) {
      return;
    }

    final userMessage = ChatMessage.user(message);
    emit(
      state.copyWith(
        data: state.data.copyWith(
          messages: _appendMessage(state.messages, userMessage),
          isSending: true,
          errorMessage: null,
        ),
      ),
    );

    try {
      final response = await _chatUsecase.sendMessage(message);
      emit(
        state.copyWith(
          data: state.data.copyWith(
            messages: _appendMessage(
              state.messages,
              ChatMessage.assistant(response.reply),
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
}
