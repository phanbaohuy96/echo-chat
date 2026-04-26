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
    @Default(false) bool isSyncing,
    @Default(false) bool isLoadingOlder,
    @Default(true) bool hasMoreOlder,
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

  bool get isSyncing => data.isSyncing;

  bool get isLoadingOlder => data.isLoadingOlder;

  bool get hasMoreOlder => data.hasMoreOlder;
}

class ChatInitial extends ChatState {
  ChatInitial({required _StateData data}) : super(data);
}

final _factories = <Type, Function(_StateData data)>{
  ChatInitial: (data) => ChatInitial(data: data),
};

class ChatMessage {
  const ChatMessage({
    required this.clientMessageId,
    required this.text,
    required this.isMine,
    required this.createdAt,
    required this.status,
    this.localId,
    this.remoteId,
    this.errorMessage,
  });

  factory ChatMessage.fromLocal(
    LocalChatMessage message, {
    required String? currentUserId,
  }) {
    return ChatMessage(
      localId: message.localId,
      remoteId: message.remoteId,
      clientMessageId: message.clientMessageId,
      text: message.message,
      isMine: message.isMine(currentUserId),
      createdAt: message.createdAt,
      status: message.status,
      errorMessage: message.errorMessage,
    );
  }

  final int? localId;
  final String? remoteId;
  final String clientMessageId;
  final String text;
  final bool isMine;
  final DateTime createdAt;
  final ChatMessageStatus status;
  final String? errorMessage;
}
