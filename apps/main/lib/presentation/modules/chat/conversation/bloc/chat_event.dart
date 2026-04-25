part of 'chat_bloc.dart';

abstract class ChatEvent {}

class ChatMessageSubmittedEvent extends ChatEvent {
  ChatMessageSubmittedEvent(this.message);

  final String message;
}
