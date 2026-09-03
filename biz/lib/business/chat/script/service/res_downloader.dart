import 'package:biz/base/crypt/routes.dart';
import 'dart:io';

import 'package:dio/dio.dart';
import 'package:path_provider/path_provider.dart';
import 'package:crypto/crypto.dart';
import 'dart:convert';
import 'package:archive/archive_io.dart';

import '../../../../base/crypt/security.dart';
import '../../../../core/util/log_util.dart';

var kResDirName = Security.security_ct_res_download;

enum ResDownloadStatus { downloading, downloaded, success, fail }

class ResDownloader {
  static ResDownloader? _single;
  ResDownloader._();

  static ResDownloader get singleton {
    _single ??= ResDownloader._()..init();
    return _single!;
  }

  late String dir;

  Future<bool> isDownloaded({required String url, String? md5}) async {
    md5 ??= md5For(url);
    String path = '$dir/$md5';
    bool ret = await File(path).exists();
    L.i('[Downloader] already exist, $path');
    return ret;
  }

  void init() async {
    dir = '${(await getTemporaryDirectory()).path}/$kResDirName';
    Directory(dir).createSync(recursive: true);
  }

  Future<bool> download({
    required String url,
    String? md5,
    Function(String url, ResDownloadStatus status, int progress)? callback,
  }) async {
    md5 ??= md5For(url);
    String zPath = zipPath(url: url, md5: md5);
    String fPath = folderPath(url: url, md5: md5);

    if (await File(fPath).exists()) {
      callback?.call(url, ResDownloadStatus.success, 100);
      return true;
    }

    if (await File(zPath).exists()) {
      callback?.call(url, ResDownloadStatus.downloaded, 100);
      await unzip(zPath, fPath);
      callback?.call(url, ResDownloadStatus.success, 100);
      return true;
    }

    double progress = 0;

    Response response = await Dio().download(
      url,
      zPath,
      onReceiveProgress: (received, total) async {
        double perRate = received * 1.0 / total;
        if (progress == 0 || perRate - progress > 0.01 || perRate >= 1) {
          progress = perRate;
          L.i('[Download] progress, $perRate');

          if (perRate < 1) {
            callback?.call(
              url,
              ResDownloadStatus.downloading,
              (progress * 100).toInt(),
            );
          } else {
            callback?.call(
              url,
              ResDownloadStatus.downloaded,
              (progress * 100).toInt(),
            );
            await unzip(zPath, fPath);
            callback?.call(
              url,
              ResDownloadStatus.success,
              (progress * 100).toInt(),
            );
            L.i('[Download] progress complete, prepare to decode.');
          }
        }
      },
    );

    if (response.statusCode != 200) {
      callback?.call(url, ResDownloadStatus.fail, 0);
      L.i('[Download] fail, $url');
    }

    return response.statusCode == 200;
  }

  String md5For(String data) {
    final content = utf8.encode(data);
    final digest = md5.convert(content);
    return digest.toString();
  }

  String folderPath({required String url, String? md5}) {
    md5 ??= md5For(url);
    return '$dir/$md5';
  }

  String zipPath({required String url, String? md5}) {
    return '${folderPath(url: url, md5: md5)}.zip';
  }

  Future unzip(String path, String folderPath) async {
    Directory(folderPath).createSync(recursive: true);

    extractFileToDisk(path, folderPath);
  }
}
