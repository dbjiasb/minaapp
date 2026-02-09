import 'package:flutter/material.dart';
import 'package:flutter/widgets.dart';
import 'package:cached_network_image/cached_network_image.dart';

class AnimScaleImage extends StatefulWidget {
  final String imageUrl;
  final BoxFit fit;
  final double width;
  final double height;
  final PlaceholderWidgetBuilder? holderWidgetBuilder;
  final LoadingErrorWidgetBuilder? errorWidgetBuilder;
  final Duration? duration;
  final Tween<double>? tween;

  const AnimScaleImage(this.imageUrl,
      {this.width = double.infinity,
      this.height = double.infinity,
      this.fit = BoxFit.cover,
      this.holderWidgetBuilder,
      this.duration,
      this.tween,
      this.errorWidgetBuilder,
      super.key});

  @override
  State<AnimScaleImage> createState() => _AnimScaleImageState();
}

class _AnimScaleImageState extends State<AnimScaleImage>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<double> _animation;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      duration: widget.duration ?? const Duration(seconds: 5),
      vsync: this,
    )..repeat(reverse: true); // 循环播放，反向动画

    _animation = (widget.tween ?? Tween<double>(begin: 1, end: 1.05)).animate(
      CurvedAnimation(
        parent: _controller,
        curve: Curves.easeOut,
      ),
    );
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  void _startAnimation() {
    if (_controller.status == AnimationStatus.completed) {
      _controller.reset();
    }
    _controller.forward();
  }

  @override
  Widget build(BuildContext context) {
    _controller.reset();
    return CachedNetworkImage(
      imageUrl: widget.imageUrl,
      imageBuilder: (context, imageProvider) {
        _startAnimation();
        return ScaleTransition(
          scale: _animation,
          alignment: const Alignment(0, -0.5),
          child: Container(
              width: widget.width,
              height: widget.height,
              decoration: BoxDecoration(
                  image: DecorationImage(
                image: imageProvider,
                fit: widget.fit,
              ))),
        );
      },
      placeholder: widget.holderWidgetBuilder ??
          _placeHolderBuilder(
              width: widget.width, height: widget.height, fit: widget.fit),
      errorWidget: widget.errorWidgetBuilder ??
          _errorBuilder(
              width: widget.width, height: widget.height, fit: widget.fit),
    );
  }

  PlaceholderWidgetBuilder _placeHolderBuilder(
      {double width = double.infinity,
      double height = double.infinity,
      double borderRadius = 0,
      BoxFit fit = BoxFit.cover}) {
    return (BuildContext context, String url) {
      return ClipRRect(
          borderRadius: BorderRadius.circular(borderRadius),
          child: Container(
            width: width,
            height: height,
            color: Colors.grey,
          ));
    };
  }

  LoadingErrorWidgetBuilder _errorBuilder(
      {double width = double.infinity,
      double height = double.infinity,
      double borderRadius = 0,
      BoxFit fit = BoxFit.cover}) {
    return (BuildContext context, String url, dynamic err) {
      return ClipRRect(
          borderRadius: BorderRadius.circular(borderRadius),
          child: Container(
            width: width,
            height: height,
            color: Colors.grey,
          ));
    };
  }
}
