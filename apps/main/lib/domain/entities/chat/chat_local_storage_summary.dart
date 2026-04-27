/// Counts and date bounds for EchoChat data cached on this device.
class ChatLocalStorageSummary {
  const ChatLocalStorageSummary({
    required this.peerCount,
    required this.messageCount,
    required this.pendingMessageCount,
    required this.failedMessageCount,
    this.oldestMessageCreatedAt,
    this.newestMessageCreatedAt,
  });

  /// Number of cached chat peers.
  final int peerCount;

  /// Number of cached chat messages.
  final int messageCount;

  /// Number of cached messages waiting to be sent.
  final int pendingMessageCount;

  /// Number of cached messages that failed to send.
  final int failedMessageCount;

  /// Oldest cached message creation time, if any messages are cached.
  final DateTime? oldestMessageCreatedAt;

  /// Newest cached message creation time, if any messages are cached.
  final DateTime? newestMessageCreatedAt;

  /// Whether there is no cached local chat data to clear.
  bool get isEmpty {
    return peerCount == 0 &&
        messageCount == 0 &&
        pendingMessageCount == 0 &&
        failedMessageCount == 0;
  }
}
