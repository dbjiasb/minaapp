import 'package:biz/base/crypt/security.dart';
import 'dart:async';

import 'package:cached_video_player_plus/cached_video_player_plus.dart';
import 'package:flutter_cache_manager/flutter_cache_manager.dart';

/// Configure a video-only cache manager to avoid `.bin` cache files on iOS.
void configureVideoCacheManager() {
  CachedVideoPlayerPlus.cacheManager = SafeVideoCacheManager();
}

class SafeVideoCacheManager extends CacheManager {
  static final String key = Security.security_libCachedVideoPlayerPlusData;
  static final SafeVideoCacheManager _instance = SafeVideoCacheManager._();

  factory SafeVideoCacheManager() => _instance;

  SafeVideoCacheManager._()
      : super(
          Config(
            key,
            fileService: _VideoFileService(),
          ),
        );
}

class _VideoFileService extends HttpFileService {
  @override
  Future<FileServiceResponse> get(String url, {Map<String, String>? headers}) async {
    final response = await super.get(url, headers: headers);
    return _VideoFileServiceResponse(url: url, response: response);
  }
}

class _VideoFileServiceResponse implements FileServiceResponse {
  _VideoFileServiceResponse({required this.url, required this.response});

  final String url;
  final FileServiceResponse response;

  static const List<String> _fallbackVideoExtensions = <String>[
    '.mp4',
    '.mov',
    '.m4v',
    '.webm',
    '.mkv',
    '.avi',
  ];

  @override
  Stream<List<int>> get content => response.content;

  @override
  int? get contentLength => response.contentLength;

  @override
  int get statusCode => response.statusCode;

  @override
  DateTime get validTill => response.validTill;

  @override
  String? get eTag => response.eTag;

  @override
  String get fileExtension {
    final extension = response.fileExtension.toLowerCase();
    if (extension.isNotEmpty && extension != '.bin') {
      return extension;
    }

    final path = Uri.parse(url).path.toLowerCase();
    for (final item in _fallbackVideoExtensions) {
      if (path.endsWith(item)) return item;
    }

    // Safe fallback for iOS AVPlayer.
    return '.mp4';
  }
}
