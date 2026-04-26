import 'package:core/core.dart';
import 'package:flutter/foundation.dart';
import 'package:injectable/injectable.dart';
import 'package:sqflite_common_ffi_web/sqflite_ffi_web.dart';

import 'chat_conversation_sync_dao.dart';
import 'chat_message_dao.dart';
import 'chat_peer_dao.dart';
import 'data_access_object.dart';

@Singleton(as: SQLiteDatabase)
class SQLiteDatabaseImpl extends SQLiteDatabase {
  /// Version should be updated when database structure changed
  int get version => 4;

  String get name => 'local.db';

  Database? _db;

  SQLiteDatabaseImpl();

  @override
  Future<Database?> create({OnDatabaseCreateFn? onCreate}) async {
    if (_db != null && _db!.isOpen) {
      return _db;
    }

    if (kIsWeb) {
      databaseFactory = databaseFactoryFfiWeb;
    }

    final databasesPath = await getDatabasesPath();
    final path = '$databasesPath/$name';
    return _db = await openDatabase(
      path,
      version: version,
      onCreate: (Database db, int version) async {
        _isOpen = true;
        await onCreate?.call(db, version);
        await _createChatTables(db);
      },
      onConfigure: (Database db) async {
        await db.execute('PRAGMA foreign_keys = ON');
      },
      onUpgrade: (db, oldVersion, newVersion) async {
        if (oldVersion < 3) {
          await _createChatTables(db);
        }
        if (oldVersion < 4) {
          await _upgradeChatTablesToV4(db);
        }
      },
      onDowngrade: (db, oldVersion, newVersion) async {
        // TODO(template): handle downgrade database version
        // await db.execute(
        //   'DROP TABLE IF EXISTS ${SqliteTable.form.name}',
        // );
      },
    );
  }

  Future<void> _createChatTables(Database db) async {
    await db.execute(ChatPeerDao.createTableQuery);
    await db.execute(ChatMessageDao.createTableQuery);
    await db.execute(ChatConversationSyncDao.createTableQuery);
    for (final query in ChatMessageDao.createIndexQueries) {
      await db.execute(query);
    }
  }

  Future<void> _upgradeChatTablesToV4(Database db) async {
    await _addColumnIfMissing(
      db,
      SqliteTable.chatMessage.name,
      ChatMessageDao.updatedAt,
      'INTEGER',
    );
    await _addColumnIfMissing(
      db,
      SqliteTable.chatMessage.name,
      ChatMessageDao.deletedAt,
      'INTEGER',
    );
    await _addColumnIfMissing(
      db,
      SqliteTable.chatMessage.name,
      ChatMessageDao.version,
      'INTEGER NOT NULL DEFAULT 1',
    );
    await db.execute(ChatConversationSyncDao.createTableQuery);
  }

  Future<void> _addColumnIfMissing(
    Database db,
    String table,
    String column,
    String definition,
  ) async {
    final columns = await db.rawQuery('PRAGMA table_info($table)');
    final exists = columns.any((row) => row['name'] == column);
    if (!exists) {
      await db.execute('ALTER TABLE $table ADD COLUMN $column $definition');
    }
  }

  @override
  Future<void> close() async {
    if (isOpen && executingCount == 0) {
      await _db?.close();
    }
  }

  @override
  Database get database {
    assert(_db != null, 'Database should be created before using');
    return _db!;
  }

  @override
  bool get isOpen => _isOpen;

  var _isOpen = false;

  @override
  int get executingCount => _executingCount;

  var _executingCount = 0;

  @override
  Future<T> execute<T>(
    Future<T> Function() executable, {
    Future<void> Function()? create,
  }) async {
    await create?.call();

    _executingCount++;
    final result = await executable();
    _executingCount--;

    // await close();

    return result;
  }

  @override
  Future<List<Map<String, Object?>>> query(
    String table, {
    bool? distinct,
    List<String>? columns,
    String? where,
    List<Object?>? whereArgs,
    String? groupBy,
    String? having,
    String? orderBy,
    int? limit,
    int? offset,
  }) {
    return database.query(
      table,
      distinct: distinct,
      columns: columns,
      where: where,
      whereArgs: whereArgs,
      groupBy: groupBy,
      having: having,
      orderBy: orderBy,
      limit: limit,
      offset: offset,
    );
  }

  @override
  Future<int> delete(String table, {String? where, List<Object?>? whereArgs}) {
    return database.delete(table, where: where, whereArgs: whereArgs);
  }

  @override
  Future<int> insert(
    String table,
    Map<String, Object?> values, {
    String? nullColumnHack,
    ConflictAlgorithm? conflictAlgorithm,
  }) {
    return database.insert(
      table,
      values,
      nullColumnHack: nullColumnHack,
      conflictAlgorithm: conflictAlgorithm,
    );
  }

  @override
  Future<int> update(
    String table,
    Map<String, Object?> values, {
    String? where,
    List<Object?>? whereArgs,
    ConflictAlgorithm? conflictAlgorithm,
  }) {
    return database.update(
      table,
      values,
      where: where,
      whereArgs: whereArgs,
      conflictAlgorithm: conflictAlgorithm,
    );
  }
}
