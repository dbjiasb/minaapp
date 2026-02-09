import 'package:biz/base/crypt/other.dart';
import 'package:biz/base/crypt/security.dart';
import 'package:biz/base/database/data_center.dart';
import 'package:biz/core/account/account_service.dart';
import 'package:sqflite/sqflite.dart';

import 'chat_room_cells/chat_message.dart';

class ChatMessageHandler {
  int get userId => AccountService.instance.account.userId;

  Database get database => DataCenter.instance.database;

  ChatMessageHandler() {
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
    return await database.execute(ChatMessage.createTableSql);
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
    if (toVersion == 2) {
      database.execute(
        'ALTER TABLE ${ChatMessage.tableName} ADD COLUMN ${Security.security_lockInfo}  TEXT',
      );
      database.execute(
        'ALTER TABLE ${ChatMessage.tableName} ADD COLUMN ${Security.security_uuid}  TEXT',
      );
      database.execute(
        'ALTER TABLE ${ChatMessage.tableName} ADD COLUMN ${Security.security_renewInfo}  TEXT',
      );
    } else if (toVersion == 4) {
      database.execute(
        'ALTER TABLE ${ChatMessage.tableName} ADD COLUMN  ${Security.security_like}  INTEGER DEFAULT 0',
      );
      database.execute(
        'ALTER TABLE ${ChatMessage.tableName} ADD COLUMN ${Security.security_name}  TEXT',
      );
      database.execute(
        'ALTER TABLE ${ChatMessage.tableName} ADD COLUMN ${Security.security_avatar}  TEXT',
      );
      database.execute(
        'ALTER TABLE ${ChatMessage.tableName} ADD COLUMN  ${Security.security_sessionType}  INTEGER DEFAULT 0',
      );
    }
  }

  Future<int> insertMessage(ChatMessage message) async {
    return await database.insert(
      ChatMessage.tableName,
      message.toDatabase(),
      conflictAlgorithm: ConflictAlgorithm.replace,
    );
  }

  Future<int> updateLocalMessage(ChatMessage message) async {
    return await database.update(
      ChatMessage.tableName,
      message.toDatabase(),
      where: Other.security_nativeId___,
      whereArgs: [message.nativeId],
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
      where: Other.security_id____,
      whereArgs: [id],
    );

    if (results.isEmpty) return null;
    return ChatMessage.fromDatabase(results.first);
  }

  Future<int> deleteMessageById(int msgId) async {
    return await database.delete(
      ChatMessage.tableName,
      where: "id=?",
      whereArgs: [msgId],
    );
  }

  Future<int> deleteMessagesFromId(String sessionId, int msgId) async {
    return await database.delete(
      ChatMessage.tableName,
      where: '${Security.security_sessionId}=? AND id>?',
      whereArgs: [sessionId, msgId],
    );
  }
}
