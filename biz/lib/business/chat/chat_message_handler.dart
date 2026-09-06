import 'package:biz/base/crypt/other.dart';
import 'package:biz/base/crypt/security.dart';
import 'package:biz/base/database/data_center.dart';
import 'package:biz/core/account/account_service.dart';
import 'package:sqflite/sqflite.dart';

import 'chat_room_cells/chat_message.dart';

class ChatMessageHandler {
  int get userId => AccountService.instance.account.userId;

  Database get database => DataCenter.instance.database;

  Future<int> insertMessage(ChatMessage message) async {
    Map<String, Object?> values = message.toDatabase();
    return await database.insert(
      ChatMessage.tableName,
      values,
      conflictAlgorithm: ConflictAlgorithm.replace,
    );
  }

  Future<int> updateLocalMessage(ChatMessage message) async {
    Map<String, Object?> values = message.toDatabase();
    return await database.update(
      ChatMessage.tableName,
      values,
      where: '${Security.security_ownerId}=? AND ${Security.security_nativeId}=?',
      whereArgs: [message.ownerId, message.nativeId],
    );
  }

  Future<List<ChatMessage>> queryMessages(
    String sessionId, {
    List<int>? types,
    int? limit,
    int? offset,
  }) async {

    String where =
        "${Security.security_ownerId}  = $userId AND ${Security.security_sessionId}  = ?";
    if (types != null && types.isNotEmpty) {
      where += " AND ${Security.security_type}  IN (${types.join(',')})";
    }

    final List<Map<String, dynamic>> results = await database.query(
      ChatMessage.tableName,
      where: where,
      whereArgs: [sessionId],
      orderBy: Other.security_date_DESC__id_DESC,
      limit: limit,
      offset: offset,
    );

    List<ChatMessage> messages =
        results.map((result) {
          return ChatMessage.fromDatabase(result);
        }).toList();

    return messages;
  }

  Future<int> deleteMessagesBySessionId(String sessionId) async {
    final int deletedCount = await database.delete(
      ChatMessage.tableName,
      where:
          '${Security.security_ownerId} = $userId AND ${Security.security_sessionId} = ?',
      whereArgs: [sessionId],
    );
    return deletedCount;
  }

  Future<ChatMessage?> selectMessage(int id) async {
    final List<Map<String, dynamic>> results = await database.query(
      ChatMessage.tableName,
      where: '${Security.security_ownerId}=? AND ${Security.security_id}=?',
      whereArgs: [userId, id],
    );

    if (results.isEmpty) return null;
    return ChatMessage.fromDatabase(results.first);
  }

  Future<int> deleteMessageById(int msgId) async {
    return await database.delete(
      ChatMessage.tableName,
      where: "${Security.security_ownerId}=? AND id=?",
      whereArgs: [userId, msgId],
    );
  }

  Future<int> deleteMessagesFromId(String sessionId, int msgId) async {
    return await database.delete(
      ChatMessage.tableName,
      where: '${Security.security_ownerId}=? AND ${Security.security_sessionId}=? AND id>?',
      whereArgs: [userId, sessionId, msgId],
    );
  }
}
