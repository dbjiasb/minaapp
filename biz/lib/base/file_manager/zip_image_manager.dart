import 'dart:io';
import 'package:archive/archive.dart';
import 'package:dio/dio.dart';
import 'package:biz/base/api_service/api_config.dart';
import 'package:path_provider/path_provider.dart';

class ZipImageManager {
  static ZipImageManager get instance => _instance;
  static final ZipImageManager _instance = ZipImageManager._internal();

  ZipImageManager._internal();

  factory ZipImageManager() => _instance;

  late String _zipUrl;
  late String _fallbackUrlPrefix;
  late String _version; // 从 zipUrl 自动提取

  String? _extractDir;
  bool _isDownloading = false;

  /// 初始化：自动从 zipUrl 提取版本号
  Future<void> init() async {
    _zipUrl = ApiConfig.imageZipUrl;
    _fallbackUrlPrefix = ApiConfig.assetImageUrl;

    _version = _extractVersionFromUrl(_zipUrl);
    if (_version.isEmpty) {
      throw ArgumentError(
        'can not extract versionInfo from zipUrl: $_zipUrl\n',
      );
    }

    final tempDir = await getTemporaryDirectory();
    final extractPath = '${tempDir.path}/images_v$_version/';
    final markerFile = File('$extractPath/.version');

    // 检查是否已缓存当前版本
    if (await markerFile.exists()) {
      final cached = (await markerFile.readAsString()).trim();
      if (cached == _version) {
        _extractDir = extractPath;
        _cleanOldVersions(tempDir, _version);
        return;
      }
    }

    // 未缓存或版本不匹配 → 下载
    _ensureDownloaded(extractPath);
  }

  /// 从 URL 提取版本号（简单实现，假设格式固定）
  String _extractVersionFromUrl(String url) {
    final uri = Uri.tryParse(url);
    if (uri == null) return '';

    final pathSegments = uri.pathSegments;
    // 假设倒数第二段是版本（如 [..., "1.0.1", "images.zip"]）
    if (pathSegments.length >= 2) {
      final possibleVersion = pathSegments[pathSegments.length - 2];
      // 简单校验：包含数字和点，且不包含文件扩展名
      if (RegExp(r'^\d+(\.\d+)*$').hasMatch(possibleVersion)) {
        return possibleVersion;
      }
    }
    return '';
  }

  Future<void> _cleanOldVersions(
    Directory tempDir,
    String currentVersion,
  ) async {
    final entries = await tempDir.list().toList();
    for (final entity in entries) {
      if (entity is Directory && entity.path.contains("images_v")) {
        if (!entity.path.contains('images_v$currentVersion')) {
          try {
            await entity.delete(recursive: true);
            print('clear old version: ${entity.path}');
          } catch (e) {
            // ignore
          }
        }
      }
    }
  }

  Future<void> _ensureDownloaded(String extractPath) async {
    if (_extractDir != null) return;
    if (_isDownloading) return;

    _isDownloading = true;
    try {
      final tempDir = await getTemporaryDirectory();
      final zipPath = '${tempDir.path}/images_v$_version.zip';

      await Dio().download(
        _zipUrl,
        zipPath,
        options: Options(
          receiveTimeout: Duration(milliseconds: 300 * 1000),
          sendTimeout: Duration(milliseconds: 60 * 1000),
        ),
        onReceiveProgress: (received, total) {
          if (total <= 0) return;
          print('percentage: ${(received / total * 100).toStringAsFixed(0)}%');
        },
      );

      final bytes = await File(zipPath).readAsBytes();
      final archive = ZipDecoder().decodeBytes(
        bytes,
        password: "mina",
      );

      await Directory(extractPath).create(recursive: true);
      for (final file in archive) {
        if (file.name.endsWith('/')) continue;
        final data = file.content as List<int>;
        final outFile = File('$extractPath${file.name.split('/').last}');
        await outFile.create(recursive: true);
        await outFile.writeAsBytes(data);
      }

      await File('$extractPath/.version').writeAsString(_version);
      _extractDir = extractPath;
      await File(zipPath).delete();

      final rootTemp = await getTemporaryDirectory();
      _cleanOldVersions(rootTemp, _version);
    } catch (e) {
      print('ZIP download or unzip error（version $_version）: $e');
    } finally {
      _isDownloading = false;
    }
  }

  String getImagePathOrUrl(String imageName) {
    if (_extractDir != null) {
      final localPath = '$_extractDir$imageName';
      if (File(localPath).existsSync()) {
        return localPath;
      }
    }

    // 触发重试（仅当尚未成功）
    if (_extractDir == null) {
      getTemporaryDirectory().then((tempDir) {
        final extractPath = '${tempDir.path}/images_v$_version/';
        _ensureDownloaded(extractPath);
      });
    }

    return _fallbackUrlPrefix.endsWith('/')
        ? '$_fallbackUrlPrefix$imageName'
        : '$_fallbackUrlPrefix/$imageName';
  }

  bool isLocalImage(String path) {
    return path.startsWith('/') && !path.startsWith(_fallbackUrlPrefix);
  }
}
