import 'dart:io';

import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:video_player/video_player.dart';
import 'package:flutter/widgets.dart';
import 'package:cached_network_image/cached_network_image.dart';

class VideoFileView extends StatefulWidget {
  final bool isFile;
  final String url; // Reusing ImageFile for consistency
  final BoxFit fit;
  final String thumbnailUrl;

  const VideoFileView({super.key, this.isFile = false, this.url = "", this.thumbnailUrl = '', this.fit = BoxFit.cover});

  @override
  _VideoFileViewState createState() => _VideoFileViewState();
}

class _VideoFileViewState extends State<VideoFileView> {
  VideoPlayerController? _controller;

  // CachedVideoPlayerPlus? _player;

  @override
  void initState() {
    super.initState();
    if (widget.thumbnailUrl.isEmpty) {
      _controller = widget.isFile ? VideoPlayerController.file(File(widget.url)) : VideoPlayerController.networkUrl(Uri.parse(widget.url))
        ..initialize().then((_) {
          if (mounted) {
            setState(() {}); // Trigger rebuild to display the first frame
          }
        });
    }

    // _player =
    //     widget.isFile
    //           ? CachedVideoPlayerPlus.file(File(widget.url))
    //           : CachedVideoPlayerPlus.networkUrl(Uri.parse(widget.url))
    //       ..initialize().then((_) {
    //         if (mounted) {
    //           setState(() {}); // Trigger rebuild to display the first frame
    //         }
    //       });
  }

  @override
  void dispose() {
    _controller?.dispose();
    // _player?.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Stack(
      children: [
        ClipRRect(
          borderRadius: BorderRadius.circular(4),
          child: widget.thumbnailUrl.isNotEmpty
              ? CachedNetworkImage(imageUrl: widget.thumbnailUrl, fit: BoxFit.cover, width: double.infinity, height: double.infinity,)
              : _controller != null && _controller!.value.isInitialized
          // child: _player != null && _player!.isInitialized
              ? Stack(
            children: [
              SizedBox.expand(
                child: FittedBox(
                  fit: BoxFit.cover,
                  child: SizedBox(
                    width: _controller!.value.size.width,
                    height: _controller!.value.size.height,
                    child: VideoPlayer(_controller!),
                    // width: _player!.controller.value.size.width,
                    // height: _player!.controller.value.size.height,
                    // child: VideoPlayer(_player!.controller),
                  ),
                ),
              ),
            ],
          )
              : Container(
            color: Colors.grey[300], // Placeholder while loading
            child: const Center(child: CircularProgressIndicator()),
          ),
        ),
        Positioned(
          left: 0,
          right: 0,
          bottom: 0,
          top: 0,
          child: Center(child: Icon(Icons.play_circle, size: 32, color: Colors.white)),
        ),
      ],
    );
  }
}
