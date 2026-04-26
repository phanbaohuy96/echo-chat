part of 'chat_bloc.dart';

abstract class ChatEvent {}

class ChatStartedEvent extends ChatEvent {}

class ChatPeerSelectedEvent extends ChatEvent {
  ChatPeerSelectedEvent(this.peer);

  final UserModel peer;
}

class ChatRefreshRequestedEvent extends ChatEvent {}

class ChatRetryRequestedEvent extends ChatEvent {
  ChatRetryRequestedEvent(this.clientMessageId);

  final String clientMessageId;
}

class ChatMessageSubmittedEvent extends ChatEvent {
  ChatMessageSubmittedEvent(this.message);

  final String message;
}
