import 'dart:convert';
import 'dart:io';
import 'dart:math';
import 'dart:typed_data';

import 'package:biz/base/assets/image_view.dart';
import 'package:biz/base/crypt/copywriting.dart';
import 'package:biz/base/crypt/security.dart';
import 'package:biz/base/preferences/preferences.dart';
import 'package:biz/base/report/report_manager.dart';
import 'package:biz/base/router/router_names.dart';
import 'package:biz/business/chat/chat_manager.dart';
import 'package:biz/business/chat/chat_room/chat_room_view.dart';
import 'package:biz/business/chat/chat_room_cells/chat_audio_message.dart';
import 'package:biz/business/chat/chat_room_cells/chat_image_message.dart';
import 'package:biz/business/chat/chat_session.dart';
import 'package:biz/core/util/audio_manager.dart';
import 'package:biz/core/util/cached_image.dart';
import 'package:biz/core/util/collections_util.dart';
import 'package:biz/core/util/file_upload.dart';
import 'package:biz/shared/app_theme.dart';
import 'package:biz/shared/sheet.dart';
import 'package:flutter/material.dart';
import 'package:flutter_cache_manager/flutter_cache_manager.dart';
import 'package:flutter_image_compress/flutter_image_compress.dart';
import 'package:flutter_staggered_grid_view/flutter_staggered_grid_view.dart';
import 'package:get/get.dart';
import 'package:image_picker/image_picker.dart';
import 'package:video_thumbnail/video_thumbnail.dart';

import '../../../shared/toast/toast.dart';
import '../call/av_engine.dart';
import '../chat_room_cells/chat_video_message.dart';
import '../create_image/create_image_panel.dart';
import '../gift/gift_panel.dart';
import 'chat_muse_view.dart';

enum ChatRoomBottomBarState { simple, detailed, muse, gift }

class ChatBottomBar extends StatelessWidget {
  ChatBottomBar({super.key, this.showAudioInputMask, this.cancelAudio, this.sendText});

  final Function(bool)? showAudioInputMask; // control audio input mask visibility
  final Function(bool)? cancelAudio; // control audio input cancel state
  final Function? sendText;
  RxBool showGreetTips = true.obs;

  ChatBottomBarController viewController = Get.put(ChatBottomBarController());

  @override
  Widget build(BuildContext context) {
    return Obx(
      () => Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          if (viewController.isGroup) _buildMembersBar(),
          if (viewController.isReal) buildGreetTips(),
          Container(
            decoration: BoxDecoration(
              gradient: LinearGradient(
                begin: Alignment.topCenter,
                end: Alignment.bottomCenter,
                colors: [Color(0xFF252230).withValues(alpha: 0.5), Color(0xFF2F253B).withValues(alpha: 0.9)],
              ),
            ),
            child: SafeArea(bottom: true, child: Column(children: [buildInputBar(), buildFunctionBar()])),
          ),
        ],
      ),
    );
  }

  Widget buildFunctionBar() {
    ChatRoomBottomBarState state = viewController.barState;
    switch (state) {
      case ChatRoomBottomBarState.simple:
        {
          // if (viewController.isAi && !viewController.isGroup) {
          //   return buildSimpleBar();
          // }
          return Container();
        }

      case ChatRoomBottomBarState.detailed:
        {
          return buildDetailedBar();
        }

      case ChatRoomBottomBarState.muse:
        {
          return ChatMuseView(sendText: sendText);
        }
      case ChatRoomBottomBarState.gift:
        {
          return GiftPanel(recipient: viewController.roomViewController.userId);
        }
    }
  }

  // input mode
  final _audioInputMode = false.obs;

  Widget buildInputBar() {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      child: Obx(() {
        final isAudioMode = _audioInputMode.value;
        return GestureDetector(
          onTap:
              isAudioMode
                  ? () {
                    Toast.show(Copywriting.security_audio_input_is_too_short_to_send_);
                    viewController.cleanAudioInput();
                  }
                  : null,
          onLongPressStart:
              isAudioMode
                  ? (_) {
                    beginAudioRecord();
                  }
                  : null,
          onLongPressEnd: (_) {
            endAudioRecord();
          },
          onLongPressMoveUpdate: isAudioMode ? updateAudioRecordState : null,
          child: Container(
            height: 44,
            decoration: BoxDecoration(
              color: _audioInputMode.value ? Colors.white.withValues(alpha: 0.7) : Color(0xFFB4ADAB).withValues(alpha: 0.6),
              borderRadius: BorderRadius.circular(26),
            ),
            child: Row(
              children: [
                Obx(() {
                  return viewController.isKeyboardVisible.value
                      ? GestureDetector(
                        onTap: () {
                          viewController.textController.text += '**';
                          viewController.textController.selection = TextSelection.fromPosition(
                            TextPosition(offset: viewController.textController.text.length - 1),
                          );
                        },
                        child: Container(
                          alignment: Alignment.center,
                          width: 24,
                          height: 24,
                          margin: EdgeInsets.only(left: 12, right: 8),
                          child: Text('**', style: TextStyle(fontSize: 20, color: Colors.white)),
                        ),
                      )
                      : GestureDetector(
                        onTap: () {
                          _audioInputMode.value = !_audioInputMode.value;
                          if (viewController.barState != ChatRoomBottomBarState.simple) {
                            viewController.updateBarState(ChatRoomBottomBarState.simple);
                          }
                        },
                        child: Container(
                          margin: EdgeInsets.only(left: 12, right: 8),
                          child: Obx(() => ImageView(_audioInputMode.value ? "keyboard.png" : "audio_mode.png", width: 24, height: 24)),
                        ),
                      );
                }),
                Expanded(
                  child: Obx(
                    () =>
                        _audioInputMode.value
                            ? Row(
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                Text(Copywriting.security_hold_to_talk, style: TextStyle(color: Colors.white, fontWeight: FontWeight.w500, fontSize: 14)),
                              ],
                            )
                            : Row(
                              children: [
                                Expanded(
                                  child: TextField(
                                    onChanged: (value) {
                                      viewController.onTextChanged(value);
                                    },
                                    onSubmitted: (value) {
                                      viewController.sendText(value);
                                    },
                                    style: TextStyle(color: Colors.white, fontSize: 11, fontWeight: FontWeight.w600),
                                    controller: viewController.textController,
                                    focusNode: viewController.focusNode,
                                    decoration: InputDecoration(
                                      enabledBorder: OutlineInputBorder(borderSide: BorderSide.none),
                                      focusedBorder: OutlineInputBorder(borderSide: BorderSide.none),
                                      fillColor: Colors.transparent,
                                      filled: true,
                                      hintText: viewController.messageHints,
                                      hintStyle: TextStyle(color: Color(0x80FFFFFF), fontWeight: FontWeight.w600, fontSize: 11),
                                      floatingLabelBehavior: viewController.isGroup ? FloatingLabelBehavior.always : FloatingLabelBehavior.auto,
                                      prefix:
                                          viewController.isGroup
                                              ? Container(
                                                constraints: BoxConstraints(maxWidth: 120),
                                                margin: viewController.buildGroupAtText().isNotEmpty ? EdgeInsets.only(right: 4) : null,
                                                child: Text(
                                                  viewController.buildGroupAtText(),
                                                  style: TextStyle(
                                                    color: Colors.white,
                                                    fontSize: 11,
                                                    overflow: TextOverflow.ellipsis,
                                                    fontWeight: FontWeight.w600,
                                                  ),
                                                ),
                                              )
                                              : null,
                                      contentPadding: EdgeInsets.zero,
                                    ),
                                    textInputAction: TextInputAction.send,
                                  ),
                                ),
                                if (viewController.isAi)
                                  GestureDetector(
                                    onTap: () {
                                      if (viewController.barState != ChatRoomBottomBarState.muse) {
                                        viewController.updateBarState(ChatRoomBottomBarState.muse);
                                      } else {
                                        viewController.updateBarState(ChatRoomBottomBarState.simple);
                                      }
                                    },
                                    child: Container(
                                      margin: EdgeInsets.only(right: 6),
                                      child: Obx(
                                        () => ImageView(
                                          viewController.barState == ChatRoomBottomBarState.muse ? "tip_on.png" : "tip_off.png",
                                          width: 28,
                                          height: 28,
                                        ),
                                      ),
                                    ),
                                  ),
                                GestureDetector(
                                  onTap: () {
                                    if (viewController.barState != ChatRoomBottomBarState.detailed) {
                                      viewController.updateBarState(ChatRoomBottomBarState.detailed);
                                    } else {
                                      viewController.updateBarState(ChatRoomBottomBarState.simple);
                                    }
                                  },
                                  child: Container(
                                    margin: EdgeInsets.only(right: 12),
                                    child: ImageView(
                                      viewController.barState == ChatRoomBottomBarState.detailed ? "chat_add.png" : "chat_add.png",
                                      width: 28,
                                      height: 28,
                                    ),
                                  ),
                                ),
                              ],
                            ),
                  ),
                ),
              ],
            ),
          ),
        );
      }),
    );
  }

  void beginAudioRecord() {
    showAudioInputMask?.call(true);
    viewController._recordAudioBegin();
  }

  final _isCanceled = false.obs;

  void endAudioRecord() {
    showAudioInputMask?.call(false);
    viewController._recordAudioEnd(_isCanceled.value);

    // reset mask
    _isCanceled.value = false;
    cancelAudio?.call(false);
  }

  void updateAudioRecordState(LongPressMoveUpdateDetails details) {
    if (details.localPosition.dy >= 0) {
      if (_isCanceled.value == false) return;
      cancelAudio?.call(false);
      _isCanceled.value = false;
    } else {
      if (_isCanceled.value == true) return;
      cancelAudio?.call(true);
      _isCanceled.value = true;
    }
  }

  Widget buildSimpleBar() {
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 16),
      child: Row(
        spacing: 8,
        children: [
          GestureDetector(
            onTap: () {
              viewController.askForImage();
            },
            child: Container(
              height: 30,
              padding: EdgeInsets.symmetric(horizontal: 12, vertical: 6),
              decoration: BoxDecoration(borderRadius: BorderRadius.circular(15), color: Color(0xFF63616B).withValues(alpha: 0.8)),
              child: Row(
                spacing: 4,
                children: [
                  ImageView("btn_pic.png", width: 16, height: 16, fit: BoxFit.cover),
                  Text(Security.security_Ask, style: TextStyle(color: Colors.white, fontSize: 13, fontWeight: FontWeight.w500)),
                ],
              ),
            ),
          ),
          if (Preferences.instance.supportVeo(viewController.userId.toString()))
            GestureDetector(
              onTap: () {
                viewController.askForVideo();
              },
              child: Stack(
                children: [
                  Container(
                    height: 30,
                    padding: EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                    decoration: BoxDecoration(borderRadius: BorderRadius.circular(15), color: Color(0xFF63616B).withValues(alpha: 0.8)),
                    child: Row(
                      spacing: 4,
                      children: [
                        Image.asset("btn_video.png", width: 16, height: 16, fit: BoxFit.cover),
                        Text(Security.security_Ask, style: TextStyle(color: Colors.white, fontSize: 13, fontWeight: FontWeight.w500)),
                      ],
                    ),
                  ),
                  Positioned(
                    right: 0,
                    child: Transform.translate(
                      offset: Offset(2, -6),
                      child: Container(
                        padding: EdgeInsets.symmetric(horizontal: 4, vertical: 2),
                        decoration: BoxDecoration(borderRadius: BorderRadius.circular(12), color: Colors.black.withValues(alpha: 0.4)),
                        child: Obx(
                          () => Row(
                            children: [
                              // if (!viewController.hasVideoConfig) SizedBox(height: 10, width: 10, child: CircularProgressIndicator(strokeWidth: 2)),
                              if (viewController.hasVideoConfig)
                                Row(
                                  children: [
                                    if (viewController.isGenerateVideoPremiumFree)
                                      Row(
                                        children: [
                                          ImageView("premium.png", width: 12, height: 12),
                                          SizedBox(width: 1),
                                          Text(Security.security_Free, style: TextStyle(color: Colors.white, fontSize: 9, fontWeight: FontWeight.bold)),
                                        ],
                                      ),
                                    if (viewController.isGenerateVideoFree)
                                      Text(Security.security_Free, style: TextStyle(color: Colors.white, fontSize: 9, fontWeight: FontWeight.bold)),
                                  ],
                                ),
                            ],
                          ),
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ),
          GestureDetector(
            onTap: onCreateImageButtonClicked,
            child: Container(
              height: 30,
              padding: EdgeInsets.symmetric(horizontal: 12, vertical: 6),
              decoration: BoxDecoration(borderRadius: BorderRadius.circular(15), color: Color(0xFF63616B).withValues(alpha: 0.8)),
              child: Row(
                spacing: 4,
                children: [
                  ImageView("btn_custom.png", width: 16, height: 16, fit: BoxFit.cover),
                  Text(Security.security_Custom, style: TextStyle(color: Colors.white, fontSize: 13, fontWeight: FontWeight.w500)),
                ],
              ),
            ),
          ),
          GestureDetector(
            onTap: () {
              viewController.toCall(0);
            },
            child: Container(
              height: 30,
              padding: EdgeInsets.symmetric(horizontal: 12, vertical: 6),
              decoration: BoxDecoration(borderRadius: BorderRadius.circular(15), color: Color(0xFF63616B).withValues(alpha: 0.8)),
              child: Row(
                spacing: 4,
                children: [
                  ImageView("btn_call.png", width: 16, height: 16, fit: BoxFit.cover),
                  Text(Security.security_Call, style: TextStyle(color: Colors.white, fontSize: 13, fontWeight: FontWeight.w500)),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  void onCreateImageButtonClicked() {
    Get.lazyPut(() => CreateImagePanelController());
    Get.bottomSheet(CreateImagePanel(), persistent: false, useRootNavigator: true);
  }

  void onChatHistoryButtonClicked() {
    Get.toNamed(Routers.chatHistory);
  }

  void askForImage() {
    viewController.askForImage();
  }

  Widget buildDetailedBar() {
    List<Map<String, dynamic>> items;
    if (viewController.isGroup) {
      items = [
        {Security.security_title: Security.security_Photo, Security.security_icon: "btn_pic.png", Security.security_action: viewController.showImageSelector},
        {Security.security_title: Security.security_History, Security.security_icon: "btn_history.png", Security.security_action: onChatHistoryButtonClicked},
      ];
    } else {
      if (viewController.isAi) {
        items = [
          {Security.security_title: "Ask for pic", Security.security_icon: "btn_pic.png", Security.security_action: viewController.askForImage},
          {Security.security_title: "Ask for video", Security.security_icon: "btn_video.png", Security.security_action: viewController.askForVideo},
          {
            Security.security_title: "Audio Call",
            Security.security_icon: "btn_call.png",
            Security.security_action: () => viewController.toCall(StreamType.audio.index),
          },
          {Security.security_title: Security.security_Gift, Security.security_icon: "btn_gift.png", Security.security_action: viewController.showGiftPanel},
          {
            Security.security_title: Security.security_Photo,
            Security.security_icon: "btn_camera.png",
            Security.security_action: viewController.showImageSelector,
          },
          {Security.security_title: Security.security_History, Security.security_icon: "btn_history.png", Security.security_action: onChatHistoryButtonClicked},
          {Security.security_title: Security.security_Custom, Security.security_icon: "btn_custom.png", Security.security_action: onCreateImageButtonClicked},
        ];
      } else {
        items = [
          {Security.security_title: Security.security_Photo, Security.security_icon: "btn_pic.png", Security.security_action: viewController.showImageSelector},
          {Security.security_title: Security.security_Video, Security.security_icon: "btn_video.png", Security.security_action: viewController.onSendVideo},
          {
            Security.security_title: Copywriting.security_video_Call,
            Security.security_icon: "btn_video_call.png",
            Security.security_action: () => viewController.toCall(StreamType.video.index),
          },
          {
            Security.security_title: Copywriting.security_audio_Call,
            Security.security_icon: "btn_call.png",
            Security.security_action: () => viewController.toCall(StreamType.audio.index),
          },
          {Security.security_title: Security.security_Gift, Security.security_icon: "btn_gift.png", Security.security_action: viewController.showGiftPanel},
          {Security.security_title: Security.security_History, Security.security_icon: "btn_history.png", Security.security_action: onChatHistoryButtonClicked},
        ];
      }
    }

    return Container(
      padding: EdgeInsets.only(left: 16, right: 16, top: 16),
      color: Colors.transparent,
      child: MasonryGridView.count(
        shrinkWrap: true,
        crossAxisCount: 4,
        crossAxisSpacing: 2,
        itemCount: items.length,
        itemBuilder: (context, index) {
          Map<String, dynamic> item = items[index];
          return GestureDetector(
            onTap: () {
              item[Security.security_action]?.call();
            },
            child: Column(
              children: [
                Container(
                  width: 56,
                  height: 56,
                  alignment: Alignment.center,
                  decoration: BoxDecoration(color: Color(0x26FFFFFF), borderRadius: BorderRadius.all(Radius.circular(10))),
                  child: ImageView(item[Security.security_icon] ?? '', width: 32, height: 32),
                ),
                SizedBox(height: 4),
                Container(
                  alignment: Alignment.center,
                  height: 16,
                  child: Text(item[Security.security_title] ?? '', style: TextStyle(color: Colors.white, fontWeight: FontWeight.w400, fontSize: 11)),
                ),
                SizedBox(height: 12),
              ],
            ),
          );
        },
      ),
    );
  }

  Widget _buildMemberItem(dynamic item) {
    return Obx(() {
      return Tooltip(
        message: item[Security.security_userbase]?[Security.security_nickName] ?? '',
        verticalOffset: -60,
        child: InkWell(
          onTap: () {
            viewController.selectMember(item);
          },
          child: Container(
            decoration: BoxDecoration(
              borderRadius: const BorderRadius.all(Radius.circular(16)),
              border: Border.all(
                color: viewController.rxMemberSelect[item[Security.security_userbase]?[Security.security_uid]] == 1 ? AppColors.primary : Colors.transparent,
                width: 1,
              ),
            ),
            child: Stack(
              children: [
                CachedImage.clipImage(
                  imageUrl: item[Security.security_userbase]?[Security.security_avatarUrl] ?? '',
                  width: 32,
                  height: 32,
                  borderRadius: BorderRadius.circular(16),
                ),
                if (viewController.rxMemberSelect[item[Security.security_userbase]?[Security.security_uid]] == 2)
                  Positioned.fill(
                    child: Container(
                      decoration: BoxDecoration(
                        color: Colors.black.withAlpha((255.0 * 0.4).round()),
                        borderRadius: const BorderRadius.all(Radius.circular(16)),
                      ),
                      child: Center(child: ImageView("unspeaker.webp", width: 16, height: 16)),
                    ),
                  ),
                if (item[Security.security_state] == 2 || item[Security.security_state] == 3)
                  Positioned.fill(
                    child: Container(
                      decoration: BoxDecoration(
                        color: Colors.black.withAlpha((255.0 * 0.4).round()),
                        borderRadius: const BorderRadius.all(Radius.circular(16)),
                      ),
                      child: Center(child: ImageView("deactivated.webp", width: 16, height: 16)),
                    ),
                  ),
              ],
            ),
          ),
        ),
      );
    });
  }

  Widget _buildMembersBar() {
    return viewController.membersNoOwner.isNotEmpty
        ? Container(
          padding: const EdgeInsets.all(4),
          margin: const EdgeInsets.only(left: 12, right: 12, bottom: 4),
          decoration: const BoxDecoration(color: Color(0x66252230), borderRadius: BorderRadius.all(Radius.circular(20))),
          height: 40,
          child: ListView.separated(
            scrollDirection: Axis.horizontal,
            shrinkWrap: true,
            itemBuilder: (context, index) {
              return _buildMemberItem(viewController.membersNoOwner.safeGet(index, {}));
            },
            separatorBuilder: (context, index) {
              return const SizedBox(width: 8);
            },
            itemCount: viewController.membersNoOwner.length,
          ),
        )
        : Container();
  }

  Widget buildGreetTips() {
    return Obx(() {
      return !viewController.hasMessages && showGreetTips.value
          ? Container(
            padding: const EdgeInsets.only(left: 16, right: 16),
            margin: const EdgeInsets.only(bottom: 6, top: 6),
            child: Row(
              children: [
                ...['😃 Hi~', '💝${Copywriting.security_nice_to_meet_you_}'].map(
                  (e) => GestureDetector(
                    onTap: () {
                      viewController.sendText(e);
                    },
                    child: Container(
                      margin: const EdgeInsets.only(right: 8),
                      decoration: BoxDecoration(color: Colors.black.withOpacity(0.4), borderRadius: BorderRadius.circular(8)),
                      alignment: Alignment.center,
                      padding: const EdgeInsets.only(left: 6, right: 6),
                      height: 24,
                      // width: 32,
                      child: Text(e, style: TextStyle(color: Colors.white, fontSize: 12)),
                    ),
                  ),
                ),
                const Spacer(),
                GestureDetector(
                  onTap: () {
                    showGreetTips.value = false;
                  },
                  child: Container(
                    decoration: BoxDecoration(color: Colors.black.withOpacity(0.4), borderRadius: BorderRadius.circular(8)),
                    alignment: Alignment.center,
                    padding: const EdgeInsets.only(left: 4, right: 4),
                    height: 24,
                    // width: 32,
                    child: const Icon(Icons.close, color: Colors.white, size: 14, weight: 100),
                  ),
                ),
              ],
            ),
          )
          : Container();
    });
  }
}

class ChatBottomBarController extends GetxController {
  static bool hasTipSelectMember = false;

  static bool hasTipBanMember = false;

  final roomViewController = Get.find<ChatRoomViewController>();

  bool get isAi => roomViewController.session.isAiChat;

  bool get isReal => roomViewController.session.isRealChat;

  bool get isGroup => roomViewController.session.isGroup;

  int get userId => roomViewController.userId;

  bool get hasMessages => roomViewController.messages.isNotEmpty;

  List<dynamic> get membersNoOwner => roomViewController.crowdInfo.value.membersNoOwner;

  RxMap<int, int> rxMemberSelect = RxMap(); // 保持成员的状态，1是选中，2是禁言

  List<int> get specifyRepliers => rxMemberSelect.entries.where((entry) => entry.value == 1).map((e) => e.key).toList();

  List<int> get bannedRepliers => rxMemberSelect.entries.where((entry) => entry.value == 2).map((e) => e.key).toList();

  bool get hasVideoConfig => roomViewController.hasVideoConfig;

  int get videoConfigCost => roomViewController.videoConfigCost ?? 0;

  int? get videoConfigCostType => roomViewController.videoConfigCostType;

  bool get isGenerateVideoPremiumFree => roomViewController.askVideoConfig[Security.security_freeReason] == 3 && videoConfigCost == 0;

  bool get isGenerateVideoFree => roomViewController.askVideoConfig[Security.security_freeReason] != 3 && videoConfigCost == 0;

  bool get isGenerateVideoNotFree => videoConfigCost > 0;

  String get generateVideoCostIcon => videoConfigCostType == 0 ? "coin.png" : "gem.png";

  final _barState = ChatRoomBottomBarState.simple.obs;

  ChatRoomBottomBarState get barState => _barState.value;

  set barState(ChatRoomBottomBarState value) {
    _barState.value = value;
    focusNode.unfocus();
  }

  RxBool isKeyboardVisible = false.obs;

  late TextEditingController textController;
  final FocusNode focusNode = FocusNode();

  String buildGroupAtText() {
    if (!isGroup) {
      return "";
    }
    String atMemberText = '';
    List<int> atMemberIds = specifyRepliers;
    if (atMemberIds.length == membersNoOwner.length && atMemberIds.length > 1) {
      return '@All ';
    }
    for (int i = 0; i < atMemberIds.length; i++) {
      dynamic member = membersNoOwner.firstWhere(
        (element) => element[Security.security_userbase]?[Security.security_uid] == atMemberIds[i],
        orElse: () {
          return null;
        },
      );
      if (member != null) {
        atMemberText += "@${member[Security.security_userbase]?[Security.security_nickName]} ";
      }
    }
    return atMemberText;
  }

  void selectMember(dynamic item) {
    if (item[Security.security_state] == 2) {
      Toast.show(Copywriting.security_this_member_is_expired_);
      return;
    }
    if (item[Security.security_state] == 3) {
      Toast.show(Copywriting.security_this_member_is_deactivated_);
      return;
    }
    if (rxMemberSelect.containsKey(item[Security.security_userbase]?[Security.security_uid])) {
      if (rxMemberSelect[item[Security.security_userbase]?[Security.security_uid]] == 1) {
        rxMemberSelect[item[Security.security_userbase]?[Security.security_uid]] = 2;
        if (!hasTipBanMember) {
          hasTipBanMember = true;
          insertMessageTips(Copywriting.security_the_muted_member_will_not_reply_your_message);
        }
      } else {
        rxMemberSelect.remove(item[Security.security_userbase]?[Security.security_uid]);
      }
    } else {
      rxMemberSelect[item[Security.security_userbase]?[Security.security_uid] ?? 0] = 1;
      if (!hasTipSelectMember) {
        hasTipSelectMember = true;
        insertMessageTips(Copywriting.security_auto___enabled__The_mentioned_member_s__will_reply_your_message_);
      }
    }
  }

  @override
  void onInit() {
    super.onInit();
    textController = TextEditingController(text: roomViewController.session.draft.value);
    focusNode.addListener(() {
      isKeyboardVisible.value = focusNode.hasFocus;
    });
  }

  @override
  void onClose() {
    focusNode.dispose();
    textController.dispose();
    super.onClose();
  }

  void cleanAudioInput() {
    AudioManager.instance.cancel();
  }

  void _recordAudioBegin() {
    // recorder active
    AudioManager.instance.begin();
  }

  void _recordAudioEnd(bool isCanceled) async {
    if (isCanceled) {
      await AudioManager.instance.cancel();
      return;
    }
    final recordInfo = await AudioManager.instance.finish();
    if (recordInfo == null) return;
    sendAudio(recordInfo);
  }

  void sendText(String text) {
    textController.clear();
    onTextChanged('');
    if (isGroup) {
      text = buildGroupAtText() + text;
    }
    roomViewController.sendText(text, specifyRepliers: specifyRepliers, bannedRepliers: bannedRepliers);
  }

  void sendAudio((String, int) recordInfo) async {
    ChatAudioMessage message = ChatAudioMessage.fromAudio(
      recordInfo.$1,
      userId,
      DateTime.now().millisecondsSinceEpoch.toString(),
      recordInfo.$2,
      specifyRepliers: specifyRepliers,
      bannedRepliers: bannedRepliers,
      session: roomViewController.session,
    );
    if (roomViewController.session.isScriptChat) message.chatStatus = 2;
    roomViewController.sendMessage(message);
  }

  void toCall(type) {
    roomViewController.toCall(type);
  }

  void unfocus() {
    updateBarState(ChatRoomBottomBarState.simple);
    focusNode.unfocus();
  }

  void updateBarState(ChatRoomBottomBarState state) {
    if (barState == ChatRoomBottomBarState.muse && state != ChatRoomBottomBarState.muse) {
      Get.delete<ChatMuseViewController>();
    }
    barState = state;
  }

  void showGiftPanel() {
    barState = ChatRoomBottomBarState.gift;
  }

  askForVideo() async {
    if (!roomViewController.hasVideoConfig) {
      Toast.show(Copywriting.security_generate_config_loading);
      return;
    }

    ReportManager.sendEvent(Security.security_video_generate_view_event, {
      Security.security_entrance: Security.security_chat_bottom_bar_ask,
      Security.security_userId: "${roomViewController.userId}",
    });
    roomViewController.showGenerateVideoPanel();
  }

  void askForImage() {
    List tips = Preferences.instance.askPicTips;
    int index = Random().nextInt(tips.length);
    sendText(tips[index]);
  }

  void insertMessageTips(String tips) {
    roomViewController.insertMessageTips(tips);
  }

  void showImageSelector() {
    showAppBottomSheet([
      ListTile(
        leading: Icon(Icons.photo_library),
        title: Text(Copywriting.security_select_from_the_album),
        onTap: () async {
          Get.back();
          pickImage(ImageSource.gallery);
        },
      ),
      ListTile(
        leading: Icon(Icons.photo_camera),
        title: Text(Copywriting.security_turn_on_the_camera),
        onTap: () async {
          Get.back();
          pickImage(ImageSource.camera);
        },
      ),
    ]);
  }

  void onSendVideo() {
    showAppBottomSheet([
      ListTile(
        leading: Icon(Icons.photo_library),
        title: Text(Copywriting.security_select_from_the_album),
        onTap: () async {
          Get.back();
          pickVideo(ImageSource.gallery);
        },
      ),
      ListTile(
        leading: Icon(Icons.photo_camera),
        title: Text(Copywriting.security_turn_on_the_camera),
        onTap: () async {
          Get.back();
          pickVideo(ImageSource.camera);
        },
      ),
    ]);
  }

  void pickVideo(ImageSource source) async {
    XFile? file;
    Uint8List? videoBytes;
    try {
      file = await ImagePicker().pickVideo(source: source);
      videoBytes = await file?.readAsBytes();
    } catch (e) {
      debugPrint('$e');
      Toast.error('Video pick failed: $e');
    }
    if (file == null || videoBytes == null) {
      return;
    }

    Toast.loading();
    try {
      String? url = await FilePushService.instance.upload(videoBytes, FileType.im, ext: Security.security_mp4);
      if (url == null || url.isEmpty) {
        Toast.error(Copywriting.security_upload_failed__please_try_again_later);
        return;
      }

      String path = file.path;
      Uint8List? thumbnailBytes = await VideoThumbnail.thumbnailData(
        video: path,
        imageFormat: ImageFormat.JPEG,
        maxWidth: 300, // specify the width of the thumbnail, let the height auto-scaled to keep the source aspect ratio
        quality: 25,
      );
      String? thumbnailUrl;
      if (thumbnailBytes != null) {
        thumbnailUrl = await FilePushService.instance.upload(thumbnailBytes, FileType.im, ext: Security.security_jpg);
      }

      if (thumbnailUrl == null || thumbnailUrl.isEmpty) {
        Toast.error(Copywriting.security_upload_failed__please_try_again_later);
        return;
      }

      Toast.dismiss();
      ChatVideoMessage message = ChatVideoMessage.fromVideo(
        url,
        thumbnailUrl,
        videoBytes.length,
        roomViewController.userId,
        specifyRepliers: specifyRepliers,
        bannedRepliers: bannedRepliers,
        session: roomViewController.session,
      );

      roomViewController.sendMessage(message);
    } catch (e) {
      debugPrint('$e');
      Toast.error('Video send failed: $e');
      return;
    }
  }

  void pickImage(ImageSource source) async {
    XFile? file;
    try {
      file = await ImagePicker().pickImage(source: source);
    } catch (e) {
      debugPrint('$e');
    }
    if (file == null) return;

    Uint8List? compressed = await FlutterImageCompress.compressWithFile(file.path);
    if (compressed == null) return;

    Toast.loading();
    String? url = await FilePushService.instance.upload(compressed, FileType.im, ext: Security.security_jpg);
    Toast.dismiss();
    if (url == null || url.isEmpty) {
      Toast.error(Copywriting.security_upload_failed__please_try_again_later);
      return;
    }

    DefaultCacheManager().putFileStream(url, Stream.value(compressed));
    var thumbnail = await FlutterImageCompress.compressWithFile(file.path, minWidth: 30, minHeight: 30, quality: 1);

    String? thumbnailBase64;
    if (thumbnail != null) {
      thumbnailBase64 = const Base64Encoder().convert(thumbnail);
    }

    ChatImageMessage message = ChatImageMessage.fromImage(
      url,
      thumbnailBase64,
      roomViewController.userId,
      specifyRepliers: specifyRepliers,
      bannedRepliers: bannedRepliers,
      session: roomViewController.session,
    );

    roomViewController.sendMessage(message);
  }

  void onTextChanged(String text) {
    ChatSession s = roomViewController.session;
    s.draft.value = text;
    ChatManager.instance.updateChatSession(s);
  }

  String get messageHints {
    if (isReal) {
      return Copywriting.security_send_a_message___;
    } else {
      return Copywriting.security_send_message__reply_by_AI;
    }
  }
}
