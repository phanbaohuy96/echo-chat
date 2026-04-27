import 'package:core/core.dart';
import 'package:data_source/data_source.dart';
import 'package:injectable/injectable.dart';

import '../../../../domain/entities/chat/local_chat_message.dart';
import 'data_access_object.dart';

@injectable
class ChatMessageDao extends DAO {
  ChatMessageDao(super.db);

  static const localId = 'local_id';
  static const remoteId = 'remote_id';
  static const clientMessageId = 'client_message_id';
  static const conversationPeerUserId = 'conversation_peer_user_id';
  static const senderUserId = 'sender_user_id';
  static const recipientUserId = 'recipient_user_id';
  static const message = 'message';
  static const createdAt = 'created_at';
  static const updatedAt = 'updated_at';
  static const deletedAt = 'deleted_at';
  static const version = 'version';
  static const status = 'status';
  static const errorMessage = 'error_message';

  @override
  String get tableName => SqliteTable.chatMessage.name;

  static String get createTableQuery =>
      '''
    CREATE TABLE IF NOT EXISTS ${SqliteTable.chatMessage.name} (
      $localId INTEGER PRIMARY KEY AUTOINCREMENT,
      $remoteId TEXT,
      $clientMessageId TEXT NOT NULL,
      $conversationPeerUserId TEXT NOT NULL,
      $senderUserId TEXT NOT NULL,
      $recipientUserId TEXT NOT NULL,
      $message TEXT NOT NULL,
      $createdAt INTEGER NOT NULL,
      $updatedAt INTEGER,
      $deletedAt INTEGER,
      $version INTEGER NOT NULL DEFAULT 1,
      $status TEXT NOT NULL,
      $errorMessage TEXT
    )
  ''';

  static List<String> get createIndexQueries => [
    '''
      CREATE UNIQUE INDEX IF NOT EXISTS idx_chat_message_client_message_id
      ON ${SqliteTable.chatMessage.name} ($clientMessageId)
    ''',
    '''
      CREATE UNIQUE INDEX IF NOT EXISTS idx_chat_message_remote_id
      ON ${SqliteTable.chatMessage.name} ($remoteId)
      WHERE $remoteId IS NOT NULL
    ''',
    '''
      CREATE INDEX IF NOT EXISTS idx_chat_message_conversation
      ON ${SqliteTable.chatMessage.name} ($conversationPeerUserId, $createdAt, $localId)
    ''',
  ];

  @override
  String get createQuery => createTableQuery;

  @override
  Future<void> create() async {
    await super.create();
    for (final query in createIndexQueries) {
      await db.database.execute(query);
    }
  }

  @override
  List<DataColumn> get columns => [
    DataColumn(name: localId, type: DataType.int, isPrimary: true),
    DataColumn(name: remoteId, type: DataType.text),
    DataColumn(name: clientMessageId, type: DataType.text, notNull: true),
    DataColumn(
      name: conversationPeerUserId,
      type: DataType.text,
      notNull: true,
    ),
    DataColumn(name: senderUserId, type: DataType.text, notNull: true),
    DataColumn(name: recipientUserId, type: DataType.text, notNull: true),
    DataColumn(name: message, type: DataType.text, notNull: true),
    DataColumn(name: createdAt, type: DataType.int, notNull: true),
    DataColumn(name: updatedAt, type: DataType.int),
    DataColumn(name: deletedAt, type: DataType.int),
    DataColumn(name: version, type: DataType.int, notNull: true),
    DataColumn(name: status, type: DataType.text, notNull: true),
    DataColumn(name: errorMessage, type: DataType.text),
  ];

  Future<LocalChatMessage> insertPending({
    required String clientMessageId,
    required String conversationPeerUserId,
    required String senderUserId,
    required String recipientUserId,
    required String message,
    required DateTime createdAt,
  }) async {
    final values = {
      remoteId: null,
      ChatMessageDao.clientMessageId: clientMessageId,
      ChatMessageDao.conversationPeerUserId: conversationPeerUserId,
      ChatMessageDao.senderUserId: senderUserId,
      ChatMessageDao.recipientUserId: recipientUserId,
      ChatMessageDao.message: message,
      ChatMessageDao.createdAt: createdAt.millisecondsSinceEpoch,
      updatedAt: null,
      deletedAt: null,
      version: 1,
      status: ChatMessageStatus.pending.name,
      errorMessage: null,
    };
    await execute(
      () => db.insert(
        tableName,
        values,
        conflictAlgorithm: ConflictAlgorithm.replace,
      ),
    );
    return (await getMessage(clientMessageId))!;
  }

  Future<void> upsertRemoteMessages(
    List<ChatMessageDto> messages, {
    required String currentUserId,
  }) async {
    if (messages.isEmpty) {
      return;
    }
    await execute(() async {
      final batch = db.database.batch();
      for (final remoteMessage in messages) {
        batch.insert(
          tableName,
          _toRow(
            LocalChatMessage.fromRemote(
              remoteMessage,
              currentUserId: currentUserId,
            ),
          ),
          conflictAlgorithm: ConflictAlgorithm.replace,
        );
      }
      await batch.commit(noResult: true);
    });
  }

  Future<void> markSent({
    required String clientMessageId,
    required ChatMessageDto remoteMessage,
    required String currentUserId,
  }) async {
    await execute(
      () => _upsertRemoteMessage(remoteMessage, currentUserId: currentUserId),
    );
  }

  Future<void> markPending(String clientMessageId) async {
    await execute(
      () => db.update(
        tableName,
        {status: ChatMessageStatus.pending.name, errorMessage: null},
        where: '${ChatMessageDao.clientMessageId} = ?',
        whereArgs: [clientMessageId],
      ),
    );
  }

  Future<void> markFailed({
    required String clientMessageId,
    required String errorMessage,
  }) async {
    await execute(
      () => db.update(
        tableName,
        {
          status: ChatMessageStatus.failed.name,
          ChatMessageDao.errorMessage: errorMessage,
        },
        where: '${ChatMessageDao.clientMessageId} = ?',
        whereArgs: [clientMessageId],
      ),
    );
  }

  Future<List<LocalChatMessage>> getConversation(
    String peerUserId, {
    int limit = 80,
  }) async {
    final rows = await execute(
      () => db.query(
        tableName,
        where: '$conversationPeerUserId = ?',
        whereArgs: [peerUserId],
        orderBy: '$createdAt DESC, $localId DESC',
        limit: limit,
      ),
    );
    return rows.reversed.map(_fromRow).toList();
  }

  Future<List<LocalChatMessage>> getOlderConversationPage(
    String peerUserId, {
    required DateTime beforeCreatedAt,
    int limit = 50,
  }) async {
    final rows = await execute(
      () => db.query(
        tableName,
        where: '$conversationPeerUserId = ? AND $createdAt < ?',
        whereArgs: [peerUserId, beforeCreatedAt.millisecondsSinceEpoch],
        orderBy: '$createdAt DESC, $localId DESC',
        limit: limit,
      ),
    );
    return rows.reversed.map(_fromRow).toList();
  }

  Future<DateTime?> getNewestCreatedAt(String peerUserId) async {
    final rows = await execute(
      () => db.query(
        tableName,
        columns: [createdAt],
        where: '$conversationPeerUserId = ?',
        whereArgs: [peerUserId],
        orderBy: '$createdAt DESC, $localId DESC',
        limit: 1,
      ),
    );
    if (rows.isEmpty) {
      return null;
    }
    return DateTime.fromMillisecondsSinceEpoch(rows.first[createdAt] as int);
  }

  Future<DateTime?> getOldestCreatedAt(String peerUserId) async {
    final rows = await execute(
      () => db.query(
        tableName,
        columns: [createdAt],
        where: '$conversationPeerUserId = ?',
        whereArgs: [peerUserId],
        orderBy: '$createdAt ASC, $localId ASC',
        limit: 1,
      ),
    );
    if (rows.isEmpty) {
      return null;
    }
    return DateTime.fromMillisecondsSinceEpoch(rows.first[createdAt] as int);
  }

  Future<LocalChatMessage?> getMessage(String clientMessageId) async {
    final rows = await execute(
      () => db.query(
        tableName,
        where: '${ChatMessageDao.clientMessageId} = ?',
        whereArgs: [clientMessageId],
        limit: 1,
      ),
    );
    if (rows.isEmpty) {
      return null;
    }
    return _fromRow(rows.first);
  }

  Future<List<LocalChatMessage>> getOutbox({String? peerUserId}) async {
    final where = peerUserId == null
        ? '$status = ?'
        : '$status = ? AND $conversationPeerUserId = ?';
    final whereArgs = peerUserId == null
        ? [ChatMessageStatus.pending.name]
        : [ChatMessageStatus.pending.name, peerUserId];
    final rows = await execute(
      () => db.query(
        tableName,
        where: where,
        whereArgs: whereArgs,
        orderBy: '$createdAt ASC, $localId ASC',
      ),
    );
    return rows.map(_fromRow).toList();
  }

  /// Returns the total number of cached local chat messages.
  Future<int> countMessages() {
    return count();
  }

  /// Returns the number of locally queued messages waiting to be sent.
  Future<int> countPendingMessages() {
    return count(
      where: '$status = ?',
      whereArgs: [ChatMessageStatus.pending.name],
    );
  }

  /// Returns the number of locally queued messages that failed to send.
  Future<int> countFailedMessages() {
    return count(
      where: '$status = ?',
      whereArgs: [ChatMessageStatus.failed.name],
    );
  }

  /// Returns the newest cached message timestamp across all conversations.
  Future<DateTime?> getGlobalNewestCreatedAt() {
    return _getGlobalCreatedAt('MAX');
  }

  /// Returns the oldest cached message timestamp across all conversations.
  Future<DateTime?> getGlobalOldestCreatedAt() {
    return _getGlobalCreatedAt('MIN');
  }

  /// Deletes every cached local chat message row.
  Future<void> clearAll() {
    return clearTable();
  }

  Future<DateTime?> _getGlobalCreatedAt(String functionName) async {
    final rows = await execute(
      () => db.database.rawQuery(
        'SELECT $functionName($createdAt) AS $createdAt FROM $tableName',
      ),
    );
    final value = rows.first[createdAt] as int?;
    if (value == null) {
      return null;
    }
    return DateTime.fromMillisecondsSinceEpoch(value);
  }

  Future<void> _upsertRemoteMessage(
    ChatMessageDto remoteMessage, {
    required String currentUserId,
  }) {
    final localMessage = LocalChatMessage.fromRemote(
      remoteMessage,
      currentUserId: currentUserId,
    );
    return db.insert(
      tableName,
      _toRow(localMessage),
      conflictAlgorithm: ConflictAlgorithm.replace,
    );
  }

  Map<String, Object?> _toRow(LocalChatMessage message) {
    return {
      localId: message.localId,
      remoteId: message.remoteId,
      clientMessageId: message.clientMessageId,
      conversationPeerUserId: message.conversationPeerUserId,
      senderUserId: message.senderUserId,
      recipientUserId: message.recipientUserId,
      ChatMessageDao.message: message.message,
      createdAt: message.createdAt.millisecondsSinceEpoch,
      updatedAt: message.updatedAt?.millisecondsSinceEpoch,
      deletedAt: message.deletedAt?.millisecondsSinceEpoch,
      version: message.version,
      status: message.status.name,
      errorMessage: message.errorMessage,
    }..removeWhere((key, value) => key == localId && value == null);
  }

  DateTime? _fromMilliseconds(Object? value) {
    if (value == null) {
      return null;
    }
    return DateTime.fromMillisecondsSinceEpoch(value as int);
  }

  LocalChatMessage _fromRow(Map<String, Object?> row) {
    return LocalChatMessage(
      localId: row[localId] as int?,
      remoteId: row[remoteId] as String?,
      clientMessageId: row[clientMessageId] as String,
      conversationPeerUserId: row[conversationPeerUserId] as String,
      senderUserId: row[senderUserId] as String,
      recipientUserId: row[recipientUserId] as String,
      message: row[message] as String,
      createdAt: DateTime.fromMillisecondsSinceEpoch(row[createdAt] as int),
      updatedAt: _fromMilliseconds(row[updatedAt]),
      deletedAt: _fromMilliseconds(row[deletedAt]),
      version: (row[version] as int?) ?? 1,
      status: ChatMessageStatus.values.byName(row[status] as String),
      errorMessage: row[errorMessage] as String?,
    );
  }
}
