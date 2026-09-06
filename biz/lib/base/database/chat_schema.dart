import 'package:sqflite_sqlcipher/sqflite.dart';
import '../crypt/security.dart';

/// Schema changes run inside openDatabase's creation/upgrade transaction.
class ChatSchema {
  static String get sessionsSql =>
      '''
    CREATE TABLE IF NOT EXISTS ${Security.security_chat_sessions} (
      ${Security.security_id}  TEXT NOT NULL,
      ${Security.security_ownerId}  INTEGER,
      ${Security.security_name}  TEXT,
      ${Security.security_avatar}  TEXT,
      ${Security.security_lastMessageTime}  INTEGER,
      ${Security.security_lastMessageText}  TEXT,
      ${Security.security_backgroundUrl}  TEXT,
      ${Security.security_unreadNumber}  INTEGER DEFAULT 0,
      ${Security.security_accountType}  INTEGER DEFAULT 1,
      ${Security.security_type}  INTEGER DEFAULT 0,
      ${Security.security_level}  INTEGER DEFAULT 1,
      ${Security.security_nextLevelRatio} INTEGER DEFAULT 0,
      ${Security.security_draft} TEXT,
      ${Security.security_bio} TEXT,
      PRIMARY KEY (${Security.security_ownerId}, ${Security.security_id})
    )
  ''';

  static String get messagesSql =>
      '''
      CREATE TABLE IF NOT EXISTS ${Security.security_chat_message} (
        ${Security.security_id} INTEGER NOT NULL,
        ${Security.security_ownerId} INTEGER NOT NULL,
        ${Security.security_senderId} INTEGER NOT NULL,
        ${Security.security_receiverId} INTEGER NOT NULL,
        ${Security.security_type} INTEGER NOT NULL,
        ${Security.security_sessionId} TEXT NOT NULL,
        ${Security.security_date} INTEGER NOT NULL,
        ${Security.security_nativeId} TEXT,
        ${Security.security_content}  TEXT,
        ${Security.security_sendState}  INTEGER NOT NULL DEFAULT 0,
        ${Security.security_info}  TEXT,
        ${Security.security_lockInfo}  TEXT,
        ${Security.security_uuid}  TEXT,
        ${Security.security_renewInfo}  TEXT,
        ${Security.security_like}  INTEGER NOT NULL DEFAULT 0,
        ${Security.security_name}  TEXT,
        ${Security.security_avatar}  TEXT,
        ${Security.security_sessionType}  INTEGER DEFAULT 0,
        PRIMARY KEY (${Security.security_ownerId}, ${Security.security_id})
      )
    ''';

  static Future<void> create(DatabaseExecutor db) async {
    await db.execute(sessionsSql);
    await db.execute(messagesSql);
  }

  static Future<void> upgrade(DatabaseExecutor db, int oldVersion) async {
    if (oldVersion >= 2) return;
    await _rebuild(db, Security.security_chat_sessions, sessionsSql);
    await _rebuild(db, Security.security_chat_message, messagesSql);
  }

  static Future<void> _rebuild(
    DatabaseExecutor db,
    String table,
    String sql,
  ) async {
    final columns = await db.rawQuery('PRAGMA table_info("$table")');
    if (columns.isEmpty) {
      await db.execute(sql);
      return;
    }
    final oldTable = '${table}_v1';
    await db.execute('ALTER TABLE "$table" RENAME TO "$oldTable"');
    await db.execute(sql);
    final newColumns = await db.rawQuery('PRAGMA table_info("$table")');
    final names = newColumns.map((row) => row['name']).toSet();
    final common = columns
        .map((row) => row['name'] as String)
        .where(names.contains)
        .map((name) => '"$name"')
        .join(', ');
    // Missing optional legacy columns receive the new schema defaults.
    await db.execute(
      'INSERT INTO "$table" ($common) SELECT $common FROM "$oldTable"',
    );
    await db.execute('DROP TABLE "$oldTable"');
  }
}
