import 'package:biz/base/crypt/routes.dart';
import 'package:biz/base/crypt/other.dart';
import 'package:biz/base/crypt/security.dart';
import 'package:biz/core/account/account_service.dart';
import 'package:sqflite/sqflite.dart';

import '../../base/database/data_center.dart';
import '../../base/event_center/event_center.dart';
import 'chat_session.dart';

String kEventCenterDidCreatedNewSession = Security.security_kEventCenterDidCreatedNewSession;
String kEventCenterDidChangeSession = Security.security_kEventCenterDidChangeSession;
String kDidChangeSessionId = Security.security_kDidChangeSessionId;
String kEventCenterDidClearSessionNumber = Security.security_kEventCenterDidClearSessionNumber;
String kEventCenterDidDeleteSession = Security.security_kEventCenterDidDeleteSession;

class ChatSessionHandler {
  int get ownerId => AccountService.instance.account.userId;

  Database get database => DataCenter.instance.database;

  ChatSessionHandler() {
    Map createInfo = DataCenter.instance.createInfo;
    if (createInfo.isNotEmpty) {
      createTable();
    }

    Map upgradeInfo = DataCenter.instance.upgradeInfo;
    if (upgradeInfo.isNotEmpty) {
      upgradeTable();
    }
  }

  Future<void> createTable() async {
    Database database = DataCenter.instance.database;
    return await database.execute(createTableSql);
  }

  static String get tableName => Security.security_chat_sessions;

  static String get createTableSql => '''
    CREATE TABLE IF NOT EXISTS $tableName (
      ${Security.security_id}  TEXT PRIMARY KEY,
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
      ${Security.security_draft} TEXT
    )
  ''';

  //增删查改
  Future<int> upsertSession(ChatSession session) async {
    int ret = await database.insert(tableName, session.toDatabase(), conflictAlgorithm: ConflictAlgorithm.replace);
    EventCenter.instance.sendEvent(kEventCenterDidChangeSession, {kDidChangeSessionId: session.id});
    return ret;
  }

  String findSessionSqlByType(SessionType? sessionType) {
    if (sessionType == null) {
      return "";
    }
    switch (sessionType) {
      case SessionType.ai:
        return " AND ${Security.security_accountType} <> 0 AND ${Security.security_type} <> 2";
      case SessionType.real:
        return " AND ${Security.security_accountType} = 0 AND ${Security.security_type} <> 2";
      case SessionType.group:
        return " AND ${Security.security_type} = 2";
      case SessionType.all:
        return "";
    }
  }

  Future<List<ChatSession>> querySessions({String? sessionId, int? limit, int? offset, SessionType? type}) async {
    String where = '${Security.security_ownerId} = ?';
    if (sessionId != null) {
      where += " AND ${Security.security_id}  = '$sessionId'";
    } else {
      where += " AND ${Security.security_id} <> '$kOffChatSessionId'";
      where += " AND ${Security.security_id} <> '0' AND ${Security.security_id} <> ''";
    }
    where += findSessionSqlByType(type);

    if (offset != null && offset > 0) {
      where += " OFFSET $offset";
    }

    if (limit != null && limit > 0) {
      where += " LIMIT $limit";
    }

    final List<Map<String, dynamic>> sqlSessions = await database.query(
      tableName,
      where: where,
      whereArgs: [ownerId.toString()],
      orderBy: Other.security_lastMessageTime_DESC,
    );

    List<ChatSession> sessions = sqlSessions.map((element) => ChatSession.fromDatabase(element)).toList();
    return sessions;
  }

  Future<ChatSession?> querySession(String sessionId) async {
    List<ChatSession> sessions = await querySessions(sessionId: sessionId);
    return sessions.firstOrNull;
  }

  Future<void> upgradeTable() async {
    Map upgradeInfo = DataCenter.instance.upgradeInfo;
    int oldVersion = upgradeInfo[Security.security_oldVersion] as int;
    int newVersion = upgradeInfo[Security.security_newVersion] as int;

    for (int i = oldVersion; i < newVersion; i++) {
      int toVersion = i + 1;
      await upgradeToVersion(toVersion);
    }
  }

  Future<void> upgradeToVersion(int toVersion) async {
    if (toVersion == 3) {
      database.execute('ALTER TABLE $tableName ADD COLUMN ${Security.security_accountType}  INTEGER DEFAULT 1;');
    }
    if (toVersion == 4) {
      database.execute('ALTER TABLE $tableName ADD COLUMN ${Security.security_type}  INTEGER DEFAULT 0;');
      database.execute('ALTER TABLE $tableName ADD COLUMN ${Security.security_level} INTEGER DEFAULT 1;');
      database.execute('ALTER TABLE $tableName ADD COLUMN ${Security.security_nextLevelRatio} INTEGER DEFAULT 0;');
      database.execute('ALTER TABLE $tableName ADD COLUMN ${Security.security_draft} TEXT;');
    }
  }

  Future<int> unreadCount() async {
    try {
      final List<Map<String, dynamic>> ret = await database.rawQuery(
        'SELECT SUM(${Security.security_unreadNumber}) FROM $tableName WHERE ${Security.security_ownerId} = ?',
        [ownerId.toString()],
      );

      return ret.first[ret.first.keys.first] as int;
    } catch (e) {
      return 0;
    }
  }

  Future<int> clearUnreadCount({String? sessionId}) async {
    String sql = 'UPDATE $tableName SET ${Security.security_unreadNumber} = 0 WHERE ${Security.security_ownerId} = ?';
    if (sessionId != null) {
      sql += ' AND ${Security.security_id} = "$sessionId"';
    }
    final rowsAffected = await database.rawUpdate(sql, [
      ownerId.toString(),
    ]);
    if (sessionId == null && rowsAffected > 0) {
      EventCenter.instance.sendEvent(kEventCenterDidClearSessionNumber, {});
    }
    return rowsAffected;
  }

  Future<int> deleteSessionById(String id) async {
    int ret = await database.delete(tableName, where: "${Security.security_id}=?", whereArgs: [id]);
    if (ret > 0) {
      EventCenter.instance.sendEvent(kEventCenterDidDeleteSession, {kDidChangeSessionId: id});
    }
    return ret;
  }
}
