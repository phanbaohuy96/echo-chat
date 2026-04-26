import '../models/chat_message.dart';
import '../models/user.dart';

class DemoStore {
  final Map<String, BackendUser> usersById = {};
  final Map<String, String> userIdsByUsername = {};
  final Map<String, String> userIdsByToken = {};
  final Map<String, BackendChatMessage> messagesById = {};
  final Map<String, List<String>> messageIdsByConversationKey = {};
  final Map<String, String> messageIdBySenderAndClientMessageId = {};
}

final demoStore = DemoStore();
