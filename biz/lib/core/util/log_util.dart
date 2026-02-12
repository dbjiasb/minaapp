import 'package:biz/base/crypt/routes.dart';
import 'dart:io';
import 'dart:typed_data';
import 'package:archive/archive_io.dart';

import 'package:flutter/cupertino.dart';
import 'package:flutter/foundation.dart';
import 'package:intl/intl.dart';
import 'package:logger/logger.dart';
import 'package:biz/base/preferences/preferences.dart';
import 'package:path_provider/path_provider.dart';

import '../../base/crypt/security.dart';
import 'file_upload.dart';

class MinaLogPrinter extends PrettyPrinter {
  MinaLogPrinter() : super(
      methodCount: 0,
      errorMethodCount: 8,
      noBoxingByDefault: true,
      colors: false,
      printEmojis: false
  );

  @override
  List<String> log(LogEvent event) {
    String finalLogString = '${DateTime.now()} ${event.message}';
    LogEvent et = LogEvent(event.level, finalLogString);
    return super.log(et);
  }
}

class AppLog {

  static final AppLog _instance = AppLog._internal();
  AppLog._internal();
  factory AppLog() => _instance;

  static late Logger _logger;
  static String _logDirPath = '';

  static init() async {
    _logDirPath = '${(await getTemporaryDirectory()).path}/mina_logs';
    String fileName = 'mina_log_${DateFormat('MM-dd-yyyy').format(DateTime.now())}.log';
    final path = '$_logDirPath/$fileName';
    File file = await File(path).create(recursive: true);
    FileOutput output = FileOutput(file: file);
    debugPrint('app log path: $path');
    _logger = Logger(
        filter: ProductionFilter(),
        output: output,
        printer: MinaLogPrinter()
    );
  }

  void imp_d(String msg) {
    if (kDebugMode) debugPrint('[AppLog] $msg');
    // _logger.d(msg);
  }

  void imp_i(String msg) {
    if (kDebugMode) debugPrint('[AppLog] $msg');
    _logger.i('[VCI] $msg');
  }

  void imp_e(String msg) {
    if (kDebugMode) debugPrint('[AppLog] $msg');
    _logger.e('[VCE] $msg');
  }

  static void d(String msg) => AppLog().imp_d(msg);
  static void i(String msg) => AppLog().imp_i(msg);
  static void e(String msg) => AppLog().imp_e(msg);

  //// upload
  static Future<bool> upload() async {
    try {
      await deleteLogBefore5Days();
    } catch (e) {
      L.e('delete log error: $e');
    }
    String? zipPath = await getCompressLogPath();
    final file = File(zipPath ?? '');
    if (zipPath != null && file.existsSync()) {
      Uint8List fileBytes = await file.readAsBytes();
      String? ret = await FilePushService.instance.upload(fileBytes, FileType.log, ext: Security.security_zip);
      deleteCompressLog();
      return ret?.isNotEmpty ?? false;
    }
    return false;
  }

  static Future<bool> uploadIfNeed() async {
    int lastTime = Preferences.instance.getInt(Security.security_kLastUploadLogTime);
    if (DateTime.now().millisecondsSinceEpoch - lastTime < 1000 * 30) {
      return false;
    }
    Preferences.instance.setInt(Security.security_kLastUploadLogTime, DateTime.now().millisecondsSinceEpoch);
    return await upload();
  }

    static Future<String?> getCompressLogPath() async {
    var encoder = ZipFileEncoder();
    await compute(encoder.zipDirectory, Directory(_logDirPath));
    return '$_logDirPath.zip';
  }

  static Future<void> deleteCompressLog() async {
    var zipFile = File('$_logDirPath.zip');
    zipFile.delete();
  }

  static Future<void> deleteLogBefore5Days() async {
    Directory logDir = Directory(_logDirPath);
    List<File> logFiles = logDir.listSync().whereType<File>().toList();
    DateTime fiveDaysAgo = DateTime.now().subtract(Duration(days: 5));
    List<File> filesToDelete = logFiles.where((file) {
      return file.lastModifiedSync().isBefore(fiveDaysAgo);
    }).toList();
    for (File file in filesToDelete) {
      await file.delete();
      L.i('Delete log file：${file.path}');
    }
  }
}

typedef L = AppLog;
