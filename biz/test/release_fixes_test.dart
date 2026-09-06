import 'dart:async';
import 'dart:io';

import 'package:biz/base/api_service/api_response.dart';
import 'package:biz/base/crypt/constants.dart';
import 'package:biz/base/crypt/security.dart';
import 'package:biz/base/database/chat_schema.dart';
import 'package:biz/base/database/data_center.dart';
import 'package:biz/base/event_center/event_center.dart';
import 'package:biz/business/chat/chat_manager.dart';
import 'package:biz/business/chat/chat_message_handler.dart';
import 'package:biz/business/chat/chat_room_cells/chat_message.dart';
import 'package:biz/business/chat/chat_session.dart';
import 'package:biz/business/chat/chat_session_handler.dart';
import 'package:biz/business/purchase/purchase_journal.dart';
import 'package:biz/core/account/account_service.dart';
import 'package:biz/core/util/log_util.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:sqflite_common_ffi/sqflite_ffi.dart';

Account account(int id) => Account('token-$id', {
  Security.security_baseInfo: {Security.security_uid: id},
});

ChatSession session(String id) => ChatSession(
  id: id,
  name: 'role',
  avatar: '',
  lastMessageTime: DateTime(2026),
  lastMessageText: 'saved',
  accountType: 1,
);

Map<String, Object?> message(int owner, int id) => {
  Security.security_id: id,
  Security.security_ownerId: owner,
  Security.security_senderId: owner,
  Security.security_receiverId: 100,
  Security.security_type: 1,
  Security.security_sessionId: '100',
  Security.security_date: 1000,
  Security.security_nativeId: 'local-$id',
};

ApiResponse response(String tag) => ApiResponse(response: {})
  ..statusCode = 200
  ..description = ''
  ..data = {
    Constants.statusData: {Security.security_code: 0},
    Constants.rawSessions: [],
    Constants.pullTag: tag,
  };

class SwitchingMessageHandler extends ChatMessageHandler {
  @override
  Future<int> insertMessage(ChatMessage message) async {
    final result = await super.insertMessage(message);
    AccountService.instance.account = account(2);
    return result;
  }
}

ApiResponse messagesResponse(String tag) {
  final result = response(tag);
  result.data[Constants.rawSessions] = [
    {
      Security.security_id: 100,
      Security.security_title: 'role',
      Security.security_icon: '',
      Constants.rawItems: [
        {
          Security.security_id: 200,
          Constants.senderId: 100,
          Constants.receiverId: 1,
          Constants.infoType: ChatMessageType.text.value,
          Security.security_content: 'account A only',
          Security.security_sendAt: 1000,
        },
      ],
    },
  ];
  return result;
}

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();
  late Database db;
  late Directory temporary;
  setUpAll(() async {
    sqfliteFfiInit();
    temporary = await Directory.systemTemp.createTemp('mina-release-tests-');
    TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
        .setMockMethodCallHandler(
          const MethodChannel('plugins.flutter.io/path_provider'),
          (_) async => temporary.path,
        );
    await AppLog.init();
  });
  setUp(() async {
    db = await databaseFactoryFfi.openDatabase(inMemoryDatabasePath);
    DataCenter.instance.database = db;
    await ChatSchema.create(db);
    await PurchaseJournal.create(db);
    AccountService.instance.account = account(1);
  });
  tearDown(() async {
    AccountService.instance.account = Account.none();
    await db.close();
  });

  test('same peer and same message IDs coexist across accounts', () async {
    final handler = ChatSessionHandler();
    final a = session('100');
    await handler.upsertSession(a);
    await db.insert(ChatMessage.tableName, message(1, 200));
    AccountService.instance.account = account(2);
    await handler.upsertSession(session('100'));
    await db.insert(ChatMessage.tableName, message(2, 200));
    expect(a.toDatabase()[Security.security_ownerId], 1);
    expect((await handler.querySession('100'))!.ownerId, 2);
    await ChatMessageHandler().deleteMessagesFromId('100', 100);
    await handler.deleteSessionById('100');
    AccountService.instance.account = account(1);
    expect(await handler.querySession('100'), isNotNull);
    expect(await ChatMessageHandler().selectMessage(200), isNotNull);
  });

  test(
    'message updates and deletes include the owner even for shared native IDs',
    () async {
      await db.insert(ChatMessage.tableName, message(1, 200));
      await db.insert(ChatMessage.tableName, message(2, 200));
      final handler = ChatMessageHandler();
      final own = (await handler.selectMessage(200))!;
      await handler.updateLocalMessage(own);
      expect(await db.query(ChatMessage.tableName), hasLength(2));
      await handler.deleteMessageById(200);
      expect(await handler.selectMessage(200), isNull);
      AccountService.instance.account = account(2);
      expect(await handler.selectMessage(200), isNotNull);
    },
  );

  test(
    'version 1 upgrade preserves rows and adds missing optional columns',
    () async {
      await db.execute('DROP TABLE ${Security.security_chat_sessions}');
      await db.execute('DROP TABLE ${Security.security_chat_message}');
      final oldSessions = ChatSchema.sessionsSql
          .replaceFirst(
            '${Security.security_id}  TEXT NOT NULL',
            '${Security.security_id}  TEXT PRIMARY KEY',
          )
          .replaceFirst(
            ',\n      PRIMARY KEY (${Security.security_ownerId}, ${Security.security_id})',
            '',
          )
          .replaceFirst(',\n      ${Security.security_bio} TEXT', '');
      final oldMessages = ChatSchema.messagesSql
          .replaceFirst(
            '${Security.security_id} INTEGER NOT NULL',
            '${Security.security_id} INTEGER PRIMARY KEY',
          )
          .replaceFirst(
            ',\n        PRIMARY KEY (${Security.security_ownerId}, ${Security.security_id})',
            '',
          );
      await db.execute(oldSessions);
      await db.execute(oldMessages);
      final original = session('100').toDatabase()
        ..remove(Security.security_bio);
      await db.insert(Security.security_chat_sessions, original);
      await db.insert(ChatMessage.tableName, message(1, 200));
      await db.transaction((txn) => ChatSchema.upgrade(txn, 1));
      expect(
        (await ChatSessionHandler().querySession('100'))!.lastMessageText,
        'saved',
      );
      await db.insert(ChatMessage.tableName, message(2, 200));
      AccountService.instance.account = account(2);
      await ChatSessionHandler().upsertSession(session('100'));
      expect(await db.query(Security.security_chat_sessions), hasLength(2));
    },
  );

  test(
    'opening an existing version 1 database runs the awaited migration',
    () async {
      final path = '${temporary.path}/migration.db';
      final old = await databaseFactoryFfi.openDatabase(
        path,
        options: OpenDatabaseOptions(
          version: 1,
          onCreate: (database, _) async {
            await database.execute(
              'CREATE TABLE ${Security.security_chat_sessions} '
              '(${Security.security_id} TEXT PRIMARY KEY, ${Security.security_ownerId} INTEGER)',
            );
            await database.insert(Security.security_chat_sessions, {
              Security.security_id: '100',
              Security.security_ownerId: 1,
            });
          },
        ),
      );
      await old.close();
      final upgraded = await databaseFactoryFfi.openDatabase(
        path,
        options: OpenDatabaseOptions(
          version: DataCenter.version,
          onUpgrade: DataCenter.instance.onUpgrade,
        ),
      );
      final columns = await upgraded.rawQuery(
        'PRAGMA table_info(${Security.security_chat_sessions})',
      );
      expect(columns.where((row) => (row['pk'] as int) > 0), hasLength(2));
      expect(
        await upgraded.query(Security.security_chat_sessions),
        hasLength(1),
      );
      expect(await upgraded.query('purchase_journal'), isEmpty);
      await upgraded.close();
    },
  );

  test(
    'late old response neither writes a new cursor nor unlocks the new request',
    () async {
      final pending = <Completer<ApiResponse>>[];
      final tags = <String, String>{};
      final manager = ChatManager.forTesting(
        requestSender: (_) {
          final c = Completer<ApiResponse>();
          pending.add(c);
          return c.future;
        },
        readTag: (key) => tags[key],
        writeTag: (key, value) => tags[key] = value,
      );
      final first = manager.getHistoryMessages();
      manager.onLogout(Event('logout', {}));
      AccountService.instance.account = account(2);
      final second = manager.getHistoryMessages();
      pending[0].complete(response('900'));
      await first;
      expect(tags, isEmpty);
      expect(manager.isQueryingMessages, isTrue);
      pending[1].complete(response('100'));
      await second;
      expect(tags, {'msg_sync_tag_2': '100'});
      expect(manager.isQueryingMessages, isFalse);
      manager.dispose();
    },
  );

  test(
    'same user logging in again still rejects the prior login response',
    () async {
      final pending = Completer<ApiResponse>();
      final manager = ChatManager.forTesting(
        requestSender: (_) => pending.future,
        readTag: (_) => null,
        writeTag: (_, _) => fail('stale cursor persisted'),
      );
      final request = manager.getHistoryMessages();
      AccountService.instance.account = account(1);
      pending.complete(response('900'));
      await request;
      expect(manager.lastPullTag, isEmpty);
      manager.dispose();
    },
  );

  test(
    'old account message response is discarded before parsing or storage',
    () async {
      final pending = Completer<ApiResponse>();
      final manager = ChatManager.forTesting(
        requestSender: (_) => pending.future,
        readTag: (_) => null,
        writeTag: (_, _) => fail('stale cursor persisted'),
      );
      final request = manager.getHistoryMessages();
      AccountService.instance.account = account(2);
      pending.complete(messagesResponse('200'));
      await request;
      expect(await db.query(ChatMessage.tableName), isEmpty);
      expect(await db.query(Security.security_chat_sessions), isEmpty);
      manager.dispose();
    },
  );

  test(
    'account change during a database write stops the remaining response',
    () async {
      final manager = ChatManager.forTesting(
        requestSender: (_) async => messagesResponse('200'),
        readTag: (_) => null,
        writeTag: (_, _) => fail('stale cursor persisted'),
      );
      manager.messageHandler = SwitchingMessageHandler();
      await manager.getHistoryMessages();
      final rows = await db.query(ChatMessage.tableName);
      expect(rows, hasLength(1));
      expect(rows.single[Security.security_ownerId], 1);
      expect(await db.query(Security.security_chat_sessions), isEmpty);
      expect(manager.didPostOutMessages, isEmpty);
      manager.dispose();
    },
  );

  test('failed sync releases its request lock', () async {
    final manager = ChatManager.forTesting(
      requestSender: (_) => Future.error(StateError('network')),
      readTag: (_) => null,
      writeTag: (_, _) {},
    );
    await expectLater(manager.getHistoryMessages(), throwsStateError);
    expect(manager.isQueryingMessages, isFalse);
    manager.dispose();
  });

  test(
    'failed verification is persisted and retried after reopening the journal',
    () async {
      final journal = PurchaseJournal(db);
      final record = <String, dynamic>{
        'key': 'p',
        'ownerId': 1,
        'receipt': 'receipt',
        'verified': false,
      };
      var consumed = false;
      expect(
        await PurchaseRecovery.recover(
          record: record,
          save: (r) => journal.save('p', r),
          verify: () async => false,
          settle: () async {
            consumed = true;
            return true;
          },
          isCurrentAccount: () => true,
        ),
        isFalse,
      );
      expect(consumed, isFalse);
      final recovered = (await PurchaseJournal(db).read('p'))!;
      expect(recovered['receipt'], 'receipt');
      expect(
        await PurchaseRecovery.recover(
          record: recovered,
          save: (r) => journal.save('p', r),
          verify: () async => true,
          settle: () async {
            consumed = true;
            return true;
          },
          isCurrentAccount: () => true,
        ),
        isTrue,
      );
      expect(consumed, isTrue);
      expect((await journal.read('p'))!['finished'], isTrue);
    },
  );

  test(
    'settlement failure retries without re-verifying and deduplicates completion',
    () async {
      final journal = PurchaseJournal(db);
      final record = <String, dynamic>{'key': 'p', 'verified': false};
      var verifies = 0;
      var settlements = 0;
      Future<bool> run(Map<String, dynamic> r) => PurchaseRecovery.recover(
        record: r,
        save: (r) => journal.save('p', r),
        verify: () async {
          verifies++;
          return true;
        },
        settle: () async {
          settlements++;
          return settlements > 1;
        },
        isCurrentAccount: () => true,
      );
      expect(await run(record), isFalse);
      final restored = (await journal.read('p'))!;
      expect(restored['verified'], isTrue);
      expect(await run(restored), isTrue);
      expect(await run(restored), isTrue);
      expect(verifies, 1);
      expect(settlements, 2);
    },
  );

  test(
    'persistence failure never reaches verification or consumption',
    () async {
      await expectLater(
        PurchaseRecovery.recover(
          record: {},
          save: (_) async => throw FileSystemException('disk full'),
          verify: () async {
            fail('must persist first');
          },
          settle: () async {
            fail('must verify first');
          },
          isCurrentAccount: () => true,
        ),
        throwsA(isA<FileSystemException>()),
      );
    },
  );

  test(
    'purchase and original account intent survive closing the database',
    () async {
      final path = '${temporary.path}/purchase-restart.db';
      var disk = await databaseFactoryFfi.openDatabase(path);
      await PurchaseJournal.create(disk);
      await PurchaseJournal(disk).savePurchase(
        {
          'kind': 'purchase',
          'key': 'receipt-key',
          'ownerId': 1,
          'orderId': 'order-1',
          'receipt': 'store-receipt',
          'verified': true,
        },
        {'kind': 'intent', 'orderId': 'order-1', 'ownerId': 1},
      );
      await disk.close();
      disk = await databaseFactoryFfi.openDatabase(path);
      final journal = PurchaseJournal(disk);
      final saved = (await journal.read('receipt-key'))!;
      expect(saved['receipt'], 'store-receipt');
      expect(saved['ownerId'], 1);
      expect(
        (await journal.read('intent:order-1'))!['transactionKey'],
        'receipt-key',
      );
      expect(
        await PurchaseRecovery.recover(
          record: saved,
          save: (r) => journal.save('receipt-key', r),
          verify: () async {
            fail('already verified before restart');
          },
          settle: () async => true,
          isCurrentAccount: () => true,
        ),
        isTrue,
      );
      await disk.close();
    },
  );

  test(
    'account change during verification defers settlement to the original account',
    () async {
      final journal = PurchaseJournal(db);
      var active = true;
      final record = <String, dynamic>{'ownerId': 1};
      expect(
        await PurchaseRecovery.recover(
          record: record,
          save: (r) => journal.save('p', r),
          verify: () async {
            active = false;
            return true;
          },
          settle: () async {
            fail('new account must not settle');
          },
          isCurrentAccount: () => active,
        ),
        isFalse,
      );
      final saved = (await journal.read('p'))!;
      expect(saved['ownerId'], 1);
      expect(saved['verified'], isTrue);
      expect(saved['finished'], isNot(true));
    },
  );
}
