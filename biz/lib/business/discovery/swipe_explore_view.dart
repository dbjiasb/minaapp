import 'package:biz/base/crypt/routes.dart';
import 'package:biz/base/crypt/security.dart';
import 'package:flutter/widgets.dart';
import 'package:just_audio/just_audio.dart';
import 'package:visibility_detector/visibility_detector.dart';

typedef BuildPageView =
    Widget Function(BuildContext context, ValueChanged<String> onUrlChanged);

class SwipeExploreView extends StatefulWidget {
  final BuildPageView buildSwipeView;

  final String firstUrl;

  String keyName = Security.security_swipeExploreView;

  SwipeExploreView(
    this.buildSwipeView, {
    this.firstUrl = "",
    super.key,
  });

  @override
  State<SwipeExploreView> createState() => _SwipeExploreViewState();
}

class _SwipeExploreViewState extends State<SwipeExploreView> {
  late ValueChanged<String> _onIndexChanged;
  late AudioPlayer _audioPlayer;
  String? _audioUrl;

  @override
  void initState() {
    super.initState();
    _audioUrl = _audioUrl ?? widget.firstUrl;
    _audioPlayer = AudioPlayer();
    _onIndexChanged = (url) async {
      _audioUrl = url;
      _playAudioWithUrl(url);
    };
  }

  void _playAudioWithUrl(String url) async {
    if (url.isNotEmpty) {
      await _audioPlayer.stop();
      await _audioPlayer.setUrl(url);
      _audioPlayer.play();
    }
  }

  @override
  void dispose() {
    _audioPlayer.dispose();
    super.dispose();
  }

  void _stopAudioPlay() async {
    await _audioPlayer.stop(); // 停止播放
  }

  @override
  Widget build(BuildContext context) {
    return VisibilityDetector(
      key: Key(widget.keyName),
      onVisibilityChanged: (visibilityInfo) {
        if (visibilityInfo.visibleFraction == 0) {
          _stopAudioPlay();
        } else {
          _playAudioWithUrl(_audioUrl ?? "");
        }
      },
      child: widget.buildSwipeView(context, _onIndexChanged),
    );
  }
}
