import '../../entities/chat/local_chat_message.dart';

/// Coordinates cached chat conversations and incremental message sync.
abstract class ChatConversationUsecase {
  /// Returns cached messages for [peerUserId] without contacting the backend.
  ///
  /// The result is limited to [limit] messages and may be stale until
  /// [refreshConversation] or [loadOlderMessages] updates the local cache.
  Future<List<LocalChatMessage>> getCachedConversation(
    String peerUserId, {
    int limit,
  });

  /// Fetches newer remote messages for [peerUserId] and merges them locally.
  ///
  /// If no current user is stored locally, this falls back to the cached
  /// conversation. On success, it returns the full cached conversation after
  /// the merge rather than only the remote delta.
  Future<List<LocalChatMessage>> refreshConversation(String peerUserId);

  /// Loads the next older message page for [peerUserId] when one is available.
  ///
  /// Paging state is scoped to the active peer; switching peers resets the
  /// older message cursor. The returned [messages] are the full cached
  /// conversation after any merge, not only the newly fetched page.
  Future<({List<LocalChatMessage> messages, bool hasMoreOlder})>
  loadOlderMessages(String peerUserId);

  /// Returns whether sync metadata indicates older messages may be available.
  ///
  /// When no metadata has been cached for [peerUserId], this returns `true` so
  /// the caller can attempt the first older-page load.
  Future<bool> hasMoreOlderMessages(String peerUserId);
}
