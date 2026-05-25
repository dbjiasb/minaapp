import 'package:flutter/material.dart';
import 'package:flutter/widgets.dart';
import 'package:video_player/video_player.dart';
import '../../core/util/cached_image.dart';
import '../../shared/app_theme.dart';
import 'anim_scale_image.dart';

class UserCardView extends StatelessWidget {
  final String? userBgUrl;
  final String? userCardUrl;

  final String? defaultUrl;
  final String? videoUrl;

  final double width;
  final double height;

  const UserCardView({
    this.defaultUrl,
    this.userBgUrl,
    this.userCardUrl,
    this.videoUrl,
    this.width = double.infinity,
    this.height = double.infinity,
    super.key,
  });

  @override
  Widget build(BuildContext context) {
    Widget child;
    if ((videoUrl ?? "").isNotEmpty) {
      child = VideoView(
        videoUrl: videoUrl!,
        coverUrl: defaultUrl,
        width: width,
        height: height,
        autoScale: true,
      );
    } else if ((userBgUrl ?? "").isNotEmpty && (userCardUrl ?? "").isNotEmpty) {
      child = Stack(
        children: [
          AnimScaleImage(
            userBgUrl ?? "",
            fit: BoxFit.fitHeight,
            tween: Tween<double>(begin: 1.0, end: 1.15),
            holderWidgetBuilder: (BuildContext context, String url) {
              return _defaultBg();
            },
            errorWidgetBuilder: (context, url, error) {
              return _defaultBg();
            },
          ),
          Container(
            width: width,
            height: height,
            padding: const EdgeInsets.only(left: 48, right: 48, top: 120),
            child: AnimScaleImage(
              userCardUrl ?? "",
              fit: BoxFit.fitHeight,
              holderWidgetBuilder: (BuildContext context, String url) {
                return Container();
              },
              errorWidgetBuilder: (context, url, error) {
                return Container();
              },
            ),
          ),
        ],
      );
    } else {
      child = CachedImage(
        imageUrl: defaultUrl ?? "",
        width: width,
        height: height,
        fit: BoxFit.cover,
        placeholder: (context, url) {
          return Container(
            height: width,
            width: height,
            alignment: Alignment.center,
            child: const CircularProgressIndicator(color: AppColors.primary),
          );
        },
      );
    }
    return child;
  }

  Widget _defaultBg() {
    return Container(
      height: width,
      width: height,
      // decoration: const BoxDecoration(
      //   gradient: LinearGradient(
      //     colors: [Color(0xFFFFF0E9), Color(0xFFFFF2D8)],
      //     // 渐变色数组
      //     begin: Alignment.topCenter,
      //     // 渐变起始点
      //     end: Alignment.bottomCenter,
      //   ),
      // ),
    );
  }
}

class VideoView extends StatefulWidget {
  final String videoUrl;
  final String? coverUrl;
  final double width;
  final double height;
  final bool autoScale;

  VideoView({
    Key? key,
    required this.videoUrl,
    this.coverUrl,
    this.height = double.infinity,
    this.width = double.infinity,
    this.autoScale = false,
  }) : super(key: key);

  @override
  State<VideoView> createState() => _VideoViewState();
}

class _VideoViewState extends State<VideoView> {
  late VideoPlayerController _controller;

  double vWidth = double.infinity;
  double vHeight = double.infinity;

  @override
  void initState() {
    super.initState();
    _controller = VideoPlayerController.networkUrl(Uri.parse(widget.videoUrl));
    _initVideo();
  }

  bool _showVideo = false;

  Future<void> _initVideo() async {
    await _controller.initialize();

    vWidth = _controller.value.size.width;
    vHeight = _controller.value.size.height;

    await _controller.setLooping(true);
    await _controller.setVolume(0);
    await _controller.play();

    await Future.delayed(const Duration(milliseconds: 300));

    if (mounted) {
      setState(() {
        _showVideo = true;
      });
    }
  }

  @override
  void dispose() {
    super.dispose();
    _controller.dispose();
  }

  @override
  Widget build(BuildContext context) {
    Widget videoWidget = _controller.value.isInitialized
        ? (widget.autoScale
        ? SizedBox.expand(
      child: FittedBox(
        fit: BoxFit.cover,
        child: SizedBox(width: _controller.value.size.width, height: _controller.value.size.height, child: VideoPlayer(_controller)),
      ),
    )
        : Center(
      child: AspectRatio(aspectRatio: _controller.value.aspectRatio, child: VideoPlayer(_controller)),
    ))
        : const SizedBox();

    return SizedBox(
      width: widget.width,
      height: widget.height,
      child: Stack(
        fit: StackFit.expand,
        children: [
          /// 封面
          AnimatedOpacity(
            opacity: _showVideo ? 0 : 1,
            duration: const Duration(milliseconds: 300),
            child: CachedImage(
              imageUrl: widget.coverUrl ?? "",
              width: widget.width,
              height: widget.height,
              fit: BoxFit.cover,
              errorWidget: (context, url, error) {
                return _defaultBg();
              },
              placeholder: (context, url) {
                return _defaultBg();
              },
            ),
          ),

          /// 视频
          AnimatedOpacity(opacity: _showVideo ? 1 : 0, duration: const Duration(milliseconds: 300), child: videoWidget),
        ],
      ),
    );
  }

  Widget _defaultBg() {
    return Container(
      width: widget.width,
      height: widget.height,
      // decoration: const BoxDecoration(
      //   gradient: LinearGradient(
      //     colors: [Color(0xFF6B39FF), Color(0xFFFF56BB)],
      //     // 渐变色数组
      //     begin: Alignment.topCenter,
      //     // 渐变起始点
      //     end: Alignment.bottomCenter,
      //   ),
      // ),
    );
  }
}
