// ignore_for_file: unused_element, unused_element_parameter

part of 'chat_bloc.dart';

@freezed
sealed class _StateData with _$StateData {
  const factory _StateData({
    @Default([
      ChatMessage.assistant(
        'Welcome to EchoChat. Sign up or sign in, then ask about Flutter, '
        'BLoC, auth, or env setup.',
      ),
    ])
    List<ChatMessage> messages,
    @Default(false) bool isSending,
    String? errorMessage,
  }) = __StateData;

  factory _StateData.initial() => const _StateData();
}

abstract class ChatState {
  ChatState(this.data);

  final _StateData data;

  T copyWith<T extends ChatState>({_StateData? data}) {
    return _factories[T == ChatState ? runtimeType : T]!(data ?? this.data);
  }

  List<ChatMessage> get messages => data.messages;

  bool get isSending => data.isSending;

  String? get errorMessage => data.errorMessage;
}

class ChatInitial extends ChatState {
  ChatInitial({required _StateData data}) : super(data);
}

final _factories = <Type, Function(_StateData data)>{
  ChatInitial: (data) => ChatInitial(data: data),
};

class ChatMessage {
  const ChatMessage({required this.text, required this.isMine});

  const ChatMessage.user(String text) : this(text: text, isMine: true);

  const ChatMessage.assistant(String text) : this(text: text, isMine: false);

  final String text;
  final bool isMine;
}
