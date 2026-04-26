// ignore_for_file: unused_element, unused_element_parameter

part of 'chat_bloc.dart';

@freezed
sealed class _StateData with _$StateData {
  const factory _StateData({
    @Default([]) List<UserModel> peers,
    UserModel? selectedPeer,
    @Default([]) List<ChatMessage> messages,
    @Default(false) bool isLoadingPeers,
    @Default(false) bool isLoadingMessages,
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

  List<UserModel> get peers => data.peers;

  UserModel? get selectedPeer => data.selectedPeer;

  List<ChatMessage> get messages => data.messages;

  bool get isLoadingPeers => data.isLoadingPeers;

  bool get isLoadingMessages => data.isLoadingMessages;

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

  factory ChatMessage.fromDto(
    ChatMessageDto message, {
    required String? currentUserId,
  }) {
    return ChatMessage(
      text: message.message,
      isMine: message.senderUserId == currentUserId,
    );
  }

  final String text;
  final bool isMine;
}
