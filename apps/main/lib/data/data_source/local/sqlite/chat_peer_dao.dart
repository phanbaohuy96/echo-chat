import 'package:core/core.dart';
import 'package:data_source/data_source.dart';
import 'package:injectable/injectable.dart';

import 'data_access_object.dart';

@injectable
class ChatPeerDao extends DAO {
  ChatPeerDao(super.db);

  static const userId = 'user_id';
  static const name = 'name';
  static const username = 'username';
  static const syncedAt = 'synced_at';

  static String get createTableQuery =>
      '''
    CREATE TABLE IF NOT EXISTS ${SqliteTable.chatPeer.name} (
      $userId TEXT PRIMARY KEY NOT NULL,
      $name TEXT,
      $username TEXT,
      $syncedAt INTEGER NOT NULL
    )
  ''';

  @override
  String get tableName => SqliteTable.chatPeer.name;

  @override
  String get createQuery => createTableQuery;

  @override
  List<DataColumn> get columns => [
    DataColumn(name: userId, type: DataType.text, isPrimary: true),
    DataColumn(name: name, type: DataType.text),
    DataColumn(name: username, type: DataType.text),
    DataColumn(name: syncedAt, type: DataType.int, notNull: true),
  ];

  Future<void> upsertPeers(List<UserModel> peers) async {
    final now = DateTime.now().millisecondsSinceEpoch;
    await execute(() async {
      for (final peer in peers) {
        final id = peer.id;
        if (id == null || id.isEmpty) {
          continue;
        }
        await db.insert(tableName, {
          userId: id,
          name: peer.name,
          username: peer.username,
          syncedAt: now,
        }, conflictAlgorithm: ConflictAlgorithm.replace);
      }
    });
  }

  Future<List<UserModel>> getPeers() async {
    final rows = await execute(
      () => db.query(tableName, orderBy: '$username COLLATE NOCASE ASC'),
    );
    return rows.map(_peerFromRow).toList();
  }

  Future<UserModel?> getPeer(String id) async {
    final rows = await execute(
      () =>
          db.query(tableName, where: '$userId = ?', whereArgs: [id], limit: 1),
    );
    if (rows.isEmpty) {
      return null;
    }
    return _peerFromRow(rows.first);
  }

  /// Returns the number of cached chat peers.
  Future<int> countPeers() {
    return count();
  }

  /// Deletes every cached chat peer row.
  Future<void> clearAll() {
    return clearTable();
  }

  UserModel _peerFromRow(Map<String, Object?> row) {
    return UserModel(
      id: row[userId] as String?,
      name: row[name] as String?,
      username: row[username] as String?,
    );
  }
}
