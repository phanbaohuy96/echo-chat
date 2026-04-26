import 'package:core/core.dart';
import 'package:data_source/data_source.dart';
import 'package:injectable/injectable.dart';

import '../../../data/data_source/local/local_data_manager.dart';
import '../../../data/repositories/chat/chat_local_repository.dart';
import '../../entities/chat/local_chat_message.dart';

part 'chat_usecase.impl.dart';

abstract class ChatUsecase {
  Future<List<UserModel>> getCachedPeers();

  Future<List<UserModel>> syncPeers();

  Future<List<LocalChatMessage>> getCachedConversation(String peerUserId);

  Future<List<LocalChatMessage>> syncConversation(String peerUserId);

  Future<LocalChatMessage> enqueueMessage({
    required String recipientUserId,
    required String clientMessageId,
    required String message,
    required String senderUserId,
  });

  Future<List<LocalChatMessage>> sendQueuedMessage(String clientMessageId);

  Future<List<LocalChatMessage>> retryMessage(String clientMessageId);

  Future<void> syncQueuedMessage(String clientMessageId);

  Future<void> syncOutbox({String? peerUserId});
}
