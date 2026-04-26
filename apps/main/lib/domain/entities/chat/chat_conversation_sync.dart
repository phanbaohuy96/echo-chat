class ChatConversationSync {
  const ChatConversationSync({
    required this.peerUserId,
    this.latestMessageCreatedAt,
    this.oldestMessageCreatedAt,
    this.hasMoreOlder = true,
    this.lastSyncedAt,
  });

  final String peerUserId;
  final DateTime? latestMessageCreatedAt;
  final DateTime? oldestMessageCreatedAt;
  final bool hasMoreOlder;
  final DateTime? lastSyncedAt;
}
