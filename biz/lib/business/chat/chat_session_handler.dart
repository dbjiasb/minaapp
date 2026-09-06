import 'package:biz/base/crypt/routes.dart';
import 'package:biz/base/crypt/other.dart';
import 'package:biz/base/crypt/security.dart';
import 'package:biz/core/account/account_service.dart';
import 'package:sqflite/sqflite.dart';

import '../../base/database/data_center.dart';
import '../../base/database/chat_schema.dart';
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

  static String get tableName => Security.security_chat_sessions;

  static String get createTableSql => ChatSchema.sessionsSql;

  //增删查改
  Future<int> upsertSession(ChatSession session) async {
    int ret = await database.insert(tableName, session.toDatabase(), conflictAlgorithm: ConflictAlgorithm.replace);
    if (session.ownerId == ownerId) {
      EventCenter.instance.sendEvent(kEventCenterDidChangeSession, {kDidChangeSessionId: session.id});
    }
    return ret;
  }

  /// 本方法不查剧场
  Future<List<ChatSession>> querySessions({
    String? sessionId,
    int? limit,
    int? offset,
    int? sessionType,
    bool? isReal
  }) async {
    final args = <Object?>[ownerId];
    String where = '${Security.security_ownerId} = ?';
    if (sessionId != null) {
      where += " AND ${Security.security_id} = ?";
      args.add(sessionId);
    } else {
      where += " AND ${Security.security_id} <> '$kOffChatSessionId'";
      where += " AND ${Security.security_id} <> '0' AND ${Security.security_id} <> ''";
    }

    /// 去掉剧场
    where += " AND ${Security.security_type} <> ${SessionType.theater}";
    if (sessionType != null) {
      where += " AND ${Security.security_type} = $sessionType";
    }

    if (sessionType == 0) {
      if (isReal == true) where += " AND ${Security.security_accountType} = 0";
      if (isReal == false) where += " AND ${Security.security_accountType} <> 0";
    }

    final List<Map<String, dynamic>> sqlSessions = await database.query(
      tableName,
      where: where,
      whereArgs: args,
      limit: limit,
      offset: offset,
      orderBy: Other.security_lastMessageTime_DESC,
    );

    List<ChatSession> sessions = sqlSessions.map((element) => ChatSession.fromDatabase(element)).toList();
    return sessions;
  }

  Future<ChatSession?> querySession(String sessionId) async {
    List<ChatSession> sessions = await querySessions(sessionId: sessionId);
    return sessions.firstOrNull;
  }

  // 查询私聊会话列表
  Future<List<ChatSession>> queryAllChatSessions({int? limit, int? offset}) async {
    return await querySessions(
      limit: limit,
      offset: offset,
    );
  }

  Future<int> unreadCount() async {
    try {
      final List<Map<String, dynamic>> ret = await database.rawQuery(
        'SELECT SUM(${Security.security_unreadNumber}) FROM $tableName WHERE ${Security.security_ownerId} = ? AND ${Security.security_type} <> ${SessionType.theater}',
        [ownerId.toString()],
      );

      return ret.first[ret.first.keys.first] as int;
    } catch (e) {
      return 0;
    }
  }

  Future<int> clearUnreadCount({String? sessionId}) async {
    final args = <Object?>[ownerId];
    String sql = 'UPDATE $tableName SET ${Security.security_unreadNumber} = 0 WHERE ${Security.security_ownerId} = ?';
    if (sessionId != null) {
      sql += ' AND ${Security.security_id} = ?';
      args.add(sessionId);
    }
    final rowsAffected = await database.rawUpdate(sql, args);
    if (sessionId == null && rowsAffected > 0) {
      EventCenter.instance.sendEvent(kEventCenterDidClearSessionNumber, {});
    }
    return rowsAffected;
  }

  Future<int> deleteSessionById(String id) async {
    int ret = await database.delete(tableName, where: "${Security.security_ownerId}=? AND ${Security.security_id}=?", whereArgs: [ownerId, id]);
    if (ret > 0) {
      EventCenter.instance.sendEvent(kEventCenterDidDeleteSession, {kDidChangeSessionId: id});
    }
    return ret;
  }
}
