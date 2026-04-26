enum SqliteTable {
  user('user'),
  chatPeer('chatPeer'),
  chatMessage('chatMessage');

  const SqliteTable(this.name);

  final String name;
}
