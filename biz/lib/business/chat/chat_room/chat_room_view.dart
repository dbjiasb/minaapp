import 'dart:async';
import 'dart:convert';

import 'package:biz/business/chat/chat_room_cells/chat_image_message.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:biz/base/api_service/api_response.dart';
import 'package:biz/base/assets/image_path.dart';
import 'package:biz/base/crypt/copywriting.dart';
import 'package:biz/base/crypt/security.dart';
import 'package:biz/base/event_center/event_center.dart';
import 'package:biz/base/router/router_names.dart';
import 'package:biz/business/chat/ai_mode/service/ai_mode_service.dart';
import 'package:biz/business/chat/call/call_manager.dart';
import 'package:biz/business/chat/chat_room_cells/chat_message.dart';
import 'package:biz/business/chat/chat_room_cells/chat_tip_message.dart';
import 'package:biz/business/chat/setting/chat_model_view.dart';
import 'package:biz/business/chat/setting/chat_setting_helper.dart';
import 'package:biz/business/chat/setting/message_option_view.dart';
import 'package:biz/business/crowd/crowd_manager.dart';
import 'package:biz/core/account/account_service.dart';
import 'package:biz/core/report/report_helper.dart';
import 'package:biz/core/user_manager/user_manager.dart';
import 'package:biz/core/util/string_ext.dart';
import 'package:biz/shared/rv_helper.dart';

import '../../../base/ads/ad_service.dart';
import '../../../base/api_service/api_request.dart';
import '../../../base/api_service/api_service.dart';
import '../../../base/assets/image_view.dart';
import '../../../base/crypt/apis.dart';
import '../../../base/crypt/images.dart';
import '../../../base/privacy/ai_consent_service.dart';
import '../../../base/preferences/preferences.dart';
import '../../../base/push_service/push_service.dart';
import '../../../base/router/route_helper.dart';
import '../../../base/ui/overlay_popup.dart';
import '../../../core/util/cached_image.dart';
import '../../../core/util/log_util.dart';
import '../../../shared/alert.dart';
import '../../../shared/app_theme.dart';
import '../../../shared/toast/toast.dart';
import '../chat_manager.dart';
import '../chat_room_cells/chat_anchor_album_message.dart';
import '../chat_room_cells/chat_audio_message.dart';
import '../chat_room_cells/chat_call_cell.dart';
import '../chat_room_cells/chat_cell.dart';
import '../chat_room_cells/chat_generating_message.dart';
import '../chat_room_cells/chat_system_message.dart';
import '../chat_room_cells/chat_text_cell.dart';
import '../chat_room_cells/chat_time_message.dart';
import '../chat_room_cells/chat_video_message.dart';
import '../chat_session.dart';
import '../chat_voice_manager.dart';
import '../chat_voice_player.dart';
import '../create_image/create_image_manager.dart';
import '../generate_video/generate_video_panel.dart';
import './chat_bottom_bar.dart';
import 'level_up_pop_up.dart';
import 'sidebar.dart';
import 'package:cached_network_image/cached_network_image.dart';

const String kLogTag = '[TalkRoom]';

String chatRoomViewTag = Security.security_chat_room_view;

class ChatRoomView extends StatelessWidget {
  ChatRoomView({super.key});

  final GlobalKey<ScaffoldState> _scaffoldKey = GlobalKey();

  ChatRoomViewController viewController = Get.put(
    ChatRoomViewController(Get.arguments),
  );

  ChatSession get session => viewController.session;

  // used in audio input

  void _onBackgroundClicked() {
    viewController.unfocus();
  }

  void _onBackButtonClicked() {
    /// 退出界面保存一次
    ChatManager.instance.updateChatSession(session);
    RH.back();
  }

  Widget _buildChatRoomView() {
    return Expanded(
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 12),
        child:
            viewController.messages.isEmpty
                ? null
                : ListView.builder(
                  itemBuilder: (BuildContext context, int index) {
                    OverlayPopupController overlayPopupController =
                        OverlayPopupController();

                    ChatMessage message = viewController.messages[index];
                    Widget cell = ChatCell.create(
                      message,
                      resend: viewController.resendMessage,
                      unlock: viewController.unlockMessage,
                      reload: viewController.reloadMessage,
                      download: viewController.downloadMessage,
                      onTap: viewController.onTapMessage,
                      onContinue: viewController.onAIContinue,
                      generateVideo: viewController.generateVideo,
                    );

                    if (message is ChatTipsMessage ||
                        message is ChatSystemMessage ||
                        message is ChatTimeMessage ||
                        message is ChatGeneratingMessage) {
                      return cell;
                    }

                    Widget paddingWidget = GestureDetector(
                      onTap: () {
                        overlayPopupController.hideMenu();
                      },
                      child: SizedBox(width: 70),
                    );

                    return OverlayPopup(
                      pressType: PressType.longPress,
                      showArrow: false,
                      position:
                          index >= viewController.messages.length - 2
                              ? PreferredPosition.bottom
                              : PreferredPosition.top,
                      controller: overlayPopupController,
                      child: cell,
                      menuBuilder: () {
                        return Row(
                          mainAxisAlignment:
                              message.isMine()
                                  ? MainAxisAlignment.end
                                  : MainAxisAlignment.start,
                          children: [
                            if (message.isMine()) paddingWidget,
                            Flexible(
                              child: MessageOptionView(
                                viewController.messages[index],
                                viewController,
                                overlayPopupController.hideMenu,
                              ),
                            ),
                            if (!message.isMine()) paddingWidget,
                          ],
                        );
                      },
                    );
                  },
                  itemCount: viewController.messages.length,
                  padding: EdgeInsets.only(bottom: 10),
                  reverse: true,
                ),
      ),
    );
  }

  Widget _buildChatDrawer() {
    return Drawer(
      backgroundColor: AppColors.base_background,
      child: SafeArea(
        child: Align(
          alignment: Alignment.topRight,
          child: Container(
            margin: EdgeInsets.only(top: 10, left: 16, right: 16),
            decoration: BoxDecoration(
              borderRadius: BorderRadius.all(Radius.circular(8)),
              color: Color(0xFF202026),
            ),
            child: ListView(
              shrinkWrap: true, // 自适应高度
              children: [
                if (viewController.isAiChat && !session.isGroup)
                  _drawerTemplate(
                    Copywriting.security_chat_Models,
                    onTap: () {
                      Get.bottomSheet(ChatModeView());
                    },
                  ),
                if (viewController.isAiChat && !session.isGroup)
                  _drawerTemplate(
                    Security.security_reset,
                    onTap: () {
                      ChatSettingHelper.doReset(
                        tUid: viewController.userId,
                        sessionId: viewController.session.id,
                        userName: viewController.session.name,
                      );
                    },
                  ),
                _drawerTemplate(
                  Copywriting.security_clear_Chat_History,
                  onTap: () {
                    ChatSettingHelper.doClearHistory(
                      userName: viewController.session.name,
                      onConfirm: viewController.clearHistory,
                    );
                  },
                ),
                _drawerTemplate(
                  Security.security_Report,
                  onTap: () {
                    ReportHelper.showReportDialog(
                      int.parse(viewController.session.id),
                    );
                  },
                ),
                Obx(() {
                  return _drawerOption(
                    Security.security_block,
                    onChange: (value) {
                      showConfirmAlert(
                        Security.security_block,
                        Copywriting
                            .security_are_you_sure_you_want_to_block_this_user_,
                        onConfirm: () {
                          UserManager.instance.blockUser(
                            viewController.session.userId,
                            value,
                          );
                        },
                      );
                    },
                    value: UserManager.instance.isBlocked(
                      viewController.session.userId,
                    ),
                  );
                }),
              ],
            ),
          ),
        ),
      ),
    );
  }

  // used in audio input
  final isAudioMaskShow = false.obs;
  final isAudioCanceled = false.obs;

  void showAudioMask(bool show) {
    isAudioMaskShow.value = show;
  }

  void cancelAudio(bool cancel) {
    isAudioCanceled.value = cancel;
  }

  Widget _buildAudioInputMask() {
    return Positioned(
      bottom: 0,
      left: 0,
      right: 0,
      child: Obx(() {
        if (!isAudioMaskShow.value) {
          return Container();
        }
        return Container(
          height: 210,
          decoration: BoxDecoration(
            gradient: LinearGradient(
              begin: Alignment.topCenter,
              end: Alignment.bottomCenter,
              colors: [
                Colors.black.withValues(alpha: 0),
                Colors.black.withValues(alpha: 0.61),
                Colors.black.withValues(alpha: 0.75),
              ],
            ),
          ),
          child: Column(
            children: [
              Container(
                padding: EdgeInsets.only(bottom: 12, top: 30),
                child: Center(
                  child: Obx(
                    () =>
                        isAudioCanceled.value
                            ? Text(
                              Copywriting.security_release_Cancel,
                              style: TextStyle(
                                color: Color(0xFFF8397D),
                                fontSize: 13,
                                fontWeight: AppFonts.medium,
                              ),
                            )
                            : Text(
                              Copywriting.security_release_Send,
                              style: TextStyle(
                                color: Colors.white,
                                fontSize: 13,
                                fontWeight: AppFonts.medium,
                              ),
                            ),
                  ),
                ),
              ),
              Container(
                height: 132,
                clipBehavior: Clip.hardEdge,
                alignment: Alignment.topCenter,
                decoration: BoxDecoration(
                  color: Colors.transparent,
                  image: DecorationImage(
                    image: ImageView.getImageProvider(
                      Images.security_audio_mask_png,
                    ),
                    fit: BoxFit.fitWidth,
                    alignment: Alignment.topCenter,
                  ),
                ),
                child: Column(
                  children: [
                    SizedBox(height: 10),
                    Container(
                      height: 72,
                      padding: EdgeInsets.all(6),
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        border: Border.all(color: Color(0xFFF8397D), width: 1),
                      ),
                      child: ImageView(
                        isAudioCanceled.value
                            ? Images.security_audio_cancel_png
                            : Images.security_audio_on_webp,
                      ),
                    ),
                    Spacer(),
                  ],
                ),
              ),
            ],
          ),
        );
      }),
    );
  }

  Widget _drawerTemplate(String title, {Function()? onTap, Widget? tail}) {
    return InkWell(
      onTap: () {
        Get.back();
        onTap?.call();
      },
      child: Container(
        height: 44,
        padding: EdgeInsets.symmetric(vertical: 12, horizontal: 16),
        child: Row(
          children: [
            Text(
              title,
              style: TextStyle(
                color: Colors.white,
                fontSize: 13,
                fontWeight: FontWeight.w500,
              ),
            ),
            Spacer(),
            tail ??
                ImageView(
                  Images.security_arrow_right_png,
                  height: 16,
                  width: 16,
                ),
          ],
        ),
      ),
    );
  }

  Widget _drawerOption(
    String title, {
    Function(bool value)? onChange,
    required bool value,
  }) {
    return Container(
      height: 44,
      margin: EdgeInsets.only(bottom: 8),
      padding: EdgeInsets.symmetric(horizontal: 16),
      child: Row(
        children: [
          Text(
            title,
            style: TextStyle(
              color: Colors.white,
              fontSize: 13,
              fontWeight: FontWeight.w500,
            ),
          ),
          Spacer(),
          Switch(
            value: value,
            activeColor: Colors.white,
            inactiveThumbColor: Colors.white,
            activeTrackColor: AppColors.mainLightColor,
            inactiveTrackColor: const Color(0x33D2C0FF),
            onChanged: (bool val) {
              onChange?.call(val);
            },
          ),
        ],
      ),
    );
  }

  Widget _buildBackgroundView() {
    return Obx(() {
      String url = viewController.session.backgroundUrl.value;
      debugPrint('viewController.session.backgroundUrl.value: $url');
      return url.isNotEmpty
          ? CachedImage(
            imageUrl: url,
            fit: BoxFit.cover,
            errorWidget: (context, url, error) => SizedBox.shrink(),
          )
          : SizedBox.shrink();
    });
  }

  Widget _buildNavigationBar() {
    return Container(
      height: 44,
      alignment: Alignment.center,
      padding: const EdgeInsets.only(left: 16),
      child: Row(
        children: [
          GestureDetector(
            onTap: _onBackButtonClicked,
            child: Container(
              width: 32,
              height: 32,
              alignment: Alignment.center,
              child: CachedNetworkImage(
                imageUrl: ImagePath.ic_arrow_left_circle,
                width: 32,
                height: 32,
              ),
            ),
          ),
          SizedBox(width: 10),
          GetBuilder<ChatRoomViewController>(
            id: Security.security_kTagChatRoomHeader,
            builder: (_) {
              return Container(
                padding: EdgeInsets.only(left: 2, right: 12),
                height: 40,
                alignment: Alignment.center,
                decoration: BoxDecoration(
                  color: Color(0xCC333333),
                  borderRadius: BorderRadius.circular(20),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    GestureDetector(
                      onTap: () async {
                        if (session.isGroup) {
                          dynamic result =
                              await viewController.toCrowInfoView();
                          if (result is CrowdInfo) {
                            viewController.crowdInfo.value = result;
                            viewController.updateGroupInfoIfNeed();
                          }
                        } else {
                          viewController.toPersonalPage();
                        }
                      },
                      child: Container(
                        width: 36,
                        height: 36,
                        decoration: BoxDecoration(
                          border: Border.all(color: Colors.white, width: 1),
                          borderRadius: BorderRadius.circular(18),
                          image: DecorationImage(
                            image: CachedImageProvider(
                              viewController.session.avatar,
                            ),
                            fit: BoxFit.cover,
                          ),
                        ),
                      ),
                    ),
                    SizedBox(width: 10),
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Text(
                          viewController.session.name,
                          style: TextStyle(
                            color: Colors.white,
                            fontSize: 14,
                            fontWeight: FontWeight.bold,
                            overflow: TextOverflow.ellipsis,
                          ),
                          maxLines: 1,
                        ),
                        if (session.isPGCAI)
                          Obx(() {
                            Map mod = AIModeService.instance.getCurMode(
                              session.id,
                            );
                            return mod.isEmpty
                                ? SizedBox()
                                : GestureDetector(
                                  onTap: () {
                                    RH.toPage(
                                      Routers.modeList,
                                      params: {
                                        Security.security_uid: session.id,
                                        Security.security_defaultId:
                                            '${mod[Security.security_id]}',
                                      },
                                    );
                                  },
                                  child: Row(
                                    mainAxisAlignment: MainAxisAlignment.start,
                                    mainAxisSize: MainAxisSize.min,
                                    children: [
                                      Text(
                                        mod[Security.security_name] ?? '',
                                        style: TextStyle(
                                          color: Color(0xFF999999),
                                          fontSize: 11,
                                          overflow: TextOverflow.ellipsis,
                                          height: 1,
                                        ),
                                        maxLines: 1,
                                      ),
                                      SizedBox(width: 2),
                                      ImageView(
                                        Images.security_mode_change_png,
                                        height: 12,
                                        width: 12,
                                      ),
                                    ],
                                  ),
                                );
                          }),
                      ],
                    ),
                  ],
                ),
              );
            },
          ),
          Spacer(),
          GestureDetector(
            onTap: () {
              RH.toRecharge((session.isAiChat || session.isGroup) ? 0 : 1);
            },
            child: Container(
              padding: EdgeInsets.symmetric(horizontal: 7, vertical: 4),
              decoration: BoxDecoration(
                color: Color(0xCC333333),
                borderRadius: BorderRadius.circular(14),
              ),
              child: Row(
                spacing: 4,
                children: [
                  ImageView(
                    session.isAiChat || session.isGroup
                        ? Images.security_coin_png
                        : Images.security_gem_png,
                    height: 16,
                    width: 16,
                  ),
                  Obx(
                    () => Text(
                      session.isAiChat || session.isGroup
                          ? MyAccount.coins.toFixString
                          : MyAccount.gems.toFixString,
                      style: TextStyle(color: Colors.white, fontSize: 12),
                    ),
                  ),
                ],
              ),
            ),
          ),
          IconButton(
            onPressed: () {
              UserManager.instance.getUserSettings(session.userId);
              _scaffoldKey.currentState?.openEndDrawer();
            },
            icon: ImageView(Images.security_more_png, width: 24, height: 24),
          ),
          SizedBox(width: 5),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return PopScope(
      onPopInvokedWithResult: (didPop, ret) {
        if (didPop) {
          ChatManager.instance.updateChatSession(session);
        }
      },
      child: GestureDetector(
        onTap: _onBackgroundClicked,
        behavior: HitTestBehavior.opaque,
        child: Scaffold(
          key: _scaffoldKey,
          endDrawer: _buildChatDrawer(),
          backgroundColor: AppColors.base_background,
          resizeToAvoidBottomInset: true,
          body: Stack(
            fit: StackFit.expand,
            children: [
              _buildBackgroundView(),
              SafeArea(
                bottom: false,
                child: Column(
                  children: [
                    _buildNavigationBar(),
                    Obx(() => _buildChatRoomView()),
                    ChatBottomBar(
                      showAudioInputMask: showAudioMask,
                      cancelAudio: cancelAudio,
                      sendText: viewController.sendText,
                    ),
                  ],
                ),
              ),
              _buildAudioInputMask(),
              RvHelper.packWidget(ChatSidebar()),
            ],
          ),
        ),
      ),
    );
  }
}

class ChatRoomViewController extends GetxController {
  final isShowAudioInputAnim = false.obs;

  Map<String, dynamic> arguments = Get.arguments;

  final ChatSession session;
  late UserProfileInfo userProfileInfo;

  int get userId => session.id.safeParse();

  Rx<CrowdInfo> crowdInfo = CrowdInfo.none().obs;

  var isKeyboardVisible = false.obs;

  RxList messages = [].obs;

  ChatMessage? focusedMessage;

  ChatGeneratingMessage? _generatingMessage;

  ChatGeneratingMessage get generatingMessage {
    _generatingMessage ??= ChatGeneratingMessage.placeholder(userId);
    return _generatingMessage!;
  }

  Timer? _generatingTimer;

  List waitingMessages = [];

  bool get isRealChat => session.accountType == 0;

  bool get isAiChat => !isRealChat;

  ChatRoomViewController(Map<String, dynamic> arguments)
    : session = createSession(arguments);

  @override
  void onInit() async {
    super.onInit();

    AIConsentService.promptForEntryIfNeeded(feature: AIConsentFeature.chat);

    ChatVoicePlayer.instance.init();
    session.unreadNumber.value = 0;
    ChatManager.instance.currentSession = session;
    //刷新session
    await refreshSession();
    debugPrint('[ChatRoom] sid:${session.id}, greeted: ${session.greeted}');

    if (!session.greeted) {
      ChatManager.instance.sayHelloIfNeeded(session);
    }

    //查聊天记录
    List<ChatMessage> results = await ChatManager.instance.messageHandler
        .queryMessages(session.id);
    messages.addAll(results);
    insertAiTipsMessageIfNeeded();
    showContinueButtonIfNeed();

    EventCenter.instance.addListener(
      kEventCenterDidQueriedNewMessages,
      handlePullMessages,
    );
    EventCenter.instance.addListener(
      kEventCenterDidReceivedNewMessages,
      handlePushMessages,
    );
    EventCenter.instance.addListener(
      kEventCenterDidPreparedImageMessage,
      onImagePrepared,
    );
    EventCenter.instance.addListener(
      Security.security_kDidCreateRole,
      onInfoChange,
    );
    updateInfoIfNeed();

    PushService.instance.addObserver(
      PushId.kLevelUpMessageId,
      handleLevelUpMessage,
    );

    VideoCreateManager.getVideoConfig(userId);
  }

  void handleLevelUpMessage(Event event) {
    Map data = event.data;
    if (data.isEmpty) return;

    int beforeLevel = data[Security.security_beforeLevel];
    int afterLevel = data[Security.security_afterLevel];
    session.nextLevelRatio.value =
        ((data[Security.security_progress] ?? 0) * 100).toInt();
    session.level.value = afterLevel;

    if (beforeLevel != afterLevel) {
      ChatManager.instance.updateChatSession(session);

      int rewardCoin = data[Security.security_coinAward] ?? 0;
      int rewardGem = data[Security.security_gemAward] ?? 0;
      Map rewardMode = data[Security.security_upgradeMode] ?? {};

      LevelUpPopUp.show(
        level: afterLevel,
        avatar: session.avatar,
        rewardCoin: rewardCoin,
        rewardGem: rewardGem,
        rewardMode: rewardMode,
      );
    }

    debugPrint('[ChatRoom] handleLevelUpMessage: $data');
  }

  initUserProfileInfo() async {
    userProfileInfo = UserProfileInfo({
      Security.security_coverUrl: session.backgroundUrl.value,
      Security.security_userInfo: {
        Security.security_bio: session.bio,
        Security.security_baseInfo: {
          Security.security_uid: userId,
          Security.security_nickName: session.name,
          Security.security_avatarUrl: session.avatar,
          Security.security_accountType: session.accountType,
        },
      },
    });
  }

  onImagePrepared(Event event) {
    ChatMessage message = event.data[Security.security_message];
    //替换messages中的消息
    replaceMessage(message);
  }

  onInfoChange(Event event) {
    updateInfoIfNeed();
  }

  void toCall(int type) {
    Map args = {
      Security.security_callReason: Security.security_toCall,
      Security.security_session: {
        Security.security_backgroundUrl: session.backgroundUrl.value,
        Security.security_name: session.name,
        Security.security_id: session.id,
        Security.security_avatar: session.avatar,
        // Security.security_accountType: session.accountType,
      },
      Security.security_type: type,
      Security.security_ai: isAiChat ? 1 : 0,
    };
    CallManager.instance.callOut(args);
  }

  @override
  void onReady() {
    super.onReady();
  }

  //如果是ai聊天，则插入一个系统消息
  void insertAiTipsMessageIfNeeded() {
    if (isAiChat) {
      ChatSystemMessage message = ChatSystemMessage();
      messages.add(message);
    }
  }

  void insertMessageTips(String tips) {
    ChatTipsMessage message = ChatTipsMessage.fromServer({
      Security.security_content: tips,
    });
    messages.add(message);
  }

  // 插入时间消息的方法
  void insertTimeMessages() {
    if (messages.isEmpty) return;

    // 按消息时间排序
    messages.sort((a, b) => a.date.compareTo(b.date));

    const fiveMinutes = Duration(minutes: 5);
    DateTime? lastTime;

    // 倒序遍历
    for (int i = messages.length - 1; i >= 0; i--) {
      ChatMessage message = messages[i];
      if (lastTime == null ||
          message.date.difference(lastTime) >= fiveMinutes) {
        // 插入 ChatTimeMessage
        ChatTimeMessage timeMessage = ChatTimeMessage(message.date);
        messages.insert(i + 1, timeMessage);
        lastTime = message.date;
      }
    }
  }

  static createSession(Map<String, dynamic> arguments) {
    String sessionJson = arguments[Security.security_session];
    Map<String, dynamic> sessionMap = jsonDecode(sessionJson);

    ChatSession chatSession = ChatSession.fromRouter(sessionMap);

    return chatSession;
  }

  Future<void> refreshSession() async {
    ChatSession? localSection = await ChatManager.instance.sessionHandler
        .querySession(session.id);
    if (localSection != null) {
      session.lastMessageTime = localSection.lastMessageTime;
      session.lastMessageText = localSection.lastMessageText;
      if (session.backgroundUrl.value.isEmpty) {
        session.backgroundUrl.value = localSection.backgroundUrl.value;
      }
      session.greeted = true;
    }
    return Future.value();
  }

  handlePullMessages(Event event) async {
    if (event.data[session.id] != null) {
      List newMessages = event.data[session.id];
      insertMessages(newMessages);
      showContinueButtonIfNeed(lastestMsg: newMessages.lastOrNull);
    }
  }

  handlePushMessages(Event event) async {
    if (event.data[session.id] != null) {
      List newMessages = event.data[session.id];
      insertMessages(newMessages);
      showContinueButtonIfNeed(lastestMsg: newMessages.lastOrNull);
    }
  }

  void insertMessages(List newest) {
    if (newest.isEmpty) return;
    waitingMessages.insertAll(0, newest.reversed);
    if (_generatingTimer != null) return; //如果已经有定时器了，就等定时器下一次插入消息
    removeGeneratingMessage(); //移除生成中的消息
    insetMessageFromWaiting(); //从等待队列中取出一个消息插入到消息列表中
    if (waitingMessages.isNotEmpty) {
      insertGeneratingMessage(); //如果还有消息，就插入生成中的消息
      startGeneratingTimer(); //如果还有消息，就启动定时器
    }
  }

  void insetMessageFromWaiting() {
    if (waitingMessages.isEmpty) {
      return;
    }
    ChatMessage last = waitingMessages.removeLast();
    messages.insert(0, last);
  }

  Timer? generatingMsgTimer;

  void insertGeneratingMessage() {
    //先判断第一条是不是generatingMessage
    if (messages.isNotEmpty && messages.first == generatingMessage) return;

    //判断是否包含generatingMessage，如果是，则移动到第一个
    int index = messages.indexOf(generatingMessage);
    if (index >= 0) {
      messages.remove(generatingMessage);
    }
    messages.insert(0, generatingMessage);
    generatingMsgTimer?.cancel();
    generatingMsgTimer = Timer.periodic(const Duration(seconds: 10), (timer) {
      removeGeneratingMessage();
    });
  }

  void removeGeneratingMessage() {
    if (messages.isNotEmpty && messages.first == generatingMessage) {
      //大部分情况下最后一个是generatingMessage，所以先判断最后一个
      messages.remove(generatingMessage);
    } else {
      messages.remove(generatingMessage);
    }
  }

  //#_generatingTimer
  void startGeneratingTimer() {
    if (_generatingTimer != null) {
      return;
    }
    _generatingTimer = Timer.periodic(const Duration(milliseconds: 1000), (
      timer,
    ) {
      onTimeout(timer);
    });
  }

  void onTimeout(Timer timer) {
    removeGeneratingMessage(); //移除生成中的消息
    insetMessageFromWaiting(); //从等待队列中取出一个消息插入到消息列表中
    if (waitingMessages.isNotEmpty) {
      insertGeneratingMessage(); //如果还有消息，就插入生成中的消息
    } else {
      stopGeneratingTimer(); //如果没有消息了，就停止定时器
    }
  }

  void stopGeneratingTimer() {
    if (_generatingTimer != null) {
      _generatingTimer!.cancel();
      _generatingTimer = null;
    }
  }

  @override
  void onClose() {
    EventCenter.instance.removeListener(
      kEventCenterDidQueriedNewMessages,
      handlePullMessages,
    );
    EventCenter.instance.removeListener(
      kEventCenterDidReceivedNewMessages,
      handlePushMessages,
    );
    EventCenter.instance.removeListener(
      kEventCenterDidPreparedImageMessage,
      onImagePrepared,
    );
    EventCenter.instance.removeListener(
      Security.security_kDidCreateRole,
      onInfoChange,
    );
    ChatManager.instance.currentSession = null;
    ChatVoicePlayer.instance.dealloc();
    PushService.instance.removeObserver(
      PushId.kLevelUpMessageId,
      handleLevelUpMessage,
    );
    super.onClose();
  }

  @override
  void dispose() {
    debugPrint('dispose');
    super.dispose();
  }

  void unfocus() {
    //找到ChatRoomBar
    ChatBottomBarController barController = Get.find<ChatBottomBarController>();
    barController.unfocus();
  }

  void sendText(
    String text, {
    List<int>? specifyRepliers,
    List<int>? bannedRepliers,
  }) async {
    if (text.isEmpty) {
      return;
    }
    final agreed = await AIConsentService.ensureConsent(
      feature: AIConsentFeature.chat,
    );
    if (!agreed) {
      return;
    }
    ChatMessage message = ChatTextMessage.fromText(
      text,
      userId,
      specifyRepliers: specifyRepliers,
      bannedRepliers: bannedRepliers,
      session: session,
    );
    if (session.isScriptChat) message.chatStatus = 2;
    sendMessage(message);
  }

  void sendMessage(ChatMessage message) async {
    //先插入到数据库
    int result = await ChatManager.instance.messageHandler.insertMessage(
      message,
    );
    if (result <= 0) return;
    //更新列表
    if (messages.contains(message)) {
      //重发的消息，先移除掉
      messages.remove(message);
    }

    messages.insert(0, message);
    showContinueButtonIfNeed();

    session.lastMessageText = message.externalText;
    session.lastMessageTime = DateTime.now();
    ChatManager.instance.updateChatSession(session);

    //再发送
    SendMessageResponse response = await ChatManager.instance.sendMessage(
      message,
    );
    if (response.isSuccess) {
      //用服务器返回的message替换掉自己发出去的message
      int index = messages.indexWhere(
        (element) => element.nativeId == message.nativeId,
      );
      if (index >= 0) {
        messages[index] = response.message;
        if (isAiChat) {
          insertGeneratingMessage();
        }
      } else {
        debugPrint('sendMessage: 找不到自己发出去的message');
      }
    } else {}
  }

  resendMessage(ChatMessage message) async {
    message.sendState.value = ChatMessageSendStatus.sending;
    sendMessage(message);
  }

  Future<void> downloadMessage(ChatMessage message) async {
    await downloadMessageResource(message);
    await ChatManager.instance.messageHandler.insertMessage(message);
    replaceMessage(message);
  }

  Future<void> downloadMessageResource(ChatMessage message) async {
    if (message is ChatTextMessage) {
      //文本转语音
      ChatTextMessage textMessage = message;

      message.audioStatus.value = ChatTextAudioStatus.loading;

      TTSResult result = await ChatVoiceManager.instance.textToVoice(
        textMessage,
      );
      if (result.success) {
        Map extra = result.toJson();
        Map newInfo = {...textMessage.decodedInfo, ...extra};
        textMessage.info = JsonEncoder().convert(newInfo);
      }

      message.audioStatus.value = ChatTextAudioStatus.ready;
    } else if (message is ChatAudioMessage) {
      ChatVoiceManager.instance.downloadSrc(message.audioUrl);
    }
  }

  Future unlockVideoMessageWithInit(ChatVideoMessage message) async {
    Toast.loading();
    ApiResponse rsp = await VideoCreateManager.requestGenerateVideo(msgId: message.id, sid: session.userId);
    if (rsp.isSuccess) {
      ResGenReporter.reportGen(message.id, 1);
      message.prepared = 0;
      ChatManager.instance.messageHandler.insertMessage(message);
      // update([message.refreshId]);
      replaceMessage(message);
      Toast.dismiss();
      AccountService.instance.refreshBalance();
    } else {
      Toast.show(rsp.description);
    }
  }

  Future unlockImageMessageWithInit(ChatImageMessage message) async {
    Toast.loading();
    ApiResponse rsp = await CreateImageManager.instance.createImage(session.userId, msgId: message.id);
    if (rsp.isSuccess) {
      ResGenReporter.reportGen(message.id, 0);
      message.prepared = 0;
      ChatManager.instance.messageHandler.insertMessage(message);
      // update([message.refreshId]);
      replaceMessage(message);
      Toast.dismiss();
      AccountService.instance.refreshBalance();
    } else {
      Toast.show(rsp.description);
    }
  }

  Future<bool> unlockMessage(ChatMessage message) async {
    L.i('unlockMessage: $message');

    if (message is ChatVideoMessage && message.isInit) {
      await unlockVideoMessageWithInit(message);
      return Future.value(true);
    } else if (message is ChatImageMessage && message.isInit) {
      await unlockImageMessageWithInit(message);
      return Future.value(true);
    }

    Toast.loading();
    ApiResponse response = await ChatManager.instance.unlockMessage(message);
    if (response.isSuccess) {
      ChatMessage newMessage = ChatMessage.fromServer(
        response.data[Security.security_msg],
      );
      await downloadMessageResource(newMessage);
      await ChatManager.instance.messageHandler.insertMessage(newMessage);

      // 更新权益信息
      MyAccount.setPremInfo(response.data[Security.security_ownPremiumInfo]);
      EventCenter.instance.sendEvent(kEventCenterRefreshCurrency, {});
      if (MyAccount.coins < 30) {
        AdsManager.getBalanceAdAward();
      }

      Toast.dismiss();
      replaceMessage(newMessage);
    } else {
      Toast.error(response.description);
      Future.delayed(const Duration(milliseconds: 1500), () {
        Toast.dismiss();
        if (response.bsnsCode == ApiError.notEnoughBalance.v ||
            response.bsnsCode == ApiError.notEnoughGems.v) {
          message.currencyType == 1
              ? RouteHelper.toGems()
              : RouteHelper.toPremium();
        }
      });
    }
    return Future.value(response.isSuccess);
  }

  void replaceMessage(ChatMessage message) {
    int index = messages.indexWhere((element) => element.id == message.id);
    if (index >= 0) {
      if (focusedMessage != null && focusedMessage!.id == message.id) {
        focusedMessage = message;
        message.focused.value = true;
      }
      messages[index] = message;
    }
  }

  void reloadMessage(ChatMessage message) async {
    Toast.loading();
    ApiResponse response = await ChatManager.instance.reloadMessage(message);
    if (response.isSuccess) {
      Toast.dismiss();
      ChatMessage newMessage = ChatMessage.fromServer(
        response.data[Security.security_msg],
      );
      await ChatManager.instance.messageHandler.insertMessage(newMessage);
      replaceMessage(newMessage);
    } else {
      Toast.error(response.description);
    }
  }

  void onTapMessage(ChatMessage message) {
    debugPrint('onTapMessage: $message');
    if (!message.isMine()) {
      if (session.isAiChat) {
        focusedMessage?.focused.value = false;
        focusedMessage = message;
        message.focused.value = true;
      }
    }
    if (message.isCall) {
      toCall((message as ChatCallMessage).callType);
    }
    unfocus();
  }

  void onAIContinue(ChatMessage message) async {
    bool ret = await ChatManager.instance.aiContinue(
      session.userId,
      group: session.isGroup,
      sessionId: message.sessionId,
      specifyRepliers: message.specifyRepliers,
      bannedRepliers: message.bannedRepliers,
    );
    if (ret) insertGeneratingMessage();
  }

  void generateVideo(ChatMessage message) {
    try {
      GenerateVideoDialog.show(
        prompt: (message as ChatImageMessage).imageDesc,
        imageUrl: message.imageUrl,
      );
    } catch (e) {
      L.e('generateVideo error: $e');
      return;
    }
  }

  void updateGroupInfoIfNeed({CrowdInfo? resultInfo}) async {
    CrowdInfo? wantInfo = resultInfo;

    /// 先读取缓存
    Map info = Preferences.instance.getMap('GroupInfo_${session.groupId}');
    if (resultInfo == null && info.isNotEmpty) {
      wantInfo = CrowdInfo(info[Security.security_info]);
      crowdInfo.value = wantInfo;
    }

    if (resultInfo == null) {
      ApiRequest request = ApiRequest(
        Apis.security_getGroupInfo,
        params: {Security.security_groupId: session.groupId},
      );
      ApiResponse response = await ApiService.instance.sendRequest(request);
      if (response.isSuccess) {
        Preferences.instance.setMap(
          'GroupInfo_${session.groupId}',
          response.data,
        );
        wantInfo = CrowdInfo(response.data[Security.security_info]);
      }
    }
    if (wantInfo != null) {
      crowdInfo.value = wantInfo;
      session.bio = crowdInfo.value.scenario;
      if (crowdInfo.value.name != session.name ||
          crowdInfo.value.avatar != session.avatar ||
          crowdInfo.value.chatBackground != session.backgroundUrl.value) {
        session.name = crowdInfo.value.name;
        session.avatar = session.avatar;
        update([Security.security_kTagChatRoomHeader]);
        ChatManager.instance.updateChatSession(session);
      }
    }
  }

  void updateInfoIfNeed() {
    if (session.isGroup) {
      updateGroupInfoIfNeed();
    } else {
      updateUserInfoIfNeed();
    }
    initUserProfileInfo();
  }

  void updateUserInfoIfNeed() async {
    UserProfileInfo? userInfo;
    try {
      userInfo = await UserManager.instance.getUserInfo(int.parse(session.id));
    } catch (e) {
      L.e('$kLogTag updateUserInfoIfNeed error: $e');
    }

    L.i('$kLogTag userInfo: ${userInfo.toString()}');

    if (userInfo == null) return;

    userProfileInfo = userInfo;
    session.name = userInfo.nickName;
    session.avatar = userInfo.avatarUrl;
    session.level.value = userInfo.level;
    int nextLevelRatio = (userInfo.nextLevelRatio * 100).toInt();
    session.nextLevelRatio.value = nextLevelRatio;

    bool sessionChanged = false;
    if (userInfo.nickName != session.name ||
        userInfo.level != session.level.value ||
        nextLevelRatio != session.nextLevelRatio.value ||
        userInfo.avatarUrl != session.avatar) {
      sessionChanged = true;
      update([Security.security_kTagChatRoomHeader]);
    }

    if (userInfo.chatBgUrl != session.backgroundUrl.value) {
      sessionChanged = true;
      session.backgroundUrl.value = userInfo.chatBgUrl;
      session.backgroundUrl.refresh();
    }

    if (sessionChanged) {
      ChatManager.instance.updateChatSession(session);
    }
    updateAnchorAlbumCard();
  }

  void updateAnchorAlbumCard() {
    if (!session.isRealChat || session.isOffChatSession) {
      return;
    }
    if (messages.isNotEmpty && messages.last is ChatAnchorAlbumMessage) {
      messages.removeLast();
    }
    ChatAnchorAlbumMessage cardMessage = ChatAnchorAlbumMessage.fromAnchorInfo(
      userProfileInfo.data,
    );
    messages.add(cardMessage);
  }

  void toPersonalPage() {
    RouteHelper.toPage(
      Routers.person,
      args: {Security.security_personInfo: userProfileInfo.data},
    );
  }

  Future<dynamic> toCrowInfoView() {
    return RouteHelper.toPage(Routers.crowedInfo, args: crowdInfo.value.data);
  }

  void clearHistory() {
    messages.clear();
    ChatSettingHelper.deleteRemoteSession(tUid: userId, sessionId: session.id);
    session.lastMessageText = '';
  }

  ChatMessage? showContinueMsg;

  void showContinueButtonIfNeed({ChatMessage? lastestMsg}) {
    if (!session.isAiChat) return;

    ChatMessage? newestMsg = lastestMsg ?? messages.firstOrNull;
    showContinueMsg?.showContinue.value = false;
    if (newestMsg == null || newestMsg.isMine() == true || newestMsg.isGroup) {
      showContinueMsg = null;
      return;
    }
    newestMsg.showContinue.value = true;
    showContinueMsg = newestMsg;
  }
}
