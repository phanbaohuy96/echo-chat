part of 'chat_usecase.dart';

@Injectable(as: ChatUsecase)
class ChatInteractorImpl extends ChatUsecase {
  ChatInteractorImpl(this.appApiService);

  final AppApiService appApiService;

  @override
  Future<SendMessageResponse> sendMessage(String message) async {
    return SendMessageResponse.fromJson(
      await appApiService.sendChatMessage(
        SendMessageRequest(message: message).toJson(),
      ),
    );
  }
}
