import '../../entities/chat/local_chat_message.dart';

/// Coordinates pending outbound chat messages and delivery retries.
abstract class ChatOutboxUsecase {
  /// Creates a local pending message without contacting the backend.
  ///
  /// The returned message is stored in the local outbox and can later be sent
  /// by [sendQueuedMessage], [syncQueuedMessage], or [syncOutbox].
  Future<LocalChatMessage> enqueueMessage({
    required String recipientUserId,
    required String clientMessageId,
    required String message,
    required String senderUserId,
  });

  /// Attempts to send one queued message and returns its conversation cache.
  ///
  /// The local message is marked sent or failed based on the backend result.
  /// If [clientMessageId] is not found locally, this returns an empty list.
  Future<List<LocalChatMessage>> sendQueuedMessage(String clientMessageId);

  /// Marks one failed message pending, retries delivery, and returns its cache.
  ///
  /// The local message is marked sent or failed based on the backend result.
  /// If [clientMessageId] is not found locally, this returns an empty list.
  Future<List<LocalChatMessage>> retryMessage(String clientMessageId);

  /// Attempts to deliver one queued message and updates its local status.
  ///
  /// This is a no-op when the message is missing or no current user is stored
  /// locally. Backend errors are captured on the local message as failed state.
  Future<void> syncQueuedMessage(String clientMessageId);

  /// Attempts to deliver all queued messages, optionally for one peer only.
  ///
  /// Each queued message is processed through [syncQueuedMessage].
  Future<void> syncOutbox({String? peerUserId});
}
