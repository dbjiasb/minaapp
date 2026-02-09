import 'dart:async';
import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:biz/base/api_service/api_response.dart';
import 'package:biz/base/assets/image_path.dart';
import 'package:biz/base/crypt/security.dart';
import 'package:biz/base/event_center/event_center.dart';
import 'package:biz/base/router/router_names.dart';
import 'package:biz/business/chat/chat_room_cells/chat_message.dart';
import 'package:biz/business/chat/chat_room_cells/chat_tip_message.dart';
import 'package:biz/business/chat/setting/chat_setting_helper.dart';
import 'package:biz/core/account/account_service.dart';
import 'package:biz/core/user_manager/user_manager.dart';
import 'package:biz/core/util/string_ext.dart';

// import '../../../base/ads/ad_service.dart';
import '../../../base/api_service/api_request.dart';
import '../../../base/api_service/api_service.dart';
import '../../../base/crypt/apis.dart';
import '../../../base/push_service/push_service.dart';
import '../../../base/router/route_helper.dart';
import '../../../core/util/cached_image.dart';
import '../../../shared/toast/toast.dart';
import '../chat_manager.dart';
import '../chat_room_cells/chat_audio_message.dart';
// import '../chat_room_cells/chat_call_cell.dart';
import '../chat_room_cells/chat_cell.dart';
import '../chat_room_cells/chat_generating_message.dart';
import '../chat_room_cells/chat_system_message.dart';
import '../chat_room_cells/chat_text_cell.dart';
import '../chat_room_cells/chat_theater_brief_message.dart';
import '../chat_room_cells/chat_time_message.dart';
import '../chat_session.dart';
import '../chat_voice_manager.dart';
import '../chat_voice_player.dart';
// import 'level_up_pop_up.dart';
import 'package:biz/business/chat/chat_room/chat_theater_bottom_bar.dart';
import 'package:biz/core/util/collections_util.dart';


class ChatTheaterRoomView extends StatelessWidget {
  final GlobalKey<ScaffoldState> _scaffoldKey = GlobalKey();

  ChatRoomViewController viewController = Get.put(ChatRoomViewController(Get.arguments));
  ChatTheaterBottomBarController bottomBarController = Get.put(ChatTheaterBottomBarController());

  List get messages => viewController.messages;

  int get currentMessageInex => viewController.storyMessageIndex.value;

  ChatMessage get lastMessage => messages.safeGet(currentMessageInex, ChatMessage);

  bool get lastMessageIsGenerating => lastMessage.type == ChatMessageType.generating;

  ChatMessage get lastSecondMessage => messages.safeGet(currentMessageInex + 1, ChatMessage);

  ChatSession get session => viewController.session;

  void _onBackButtonClicked() {
    /// 退出界面保存一次
    ChatManager.instance.updateChatSession(session);
    RH.back();
  }

  Widget createTheaterMessage(message) => ChatCell.createTheaterMessage(message, resendMessage: viewController.resendMessage, unlock: viewController.unlockMessage);

  @override
  Widget build(BuildContext context) {
    return PopScope(
      onPopInvokedWithResult: (didPop, ret) {
        if (didPop) {
          ChatManager.instance.updateChatSession(session);
        }
      },
      child: Scaffold(
        key: _scaffoldKey,
        backgroundColor: Color(0xFF0A0B12),
        resizeToAvoidBottomInset: true,
        body: Stack(
          fit: StackFit.expand,
          children: [
            _buildBackgroundView(),
            Obx(
                  () =>
              bottomBarController.isHideView.value
                  ? SizedBox.shrink()
                  : Stack(
                children: [
                  Container(color: Colors.black.withAlpha((255 * 0.3).toInt())),
                  Positioned(
                    top: 0,
                    left: 0,
                    right: 0,
                    height: Get.statusBarHeight,
                    child: Container(
                      decoration: BoxDecoration(
                        gradient: LinearGradient(
                          colors: [Colors.black.withValues(alpha: 0.8), Colors.black.withValues(alpha: 0)],
                          begin: Alignment.topCenter,
                          end: Alignment.bottomCenter,
                        ),
                      ),
                    ),
                  ),
                  SafeArea(bottom: false, child: Column(children: [_buildNavigationBar(), _buildChatRoomView()])),
                ],
              ),
            ),
            Positioned(
              top: 0,
              right: 0,
              bottom: 0,
              left: 0,
              child: Obx(
                    () =>
                bottomBarController.isKeyboardVisible.value
                    ? GestureDetector(
                  behavior: HitTestBehavior.translucent,
                  onTap: () {
                    bottomBarController.focusNode.unfocus();
                  },
                )
                    : SizedBox.shrink(),
              ),
            ),
            Positioned(left: 0, right: 0, bottom: 0, child: ChatTheaterBottomBar(sendText: viewController.sendText)),
          ],
        ),
      ),
    );
  }


  Widget _buildNavigationBar() {
    return Container(
      height: 46,
      alignment: Alignment.center,
      padding: const EdgeInsets.only(left: 12),
      child: Row(
        children: [
          GestureDetector(
            onTap: _onBackButtonClicked,
            child: Container(width: 32, height: 32, alignment: Alignment.center, child: Image.asset(ImagePath.ic_arrow_left_circle, width: 32, height: 32)),
          ),
          SizedBox(width: 10),
          GetBuilder<ChatRoomViewController>(
            id: Security.security_kTagChatRoomHeader,
            builder: (_) {
              return Container(
                padding: EdgeInsets.only(left: 2, right: 12),
                height: 40,
                alignment: Alignment.center,
                decoration: BoxDecoration(color: Color(0xCC333333), borderRadius: BorderRadius.circular(20)),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    GestureDetector(
                      onTap: () async {
                        if (session.isGroup) {
                          // dynamic result = await viewController.toCrowInfoView();
                          // if (result is CrowdInfo) {
                          //   viewController.crowdInfo.value = result;
                          //   viewController.updateGroupInfoIfNeed();
                          // }
                        } else {
                          // viewController.toPersonalPage();
                        }
                      },
                      child: Container(
                        width: 36,
                        height: 36,
                        decoration: BoxDecoration(
                          border: Border.all(color: Colors.white, width: 1),
                          borderRadius: BorderRadius.circular(18),
                          image: DecorationImage(image: CachedImageProvider(viewController.session.avatar), fit: BoxFit.cover),
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
                          style: TextStyle(color: Colors.white, fontSize: 14, fontWeight: FontWeight.bold, overflow: TextOverflow.ellipsis),
                          maxLines: 1,
                        ),
                        Text("Theater", style: TextStyle(color: Color(0xFFFFE407), fontSize: 12)),
                      ],
                    ),
                  ],
                ),
              );
            },
          ),
          SizedBox(width: 5),
        ],
      ),
    );
  }

  Widget _buildReviewView() {
    return Expanded(
      child: Padding(
        padding: EdgeInsets.only(bottom: 100),
        child: ShaderMask(
          shaderCallback: (Rect rect) {
            return const LinearGradient(
              begin: Alignment.topCenter,
              end: Alignment.bottomCenter,
              colors: [Colors.white, Colors.transparent, Colors.transparent, Colors.white],
              stops: [0.0, 0.1, 1.0 - 0.1, 1.0], // 10% purple, 80% transparent, 10% purple
            ).createShader(rect);
          },
          blendMode: BlendMode.dstOut,
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 20),
            child:
                messages.isEmpty
                    ? null
                    : ListView.separated(
                      controller: viewController.messageListScrollController,
                      itemBuilder: (BuildContext context, int index) {
                        ChatMessage message = messages[index];
                        Widget cell = createTheaterMessage(message);
                        return cell;
                      },
                      itemCount: viewController.messages.length,
                      padding: EdgeInsets.zero,
                      reverse: true,
                      separatorBuilder: (BuildContext context, int index) {
                        return SizedBox(height: 6);
                      },
                    ),
          ),
        ),
      ),
    );
  }

  Widget _buildStoryView() {
    return Expanded(
      child: Container(
        padding: EdgeInsets.only(bottom: 100, left: 16, right: 16),
        child: Obx(
          () =>
              messages.isNotEmpty
                  ? Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [if (lastMessageIsGenerating) createTheaterMessage(lastSecondMessage), createTheaterMessage(lastMessage)],
                  )
                  : SizedBox.shrink(),
        ),
      ),
    );
  }

  Widget _buildChatRoomView() {
    return Obx(() => bottomBarController.isReview.value ? _buildReviewView() : _buildStoryView());
  }

  Widget _buildBackgroundView() {
    return Obx(() {
      String url = viewController.session.backgroundUrl.value;
      debugPrint('viewController.session.backgroundUrl.value: $url');
      return url.isNotEmpty ? CachedImage(imageUrl: url, fit: BoxFit.cover, errorWidget: (context, url, error) => SizedBox.shrink()) : SizedBox.shrink();
    });
  }
}


class ChatRoomViewController extends GetxController {
  final ScrollController messageListScrollController = ScrollController();

  final isShowAudioInputAnim = false.obs;

  Map<String, dynamic> arguments = Get.arguments;

  final ChatSession session;
  late UserProfileInfo userProfileInfo;

  int get userId => session.id.safeParse();

  var isKeyboardVisible = false.obs;

  RxList<ChatMessage> messages = RxList<ChatMessage>();

  RxInt storyMessageIndex = 0.obs;

  ChatMessage? focusedMessage;

  ChatGeneratingMessage? _generatingMessage;

  ChatGeneratingMessage get generatingMessage {
    _generatingMessage ??= ChatGeneratingMessage.placeholder(userId);
    return _generatingMessage!;
  }

  Timer? _generatingTimer;

  List waitingMessages = [];

  bool get isRealChat => session.accountType == 0;

  bool get isTheater => session.isTheater;

  bool get isAiChat => !isRealChat && !isTheater;

  ChatRoomViewController(Map<String, dynamic> arguments) : session = createSession(arguments);

  final String kChatImageViewGenerateVideo = Security.security_kChatImageViewGenerateVideo;
  final String kRequestGenerateVideoSuccess = Security.security_kRequestGenerateVideoSuccess;

  @override
  void onInit() async {
    super.onInit();
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
    List<ChatMessage> results = await ChatManager.instance.messageHandler.queryMessages(session.id);
    messages.addAll(results);
    insertAiTipsMessageIfNeeded();
    showContinueButtonIfNeed();

    EventCenter.instance.addListener(kEventCenterDidQueriedNewMessages, handlePullMessages);
    EventCenter.instance.addListener(kEventCenterDidReceivedNewMessages, handlePushMessages);
    EventCenter.instance.addListener(kEventCenterDidPreparedImageMessage, onImagePrepared);

    updateInfoIfNeed();

    getStoryBriefIfNeeded();
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

  messageListScrollToBottom() {
    if (messageListScrollController.hasClients) {
      messageListScrollController.jumpTo(0);
    }
  }

  onRequestGenerateVideoSuccess(Event event) {
    messageListScrollToBottom();
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
    ChatTipsMessage message = ChatTipsMessage.fromServer({Security.security_content: tips});
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
      if (lastTime == null || message.date.difference(lastTime) >= fiveMinutes) {
        // 插入 ChatTimeMessage
        ChatTimeMessage timeMessage = ChatTimeMessage(message.date);
        messages.insert(i + 1, timeMessage);
        lastTime = message.date;
      }
    }
  }

  static createSession(Map<String, dynamic> arguments) {
    if (arguments["isTheater"] == true) {
      return ChatSession.fromStory(arguments);
    }

    String sessionJson = arguments[Security.security_session];
    Map<String, dynamic> sessionMap = jsonDecode(sessionJson);

    ChatSession chatSession = ChatSession.fromRouter(sessionMap);
    return chatSession;
  }

  Future<void> refreshSession() async {
    ChatSession? localSection = await ChatManager.instance.sessionHandler.querySession(session.id);
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
      List<ChatMessage> newMessages = event.data[session.id];
      insertMessages(newMessages);
      showContinueButtonIfNeed(lastestMsg: newMessages.lastOrNull);
    }
  }

  handlePushMessages(Event event) async {
    if (event.data[session.id] != null) {
      List<ChatMessage> newMessages = event.data[session.id];
      insertMessages(newMessages);
      showContinueButtonIfNeed(lastestMsg: newMessages.lastOrNull);
    }
  }

  void insertTheaterMessage(List<ChatMessage> newest) {
    removeGeneratingMessage(); //移除生成中的消息
    messages.insertAll(0, newest);
    if (storyMessageIndex.value == 0) {
      storyMessageIndex.value = newest.length - 1;
    }
  }

  void insertMessages(List<ChatMessage> newest) {
    if (newest.isEmpty) return;

    if (isTheater) {
      insertTheaterMessage(newest);
      return;
    }

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
    _generatingTimer = Timer.periodic(const Duration(milliseconds: 1000), (timer) {
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
    EventCenter.instance.removeListener(kEventCenterDidQueriedNewMessages, handlePullMessages);
    EventCenter.instance.removeListener(kEventCenterDidReceivedNewMessages, handlePushMessages);
    EventCenter.instance.removeListener(kEventCenterDidPreparedImageMessage, onImagePrepared);
    EventCenter.instance.removeListener(kRequestGenerateVideoSuccess, onRequestGenerateVideoSuccess);
    ChatManager.instance.currentSession = null;
    ChatVoicePlayer.instance.dealloc();
    super.onClose();
  }

  @override
  void dispose() {
    debugPrint('dispose');
    super.dispose();
  }

  void unfocus() {
    // ChatBottomBarController barController = Get.find<ChatBottomBarController>();
    // barController.unfocus();
  }

  void sendText(String text, {List<int>? specifyRepliers, List<int>? bannedRepliers}) async {
    if (text.isEmpty) {
      return;
    }

    ChatMessage message = ChatTextMessage.fromText(text, userId, specifyRepliers: specifyRepliers, bannedRepliers: bannedRepliers, session: session);
    if (session.isScriptChat || session.isTheater) message.chatStatus = 2;
    sendMessage(message);
  }

  void sendMessage(ChatMessage message) async {
    //先插入到数据库
    int result = await ChatManager.instance.messageHandler.insertMessage(message);
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
    SendMessageResponse response = await ChatManager.instance.sendMessage(message);
    if (response.isSuccess) {
      //用服务器返回的message替换掉自己发出去的message
      int index = messages.indexWhere((element) => element.nativeId == message.nativeId);
      if (index >= 0) {
        messages[index] = response.message;
        if (isAiChat || isTheater) {
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

      TTSResult result = await ChatVoiceManager.instance.textToVoice(textMessage);
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

  Future<bool> unlockMessage(ChatMessage message) async {
    debugPrint('unlockMessage: $message');
    Toast.loading();
    ApiResponse response = await ChatManager.instance.unlockMessage(message);
    if (response.isSuccess) {
      ChatMessage newMessage = ChatMessage.fromServer(response.data[Security.security_msg]);
      await downloadMessageResource(newMessage);
      await ChatManager.instance.messageHandler.insertMessage(newMessage);

      // 更新权益信息
      MyAccount.setPremInfo(response.data[Security.security_ownPremiumInfo]);
      EventCenter.instance.sendEvent(kEventCenterRefreshCurrency, {});

      Toast.dismiss();
      replaceMessage(newMessage);
    } else {
      if (response.bsnsCode == ApiError.notEnoughBalance.v || response.bsnsCode == ApiError.notEnoughGems.v) {
        message.currencyType == 1 ? RouteHelper.toGems() : RouteHelper.toPremium();
      }
      Toast.error(response.description);
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
      ChatMessage newMessage = ChatMessage.fromServer(response.data[Security.security_msg]);
      // 更新权益信息
      MyAccount.setPremInfo(response.data[Security.security_ownPremiumInfo]);
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
    unfocus();
  }

  void updateInfoIfNeed() {
    initUserProfileInfo();
  }

  void toPersonalPage() {
    RouteHelper.toPage(Routers.person, args: {Security.security_personInfo: userProfileInfo.data});
  }

  void clearHistory() {
    messages.clear();
    ChatSettingHelper.deleteRemoteSession(tUid: userId, sessionId: session.id);
    session.lastMessageText = '';
  }

  ChatMessage? showContinueMsg;

  void showContinueButtonIfNeed({ChatMessage? lastestMsg}) {
    if (!session.isAiChat) return;


    ChatMessage? newestMsg = lastestMsg ?? messages.firstOrNull();
    showContinueMsg?.showContinue.value = false;
    if (newestMsg == null || newestMsg.isMine() == true || newestMsg.isGroup) {
      showContinueMsg = null;
      return;
    }
    newestMsg.showContinue.value = true;
    showContinueMsg = newestMsg;
  }

  void getStoryBriefIfNeeded() async {
    if (!session.isTheater) return;
    var lastMessage = messages.lastOrNull;

    if (lastMessage is ChatTheaterBriefMessage) return;

    Map params = {"sessionId": session.sessionId, "userId": MyAccount.userId};
    ApiResponse rsp = await ApiService.instance.sendRequest(ApiRequest("getSceneMergedInfo", params: params));
    String brief = rsp.data[Security.security_info]?["storyBackground"] ?? "";

    if (brief.isEmpty) return;

    ChatTheaterBriefMessage message = ChatTheaterBriefMessage(brief);
    messages.add(message);
  }
}
