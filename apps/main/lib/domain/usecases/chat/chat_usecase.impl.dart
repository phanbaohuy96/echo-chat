part of 'chat_usecase.dart';

@Injectable(as: ChatUsecase)
class ChatInteractorImpl extends ChatUsecase {
  ChatInteractorImpl(this.appApiService);

  final AppApiService appApiService;

  @override
  Future<ChatUsersResponse> getPeers() async {
    return ChatUsersResponse.fromJson(await appApiService.getChatUsers());
  }

  @override
  Future<ChatConversationResponse> getConversation(String peerUserId) async {
    return ChatConversationResponse.fromJson(
      await appApiService.getChatMessages(peerUserId),
    );
  }

  @override
  Future<SendMessageResponse> sendMessage({
    required String recipientUserId,
    required String clientMessageId,
    required String message,
  }) async {
    return SendMessageResponse.fromJson(
      await appApiService.sendChatMessage(
        SendMessageRequest(
          recipientUserId: recipientUserId,
          clientMessageId: clientMessageId,
          message: message,
        ).toJson(),
      ),
    );
  }
}
