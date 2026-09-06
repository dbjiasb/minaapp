import 'dart:convert';

import 'package:sqflite_sqlcipher/sqflite.dart';

/// Stored in the encrypted app database, including intents created before the
/// store sheet opens. A finished row is retained to deduplicate store replays.
class PurchaseJournal {
  PurchaseJournal(this.database);
  final Database database;

  static Future<void> create(DatabaseExecutor db) => db.execute('''
    CREATE TABLE IF NOT EXISTS purchase_journal (
      id TEXT PRIMARY KEY,
      payload TEXT NOT NULL
    )
  ''');

  Future<Map<String, dynamic>?> read(String key) async {
    final rows = await database.query(
      'purchase_journal',
      where: 'id=?',
      whereArgs: [key],
    );
    return rows.isEmpty
        ? null
        : Map<String, dynamic>.from(
            jsonDecode(rows.single['payload'] as String),
          );
  }

  Future<void> save(String key, Map<String, dynamic> record) async {
    await database.insert('purchase_journal', {
      'id': key,
      'payload': jsonEncode(record),
    }, conflictAlgorithm: ConflictAlgorithm.replace);
  }

  Future<void> savePurchase(
    Map<String, dynamic> record,
    Map<String, dynamic>? intent,
  ) async {
    await database.transaction((txn) async {
      await txn.insert('purchase_journal', {
        'id': record['key'],
        'payload': jsonEncode(record),
      }, conflictAlgorithm: ConflictAlgorithm.replace);
      if (intent != null && intent['orderId'] != '') {
        await txn.insert('purchase_journal', {
          'id': 'intent:${intent['orderId']}',
          'payload': jsonEncode({...intent, 'transactionKey': record['key']}),
        }, conflictAlgorithm: ConflictAlgorithm.replace);
      }
    });
  }

  Future<List<Map<String, dynamic>>> all() async {
    final rows = await database.query('purchase_journal');
    return rows
        .map(
          (row) =>
              Map<String, dynamic>.from(jsonDecode(row['payload'] as String)),
        )
        .toList();
  }
}

/// Both the verification checkpoint and store settlement are retryable. The
/// callbacks make the failure boundaries testable without a live store account.
class PurchaseRecovery {
  static Future<bool> recover({
    required Map<String, dynamic> record,
    required Future<void> Function(Map<String, dynamic>) save,
    required Future<bool> Function() verify,
    required Future<bool> Function() settle,
    required bool Function() isCurrentAccount,
  }) async {
    if (record['finished'] == true) return true;
    if (!isCurrentAccount()) return false;
    await save(record);
    if (!isCurrentAccount()) return false;
    if (record['verified'] != true) {
      if (!await verify()) return false;
      // Save even if the account changed during verification, but never issue
      // another authenticated request or settle under the new account.
      record['verified'] = true;
      await save(record);
    }
    if (!isCurrentAccount()) return false;
    if (!await settle()) return false;
    record['finished'] = true;
    await save(record);
    return true;
  }
}
