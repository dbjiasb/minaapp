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
    _controller = VideoPlayerController.networkUrl(Uri.parse(widget.videoUrl))
      ..initialize().then((_) {
        vWidth = _controller.value.size.width;
        vHeight = _controller.value.size.height;
        setState(() {});
        _controller.setVolume(0.0);
        _controller.play();
      });
    _controller.setLooping(true);
    _controller.addListener(() {});
  }

  @override
  void dispose() {
    super.dispose();
    _controller.dispose();
  }

  @override
  Widget build(BuildContext context) {
    double scaleRatio = 0;
    if (widget.autoScale) {
      final Size screenSize = MediaQuery.of(context).size;
      final Size videoSize = Size(720 * 0.5, 1280 * 0.5);

      double wRatio = screenSize.width / videoSize.width;
      double hRatio = screenSize.height / videoSize.height;
      scaleRatio = wRatio > hRatio ? wRatio : hRatio;
      // final videoWidth = 1280.0 / (screenSize.height / screenSize.width);
    }

    return Container(
      color: Colors.transparent,
      height: double.infinity,
      width: double.infinity,
      alignment: Alignment.center,
      child:
          _controller.value.isInitialized
              ? (scaleRatio > 0
                  ? Transform.scale(
                    scale: scaleRatio, // 放大1.2倍
                    child: Center(
                      child: AspectRatio(
                        aspectRatio: _controller.value.aspectRatio,
                        child: VideoPlayer(_controller),
                      ),
                    ),
                  )
                  : Center(
                    child: AspectRatio(
                      aspectRatio: _controller.value.aspectRatio,
                      child: VideoPlayer(_controller),
                    ),
                  ))
              : CachedImage(
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
