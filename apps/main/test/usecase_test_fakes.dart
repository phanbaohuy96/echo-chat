import 'package:core/core.dart';
import 'package:data_source/data_source.dart';
import 'package:flutter_core/data/data_source/local/local_data_manager.dart';
import 'package:flutter_core/data/data_source/local/preferences_helper/preferences_helper.dart';
import 'package:flutter_core/data/repositories/chat/chat_local_repository.dart';
import 'package:flutter_core/domain/entities/chat/chat_conversation_sync.dart';
import 'package:flutter_core/domain/entities/chat/chat_local_storage_summary.dart';
import 'package:flutter_core/domain/entities/chat/local_chat_message.dart';

class FakeCorePreferencesHelper extends CorePreferencesHelper {
  UserToken? savedToken;

  @override
  bool? get allowCookieConsent => null;

  @override
  Future<bool?> clearData() async => true;

  @override
  String? get domainReplacement => null;

  @override
  bool isFirstLaunch() => false;

  @override
  DateTime? get lastDayShowCookieConsent => null;

  @override
  Future<bool?> markLaunched() async => true;

  @override
  Future<bool?> saveLocalization(String? locale) async => true;

  @override
  Future<bool?> setCookieConsentAccepted(bool? accepted) async => true;

  @override
  Future<bool?> setDomainReplacement(String? domain) async => true;

  @override
  Future<bool?> setLastDayShowCookieConsent(DateTime? today) async => true;

  @override
  Future setToken(UserToken? value) async {
    savedToken = value;
    return true;
  }

  @override
  Future<bool?> setTheme(int themeMode) async => true;

  @override
  Future<UserToken?> get token async => savedToken;

  @override
  Future<bool?> unMarkLaunched() async => true;

  @override
  String? getLocalization() => null;

  @override
  int? getTheme() => null;
}

class FakePreferencesHelper extends PreferencesHelper {
  UserModel? savedUserInfo;

  @override
  UserModel? get userInfo => savedUserInfo;

  @override
  Future<bool> saveUserInfo(UserModel? user) async {
    savedUserInfo = user;
    return true;
  }
}

class TestLocalDataManager extends LocalDataManager {
  TestLocalDataManager({UserModel? userInfo})
    : appPreferences = FakePreferencesHelper(),
      corePreferences = FakeCorePreferencesHelper(),
      super(FakePreferencesHelper(), FakeCorePreferencesHelper()) {
    appPreferences.savedUserInfo = userInfo;
  }

  final FakePreferencesHelper appPreferences;
  final FakeCorePreferencesHelper corePreferences;

  @override
  UserModel? get userInfo => appPreferences.userInfo;

  @override
  Future<bool> saveUserInfo(UserModel? user) {
    return appPreferences.saveUserInfo(user);
  }

  @override
  Future<UserToken?> get token => corePreferences.token;

  @override
  Future setToken(UserToken? value) {
    return corePreferences.setToken(value);
  }
}

class FakeRestApiRepository implements RestApiRepository {
  Map<String, dynamic>? signinResponse;
  Map<String, dynamic>? signupResponse;
  Map<String, dynamic>? meResponse;
  Map<String, dynamic>? chatUsersResponse;
  Map<String, dynamic>? chatMessagesResponse;
  Map<String, dynamic>? deleteChatMessageResponse;
  Map<String, dynamic>? sendChatMessageResponse;
  Error? meError;
  Error? deleteChatMessageError;
  Error? sendChatMessageError;
  Map<String, dynamic>? lastSigninBody;
  Map<String, dynamic>? lastSignupBody;
  Map<String, dynamic>? lastSendChatMessageBody;
  String? lastDeletedMessageId;
  String? lastChatMessagesPeerUserId;
  String? lastAfterCreatedAt;
  String? lastAfterUpdatedAt;
  String? lastBeforeCreatedAt;
  int? lastChatMessagesLimit;

  @override
  Future<dynamic> getChatMessages(
    String peerUserId,
    String? afterCreatedAt,
    String? afterUpdatedAt,
    String? beforeCreatedAt,
    int? limit,
  ) async {
    lastChatMessagesPeerUserId = peerUserId;
    lastAfterCreatedAt = afterCreatedAt;
    lastAfterUpdatedAt = afterUpdatedAt;
    lastBeforeCreatedAt = beforeCreatedAt;
    lastChatMessagesLimit = limit;
    return chatMessagesResponse ??
        const ChatConversationResponse(
          peer: UserModel(id: 'peer'),
          messages: [],
          syncMetadata: ChatConversationSyncMetadataDto(),
        ).toJson();
  }

  @override
  Future<dynamic> deleteChatMessage(String messageId) async {
    lastDeletedMessageId = messageId;
    final error = deleteChatMessageError;
    if (error != null) {
      throw error;
    }
    return deleteChatMessageResponse ??
        DeleteMessageResponse(message: messageDto(id: messageId)).toJson();
  }

  @override
  Future<dynamic> getChatUsers() async {
    return chatUsersResponse ?? const ChatUsersResponse(users: []).toJson();
  }

  @override
  Future<dynamic> me() async {
    final error = meError;
    if (error != null) {
      throw error;
    }
    return meResponse ?? const MeResponseDto(user: UserModel()).toJson();
  }

  @override
  Future<dynamic> sendChatMessage(Map<String, dynamic> body) async {
    lastSendChatMessageBody = body;
    final error = sendChatMessageError;
    if (error != null) {
      throw error;
    }
    return sendChatMessageResponse ??
        SendMessageResponse(message: messageDto()).toJson();
  }

  @override
  Future<dynamic> signin(Map<String, dynamic> body) async {
    lastSigninBody = body;
    return signinResponse ?? authResultDto().toJson();
  }

  @override
  Future<dynamic> signup(Map<String, dynamic> body) async {
    lastSignupBody = body;
    return signupResponse ?? authResultDto().toJson();
  }
}

class FakeChatLocalRepository implements ChatLocalRepository {
  List<UserModel> cachedPeers = [];
  List<UserModel>? cachedPeerInput;
  final syncs = <String, ChatConversationSync?>{};
  final messages = <String, LocalChatMessage>{};
  ChatLocalStorageSummary storageSummary = const ChatLocalStorageSummary(
    peerCount: 0,
    messageCount: 0,
    pendingMessageCount: 0,
    failedMessageCount: 0,
  );
  bool cleared = false;
  int deleteLocalOnlyMessageCount = 0;
  int markPendingCount = 0;
  int markSentCount = 0;
  int markFailedCount = 0;
  int cacheRemoteConversationCount = 0;
  String? lastDeletedLocalOnlyClientMessageId;
  String? lastOutboxPeerUserId;
  String? lastMarkedFailedClientMessageId;
  String? lastMarkedFailedErrorMessage;
  String? lastMarkedSentClientMessageId;
  ChatMessageDto? lastCachedRemoteMessage;
  String? lastCachedRemoteMessageCurrentUserId;
  ChatMessageDto? lastMarkedSentRemoteMessage;
  String? lastMarkedSentCurrentUserId;
  ChatConversationResponse? lastCachedRemoteConversation;
  String? lastCachedRemoteCurrentUserId;

  @override
  Future<List<UserModel>> getCachedPeers() async => cachedPeers;

  @override
  Future<void> cachePeers(List<UserModel> peers) async {
    cachedPeerInput = peers;
    cachedPeers = peers;
  }

  @override
  Future<UserModel?> getCachedPeer(String userId) async {
    for (final peer in cachedPeers) {
      if (peer.id == userId) {
        return peer;
      }
    }
    return null;
  }

  @override
  Future<List<LocalChatMessage>> getCachedConversation(
    String peerUserId, {
    int limit = 80,
  }) async {
    final conversation = _conversationMessages(peerUserId).toList();
    if (conversation.length <= limit) {
      return conversation;
    }
    return conversation.sublist(conversation.length - limit);
  }

  @override
  Future<List<LocalChatMessage>> getOlderConversationPage(
    String peerUserId, {
    required DateTime beforeCreatedAt,
    int limit = 50,
  }) async {
    return _conversationMessages(peerUserId)
        .where((message) => message.createdAt.isBefore(beforeCreatedAt))
        .take(limit)
        .toList();
  }

  @override
  Future<ChatConversationSync?> getConversationSync(String peerUserId) async {
    return syncs[peerUserId];
  }

  @override
  Future<DateTime?> getNewestMessageCreatedAt(String peerUserId) async {
    final conversation = _conversationMessages(peerUserId).toList();
    if (conversation.isEmpty) {
      return null;
    }
    return conversation
        .map((message) => message.createdAt)
        .reduce((left, right) => left.isAfter(right) ? left : right);
  }

  @override
  Future<DateTime?> getOldestMessageCreatedAt(String peerUserId) async {
    final conversation = _conversationMessages(peerUserId).toList();
    if (conversation.isEmpty) {
      return null;
    }
    return conversation
        .map((message) => message.createdAt)
        .reduce((left, right) => left.isBefore(right) ? left : right);
  }

  @override
  Future<LocalChatMessage> enqueueMessage({
    required String clientMessageId,
    required String senderUserId,
    required String recipientUserId,
    required String message,
  }) async {
    final localMessage = LocalChatMessage(
      clientMessageId: clientMessageId,
      conversationPeerUserId: recipientUserId,
      senderUserId: senderUserId,
      recipientUserId: recipientUserId,
      message: message,
      createdAt: DateTime(2026),
      status: ChatMessageStatus.pending,
    );
    messages[clientMessageId] = localMessage;
    return localMessage;
  }

  @override
  Future<void> cacheRemoteConversation({
    required UserModel peer,
    required List<ChatMessageDto> messages,
    required ChatConversationSyncMetadataDto syncMetadata,
    required String currentUserId,
  }) async {
    cacheRemoteConversationCount++;
    lastCachedRemoteCurrentUserId = currentUserId;
    lastCachedRemoteConversation = ChatConversationResponse(
      peer: peer,
      messages: messages,
      syncMetadata: syncMetadata,
    );
    final peerUserId = peer.id;
    if (peerUserId == null) {
      return;
    }
    for (final message in messages) {
      final localMessage = LocalChatMessage.fromRemote(
        message,
        currentUserId: currentUserId,
      );
      this.messages[localMessage.clientMessageId] = localMessage;
    }
    syncs[peerUserId] = ChatConversationSync(
      peerUserId: peerUserId,
      latestMessageCreatedAt: syncMetadata.latestMessageCreatedAt,
      latestMessageUpdatedAt: syncMetadata.latestMessageUpdatedAt,
      oldestMessageCreatedAt: syncMetadata.oldestMessageCreatedAt,
      hasMoreOlder: syncMetadata.hasMoreOlder,
    );
  }

  @override
  Future<void> deleteLocalOnlyMessage(String clientMessageId) async {
    deleteLocalOnlyMessageCount++;
    lastDeletedLocalOnlyClientMessageId = clientMessageId;
    messages.remove(clientMessageId);
  }

  @override
  Future<void> cacheRemoteMessage({
    required ChatMessageDto message,
    required String currentUserId,
  }) async {
    lastCachedRemoteMessage = message;
    lastCachedRemoteMessageCurrentUserId = currentUserId;
    final localMessage = LocalChatMessage.fromRemote(
      message,
      currentUserId: currentUserId,
    );
    messages[localMessage.clientMessageId] = localMessage;
  }

  @override
  Future<void> markSent({
    required String clientMessageId,
    required ChatMessageDto remoteMessage,
    required String currentUserId,
  }) async {
    markSentCount++;
    lastMarkedSentClientMessageId = clientMessageId;
    lastMarkedSentRemoteMessage = remoteMessage;
    lastMarkedSentCurrentUserId = currentUserId;
    final localMessage = LocalChatMessage.fromRemote(
      remoteMessage,
      currentUserId: currentUserId,
    );
    messages[clientMessageId] = localMessage;
  }

  @override
  Future<void> markPending(String clientMessageId) async {
    markPendingCount++;
    final message = messages[clientMessageId];
    if (message == null) {
      return;
    }
    messages[clientMessageId] = copyMessage(
      message,
      status: ChatMessageStatus.pending,
      errorMessage: null,
    );
  }

  @override
  Future<void> markFailed({
    required String clientMessageId,
    required String errorMessage,
  }) async {
    markFailedCount++;
    lastMarkedFailedClientMessageId = clientMessageId;
    lastMarkedFailedErrorMessage = errorMessage;
    final message = messages[clientMessageId];
    if (message == null) {
      return;
    }
    messages[clientMessageId] = copyMessage(
      message,
      status: ChatMessageStatus.failed,
      errorMessage: errorMessage,
    );
  }

  @override
  Future<LocalChatMessage?> getMessage(String clientMessageId) async {
    return messages[clientMessageId];
  }

  @override
  Future<List<LocalChatMessage>> getOutbox({String? peerUserId}) async {
    lastOutboxPeerUserId = peerUserId;
    return messages.values
        .where((message) => message.status == ChatMessageStatus.pending)
        .where(
          (message) =>
              peerUserId == null ||
              message.conversationPeerUserId == peerUserId,
        )
        .toList();
  }

  @override
  Future<ChatLocalStorageSummary> getStorageSummary() async => storageSummary;

  @override
  Future<void> clearAllCachedData() async {
    cleared = true;
  }

  Iterable<LocalChatMessage> _conversationMessages(String peerUserId) {
    final conversation = messages.values.where(
      (message) => message.conversationPeerUserId == peerUserId,
    );
    return conversation.toList()..sort((left, right) {
      final createdAtCompare = left.createdAt.compareTo(right.createdAt);
      if (createdAtCompare != 0) {
        return createdAtCompare;
      }
      return (left.localId ?? 0).compareTo(right.localId ?? 0);
    });
  }
}

AuthResultDto authResultDto({
  UserToken? token,
  UserModel user = const UserModel(id: 'user'),
}) {
  return AuthResultDto(token: token ?? userToken(), user: user);
}

UserToken userToken([String accessToken = 'access-token']) {
  return UserToken(accessToken: accessToken, type: TokenType.bearer);
}

ChatMessageDto messageDto({
  String id = 'remote-message',
  String senderUserId = 'current-user',
  String recipientUserId = 'peer',
  String clientMessageId = 'client-message',
  String message = 'Hello',
  DateTime? createdAt,
  DateTime? updatedAt,
  DateTime? deletedAt,
  int version = 1,
}) {
  return ChatMessageDto(
    id: id,
    senderUserId: senderUserId,
    recipientUserId: recipientUserId,
    clientMessageId: clientMessageId,
    message: message,
    createdAt: createdAt ?? DateTime(2026),
    updatedAt: updatedAt,
    deletedAt: deletedAt,
    version: version,
  );
}

LocalChatMessage localMessage({
  String? remoteId = 'remote-message',
  String clientMessageId = 'client-message',
  String conversationPeerUserId = 'peer',
  String senderUserId = 'current-user',
  String recipientUserId = 'peer',
  String message = 'Hello',
  DateTime? createdAt,
  DateTime? updatedAt,
  DateTime? deletedAt,
  int version = 1,
  ChatMessageStatus status = ChatMessageStatus.sent,
  String? errorMessage,
}) {
  return LocalChatMessage(
    remoteId: remoteId,
    clientMessageId: clientMessageId,
    conversationPeerUserId: conversationPeerUserId,
    senderUserId: senderUserId,
    recipientUserId: recipientUserId,
    message: message,
    createdAt: createdAt ?? DateTime(2026),
    updatedAt: updatedAt,
    deletedAt: deletedAt,
    version: version,
    status: status,
    errorMessage: errorMessage,
  );
}

LocalChatMessage copyMessage(
  LocalChatMessage message, {
  String? messageText,
  DateTime? updatedAt,
  DateTime? deletedAt,
  ChatMessageStatus? status,
  String? errorMessage,
}) {
  return LocalChatMessage(
    localId: message.localId,
    remoteId: message.remoteId,
    clientMessageId: message.clientMessageId,
    conversationPeerUserId: message.conversationPeerUserId,
    senderUserId: message.senderUserId,
    recipientUserId: message.recipientUserId,
    message: messageText ?? message.message,
    createdAt: message.createdAt,
    updatedAt: updatedAt ?? message.updatedAt,
    deletedAt: deletedAt ?? message.deletedAt,
    version: message.version,
    status: status ?? message.status,
    errorMessage: errorMessage,
  );
}
