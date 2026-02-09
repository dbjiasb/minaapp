import 'package:just_audio/just_audio.dart';
import 'package:biz/business/chat/chat_room_cells/chat_audio_message.dart';

import './chat_room_cells/chat_message.dart';
import './chat_room_cells/chat_text_cell.dart';
import 'chat_voice_manager.dart';
import 'package:get/get.dart';

class ChatVoicePlayer {
  //单例
  static ChatVoicePlayer get instance => _instance;
  static final ChatVoicePlayer _instance = ChatVoicePlayer._internal();

  ChatVoicePlayer._internal();

  factory ChatVoicePlayer() => _instance;

  void init() {
    player.playerStateStream.listen((PlayerState state) {
      if (state.processingState == ProcessingState.completed) {
        if (playingMessage.value != null) {
          // 播放完成后，重置状态
          changeMessageStatus(playingMessage.value!, ChatTextAudioStatus.ready);
          // 清空当前播放的消息
          playingMessage.value = null;
        }
      }
    });
  }

  void changeMessageStatus(ChatMessage message, ChatTextAudioStatus status) {
    if (message is ChatTextMessage) {
      message.audioStatus.value = status;
    } else if (message is ChatAudioMessage) {
      message.audioStatus.value = status;
    }
  }

  final AudioPlayer player = AudioPlayer();
  Rx<ChatMessage?> playingMessage = Rx<ChatMessage?>(null);

  Future<void> play(ChatMessage message) async {
    if (playingMessage.value != null) {
      //1.判断与当前播放的是不是一样
      if (playingMessage.value?.id == message.id) {
        return;
      }
      //2.如果不一样，先停止当前播放
      await stop();
    }

    //3.获取path
    String? path = ChatVoiceManager.instance.voicePathForUrl(message.audioUrl);

    if (path != null) {
      //4.播放新的语音
      changeMessageStatus(message, ChatTextAudioStatus.playing);
      if (message is ChatTextMessage || message is ChatAudioMessage) {
        playingMessage.value = message;
        await player.setFilePath(path);
        await player.play();
      }
    }
  }

  Future<void> stop() async {
    if (playingMessage.value != null) {
      changeMessageStatus(playingMessage.value!, ChatTextAudioStatus.ready);
    }
    playingMessage.value = null;
    await player.stop();
  }

  void dealloc() async {
    await player.stop();
    playingMessage.value = null;
  }
}
