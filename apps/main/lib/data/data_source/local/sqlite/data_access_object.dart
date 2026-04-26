enum SqliteTable {
  user('user'),
  chatPeer('chatPeer'),
  chatMessage('chatMessage'),
  chatConversationSync('chatConversationSync');

  const SqliteTable(this.name);

  final String name;
}
