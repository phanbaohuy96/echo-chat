import 'package:core/core.dart';
import 'package:data_source/data_source.dart';
import 'package:injectable/injectable.dart';

import '../../../../domain/entities/chat/chat_conversation_sync.dart';
import 'data_access_object.dart';

@injectable
class ChatConversationSyncDao extends DAO {
  ChatConversationSyncDao(super.db);

  static const peerUserId = 'peer_user_id';
  static const latestMessageCreatedAt = 'latest_message_created_at';
  static const oldestMessageCreatedAt = 'oldest_message_created_at';
  static const hasMoreOlder = 'has_more_older';
  static const lastSyncedAt = 'last_synced_at';

  @override
  String get tableName => SqliteTable.chatConversationSync.name;

  static String get createTableQuery =>
      '''
    CREATE TABLE IF NOT EXISTS ${SqliteTable.chatConversationSync.name} (
      $peerUserId TEXT PRIMARY KEY NOT NULL,
      $latestMessageCreatedAt INTEGER,
      $oldestMessageCreatedAt INTEGER,
      $hasMoreOlder INTEGER NOT NULL DEFAULT 1,
      $lastSyncedAt INTEGER
    )
  ''';

  @override
  String get createQuery => createTableQuery;

  @override
  List<DataColumn> get columns => [
    DataColumn(name: peerUserId, type: DataType.text, isPrimary: true),
    DataColumn(name: latestMessageCreatedAt, type: DataType.int),
    DataColumn(name: oldestMessageCreatedAt, type: DataType.int),
    DataColumn(name: hasMoreOlder, type: DataType.int, notNull: true),
    DataColumn(name: lastSyncedAt, type: DataType.int),
  ];

  Future<ChatConversationSync?> getSync(String peerUserId) async {
    final rows = await execute(
      () => db.query(
        tableName,
        where: '${ChatConversationSyncDao.peerUserId} = ?',
        whereArgs: [peerUserId],
        limit: 1,
      ),
    );
    if (rows.isEmpty) {
      return null;
    }
    return _fromRow(rows.first);
  }

  Future<void> updateFromRemote({
    required String peerUserId,
    required ChatConversationSyncMetadataDto metadata,
    DateTime? fallbackLatestCreatedAt,
    DateTime? fallbackOldestCreatedAt,
  }) async {
    final existing = await getSync(peerUserId);
    final latest = _maxDateTime(
      existing?.latestMessageCreatedAt,
      metadata.latestMessageCreatedAt ?? fallbackLatestCreatedAt,
    );
    final oldest = _minDateTime(
      existing?.oldestMessageCreatedAt,
      metadata.oldestMessageCreatedAt ?? fallbackOldestCreatedAt,
    );
    final preserveExistingOlderState =
        existing != null &&
        (metadata.oldestMessageCreatedAt == null ||
            existing.oldestMessageCreatedAt?.isBefore(
                  metadata.oldestMessageCreatedAt!,
                ) ==
                true);
    final values = {
      ChatConversationSyncDao.peerUserId: peerUserId,
      latestMessageCreatedAt: latest?.millisecondsSinceEpoch,
      oldestMessageCreatedAt: oldest?.millisecondsSinceEpoch,
      hasMoreOlder:
          (preserveExistingOlderState
              ? existing.hasMoreOlder
              : metadata.hasMoreOlder)
          ? 1
          : 0,
      lastSyncedAt: DateTime.now().millisecondsSinceEpoch,
    };
    await execute(
      () => db.insert(
        tableName,
        values,
        conflictAlgorithm: ConflictAlgorithm.replace,
      ),
    );
  }

  Future<void> updateAfterLocalSent({
    required String peerUserId,
    required DateTime createdAt,
  }) async {
    final existing = await getSync(peerUserId);
    final latest = _maxDateTime(existing?.latestMessageCreatedAt, createdAt);
    final oldest = _minDateTime(existing?.oldestMessageCreatedAt, createdAt);
    final values = {
      ChatConversationSyncDao.peerUserId: peerUserId,
      latestMessageCreatedAt: latest?.millisecondsSinceEpoch,
      oldestMessageCreatedAt: oldest?.millisecondsSinceEpoch,
      hasMoreOlder: (existing?.hasMoreOlder ?? true) ? 1 : 0,
      lastSyncedAt: DateTime.now().millisecondsSinceEpoch,
    };
    await execute(
      () => db.insert(
        tableName,
        values,
        conflictAlgorithm: ConflictAlgorithm.replace,
      ),
    );
  }

  /// Deletes every cached conversation sync metadata row.
  Future<void> clearAll() {
    return clearTable();
  }

  ChatConversationSync _fromRow(Map<String, Object?> row) {
    return ChatConversationSync(
      peerUserId: row[peerUserId] as String,
      latestMessageCreatedAt: _fromMilliseconds(row[latestMessageCreatedAt]),
      oldestMessageCreatedAt: _fromMilliseconds(row[oldestMessageCreatedAt]),
      hasMoreOlder: (row[hasMoreOlder] as int) == 1,
      lastSyncedAt: _fromMilliseconds(row[lastSyncedAt]),
    );
  }

  DateTime? _fromMilliseconds(Object? value) {
    if (value == null) {
      return null;
    }
    return DateTime.fromMillisecondsSinceEpoch(value as int);
  }

  DateTime? _maxDateTime(DateTime? left, DateTime? right) {
    if (left == null) {
      return right;
    }
    if (right == null) {
      return left;
    }
    return left.isAfter(right) ? left : right;
  }

  DateTime? _minDateTime(DateTime? left, DateTime? right) {
    if (left == null) {
      return right;
    }
    if (right == null) {
      return left;
    }
    return left.isBefore(right) ? left : right;
  }
}
