import 'package:biz/base/assets/image_view.dart';
import 'package:biz/base/crypt/routes.dart';
import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:biz/base/assets/image_path.dart';
import 'package:biz/base/crypt/copywriting.dart';
import 'package:biz/base/crypt/security.dart';
import 'package:biz/base/preferences/preferences.dart';
import 'package:biz/base/router/router_names.dart';
import 'package:biz/core/account/account_service.dart';
import 'package:biz/shared/alert.dart';
import 'package:biz/shared/app_theme.dart';
import 'package:uuid/uuid.dart';

import '../../../base/api_service/api_response.dart';
import '../../../base/report/report_manager.dart';
import '../../../core/util/cached_image.dart';
import '../chat_manager.dart';
import '../chat_room/chat_room_view.dart';
import './chat_cell.dart';
import 'chat_message.dart';

class ChatVideoMessage extends ChatMessage {
  ChatVideoMessage({
    required super.id,
    required super.senderId,
    required super.receiverId,
    required super.date,
    required super.ownerId,
    required super.senderName,
    required super.senderAvatar,
    required super.type,
    required super.uuid,
    required super.info,
    required super.lockInfo,
    required super.nativeId,
    required super.sessionType,
  });

  ChatVideoMessage.fromDatabase(Map<String, Object?> map) : super.fromLocalData(map) {
    // updateInfoIfNeed();
  }

  void updateInfoIfNeed() async {
    DateTime createdDate = date;
    int lastUpdateTime = Preferences.instance.getInt('kMsgLastUpdateTime_$uuid');
    int compareTime = lastUpdateTime > 0 ? lastUpdateTime : createdDate.millisecondsSinceEpoch;
    DateTime compareDate = DateTime.fromMillisecondsSinceEpoch(compareTime);

    if (!prepared && DateTime.now().difference(compareDate).inMinutes >= 2) {
      Preferences.instance.setInt('kMsgLastUpdateTime_$uuid', DateTime.now().millisecondsSinceEpoch);

      ApiResponse response = await ChatManager.instance.queryMsgWithUuid(uuid);
      if (!response.isSuccess) return;
      Map msg = response.data[Security.security_msg] ?? {};
      if (msg.isEmpty) return;
      ChatVideoMessage message = ChatVideoMessage.fromServer(msg);
      if (message.prepared) ChatManager.instance.onImagePrepared(msg);
    }
  }

  ChatVideoMessage.fromServer(Map map) : super.fromServerData(map) {}

  @override
  Map<String, dynamic> toServer() {
    return {...super.toServer(), Security.security_jsonBody: info, Security.security_id: id};
  }

  Map<String, dynamic>? _decodedMap;

  Map<String, dynamic> get decodedMap {
    try {
      _decodedMap ??= jsonDecode(info);
      return _decodedMap ?? {};
    } catch (e) {
      return {};
    }
  }

  String get coverUrl => decodedMap[Security.security_coverUrl] ?? '';

  String get videoUrl => decodedMap[Security.security_url] ?? '';

  bool get prepared => preparedValue == 1;

  int get preparedValue => decodedMap[Security.security_prepared] ?? 1;

  String get thumbnailBase64 {
    return decodedMap[Security.security_coverbase64] ?? '';
  }

  bool get unlocked => lockInfo[Security.security_unlock] == 1;

  set unlocked(bool value) {
    lockInfo[Security.security_unlock] = value ? 1 : 0;
  }

  int get unlockPrice => lockInfo[Security.security_cost] ?? 0;

  int get currencyType => lockInfo[Security.security_costType] ?? 0;

  bool get canReload => unlocked && renewInfo[Security.security_reload] == 1 && prepared;

  int get reloadPrice => renewInfo[Security.security_cost] ?? 0;

  int get reloadCurrencyType => renewInfo[Security.security_costType] ?? 0;

  String get externalText => '[VIDEO]';

  ChatVideoMessage.fromVideo(String url, String thumbnailUrl, int length, int receiverId, {super.specifyRepliers, super.bannedRepliers, super.session})
    : super(
        id: DateTime.now().microsecondsSinceEpoch,
        senderId: AccountService.instance.account.userId,
        receiverId: receiverId,
        date: DateTime.now(),
        ownerId: AccountService.instance.account.userId,
        senderName: AccountService.instance.account.name,
        senderAvatar: AccountService.instance.account.avatar,
        type: ChatMessageType.video,
        uuid: '',
        info: '',
        sessionType: session?.type ?? 0,
        lockInfo: {},
        nativeId: (const Uuid().v4()).replaceAll('-', ''),
      ) {
    Map body = {Security.security_url: url, Security.security_coverUrl: thumbnailUrl, Security.security_length: length};
    info = jsonEncode(body);
    sendState = ChatMessageSendStatus.sending.obs;
  }
}

class ChatVideoCell extends ChatCell {
  ChatVideoCell(super.message, {super.unlock, super.reload, super.onTap, super.onContinue, super.generateVideo}) {
    if (!isReal) videoMessage.updateInfoIfNeed();
  }

  ChatVideoMessage get videoMessage => message as ChatVideoMessage;

  ChatRoomViewController roomViewController = Get.find<ChatRoomViewController>();

  bool get isPremiumFreeReload => MyAccount.premiumFreeReloadVideoTimes > 0;

  bool get hasVideoConfig => roomViewController.hasVideoConfig;

  int get videoConfigCost => roomViewController.videoConfigCost ?? 0;

  bool get isReal => roomViewController.isRealChat;

  int? get videoConfigCostType => roomViewController.videoConfigCostType;

  bool get isGenerateVideoPremiumFree => roomViewController.askVideoConfig[Security.security_freeReason] == 3 && videoConfigCost == 0;

  bool get isGenerateVideoFree => roomViewController.askVideoConfig[Security.security_freeReason] != 3 && videoConfigCost == 0;

  bool get isGenerateVideoNotFree => videoConfigCost > 0;

  String get generateVideoCostIcon => videoConfigCostType == 0 ? "coin.png" : 'gem.png';

  String get refreshId => 'VEO_${videoMessage.uuid}';

  bool get isInChat => type == ChatCellType.chat;

  bool get prepared => videoMessage.prepared || isReal;

  bool get preparedButNotUnlock => prepared && !videoMessage.unlocked;

  bool get isLoading => (videoMessage.preparedValue == 0) && !isReal;

  bool get isInitialization => videoMessage.preparedValue == 2;

  Widget renderPlayButton(String videoUrl) {
    return GestureDetector(
      onTap: () {
        Get.toNamed(
          Routers.videoPlayer,
          arguments: {Security.security_videoUrl: videoUrl, Security.security_canDownload: videoMessage.currencyType == 0 ? 1 : 0},
        );
      },
      child: Center(
        child: Container(
          padding: EdgeInsets.all(8),
          decoration: BoxDecoration(color: Colors.black54, borderRadius: BorderRadius.circular(50)),
          child: const Icon(Icons.play_arrow_rounded, color: Colors.white, size: 32),
        ),
      ),
    );
  }

  Widget buildPageVideoViewItem(String coverUrl, String videoUrl, int prepared) {
    bool isLoading = prepared != 1;

    return GetBuilder<ChatRoomViewController>(
      builder: (controller) {
        //加载中
        if (isLoading) {
          return renderLoadingMask();
        }

        return buildMessageContent(coverUrl, videoUrl);
      },
    );
  }

  Widget buildVideoView() {
    return GetBuilder<ChatRoomViewController>(
      id: refreshId,
      builder: (controller) {
        //加载中
        if (isLoading) {
          return renderLoadingMask();
        }

        //生成好了但没解锁||未生成的要主动点击生成
        // if ((videoMessage.preparedButNotUnlock || videoMessage.isInitialization) && !isMine) {
        if (!videoMessage.unlocked && !isMine) {
          return Stack(
            alignment: Alignment.center,
            children: [ImageView("chat_img_placeholder.png", fit: BoxFit.cover, width: 172, height: 256), renderUnlockMaskIfNeeded()],
          );
        }

        return buildMessageContent(videoMessage.coverUrl, videoMessage.videoUrl);
      },
    );
  }

  Widget buildMessageContent(String coverUrl, String videoUrl) {
    return ClipRRect(
      borderRadius: BorderRadius.circular(12),
      child: Stack(
        fit: StackFit.expand,
        children: [
          SizedBox(
            width: 172,
            height: 256,
            child: CachedImage(
              imageUrl: coverUrl,
              fit: BoxFit.cover,
              placeholder: (BuildContext context, String url) {
                return renderLoadingMask();
              },
            )
          ),
          //生成一个播放按钮
          renderPlayButton(videoUrl),
        ],
      ),
    );
  }

  RxInt videoIndicator = 0.obs;

  Widget buildChatCell() {
    List videos = videoMessage.decodedMap[Security.security_res] ?? [];
    int length = videos.length;
    return Container(
      margin: const EdgeInsets.only(bottom: 8),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.end,
        children: [
          Row(
            mainAxisAlignment: isMine ? MainAxisAlignment.end : MainAxisAlignment.start,
            children: [
              SizedBox(
                width: 172,
                height: 256,
                child:
                    length <= 1
                        ? buildVideoView()
                        : Stack(
                          children: [
                            PageView(
                              onPageChanged: (index) {
                                videoIndicator.value = index;
                              },
                              children:
                                  videos.reversed
                                      .map(
                                        (e) => buildPageVideoViewItem(e[Security.security_coverUrl], e[Security.security_url], e[Security.security_prepared]),
                                      )
                                      .toList(),
                            ),
                            Positioned(
                              bottom: 2,
                              left: 0,
                              right: 0,
                              child: SizedBox(
                                height: 20,
                                child: Row(
                                  mainAxisAlignment: MainAxisAlignment.center,
                                  children: List.generate(length, (index) {
                                    return Obx(
                                      () => Container(
                                        width: 6.0,
                                        height: 6.0,
                                        margin: EdgeInsets.symmetric(horizontal: 2.0),
                                        decoration: BoxDecoration(
                                          shape: BoxShape.circle,
                                          color:
                                              videoIndicator.value == index
                                                  ? Colors
                                                      .white // 当前页用蓝色
                                                  : Colors.grey.withValues(alpha: 0.5), // 其他页用灰色
                                        ),
                                      ),
                                    );
                                  }),
                                ),
                              ),
                            ),
                          ],
                        ),
              ),
            ],
          ),
          renderReloadViewIfNeeded(),
        ],
      ),
    );
  }

  Widget buildVideoCell() {
    return AspectRatio(aspectRatio: 109 / 168, child: buildVideoView());
  }

  @override
  Widget buildView() {
    return type == ChatCellType.chat ? (isMine ? buildChatCell() : Row(children: [buildChatCell(), buildContinueView()])) : buildVideoCell();
  }

  static String kChatVideoUnlockPromptKey = Security.security_kHasVideoPrompted;

  bool get prompted => Preferences.instance.getString(kChatVideoUnlockPromptKey) != null;

  bool get isMine => message.isMine();

  set prompted(bool value) {
    if (value) {
      Preferences.instance.setString(kChatVideoUnlockPromptKey, '$kChatVideoUnlockPromptKey:1');
    } else {
      Preferences.instance.remove(kChatVideoUnlockPromptKey);
    }
  }

  void showUnlockDialogIfNeeded() {
    bool needAlert = videoMessage.unlockPrice > 0 && !prompted && isGenerateVideoNotFree;
    if (needAlert && videoMessage.currencyType == 0) {
      needAlert = !MyAccount.isSuperPrem && !MyAccount.hasFreeVdoForAI;
    }
    if (needAlert) {
      showUnlockDialog();
    } else {
      unLockOrGenerateVideo();
    }
  }

  void unLockOrGenerateVideo() {
    //如果未生成
    if (isInitialization) {
      generateVideo?.call(videoMessage);
    } else {
      unlock?.call(videoMessage);
    }
  }

  void showUnlockDialog() {
    showConfirmAlert(
      Copywriting.security_unlock_Video,
      'Unlocking will cost ${videoMessage.unlockPrice} ${videoMessage.currencyType == 1 ? 'Gems' : 'Coins'}',
      onConfirm: () {
        prompted = true;
        unLockOrGenerateVideo();
      },
    );
  }

  bool get showFreeImage => !isReal && videoMessage.currencyType == 0 && MyAccount.hasFreeVdoForAI;

  Widget renderReloadViewIfNeeded() {
    //使Container根据自身内容自适应宽度
    if (!videoMessage.canReload) return SizedBox.shrink();
    String text =
        (videoMessage.reloadPrice == 0 || isPremiumFreeReload)
            ? Security.security_Free
            : '${videoMessage.reloadPrice} ${videoMessage.reloadCurrencyType == 1 ? 'Gems' : 'Coins'}';

    return Row(
      children: [
        GestureDetector(
          onTap: () {
            ReportManager.sendEvent(Security.security_video_reload_click, {
              Security.security_userId: "${roomViewController.userId}",
              Security.security_msgId: "${videoMessage.id}",
            });
            super.reload?.call(videoMessage);
          },
          child: Container(
            height: 20,
            margin: EdgeInsets.only(top: 8),
            padding: EdgeInsets.symmetric(horizontal: 8),
            alignment: Alignment.centerLeft,
            decoration: BoxDecoration(borderRadius: BorderRadius.all(Radius.circular(10)), color: Color(0x33000000)),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              mainAxisAlignment: MainAxisAlignment.start,
              children: [
                ImageView("refresh.png", width: 12, height: 12),
                SizedBox(width: 4),
                if (isPremiumFreeReload && videoMessage.reloadPrice != 0) ImageView("premium.png", width: 16, height: 16),
                SizedBox(width: 4),
                Text(text, style: TextStyle(color: Colors.white, fontSize: 12, fontWeight: AppFonts.medium)),
              ],
            ),
          ),
        ),
      ],
    );
  }

  // Widget renderImageMask() {
  //   return Stack(
  //     fit: StackFit.expand,
  //     children: [
  //       videoMessage.thumbnailBase64.isNotEmpty
  //           ? Image.memory(base64Decode(videoMessage.thumbnailBase64), fit: BoxFit.cover)
  //           : CachedImage(imageUrl: videoMessage.coverUrl, fit: BoxFit.cover),
  //       BackdropFilter(
  //         filter: ImageFilter.blur(sigmaX: 16.0, sigmaY: 16.0),
  //         //显示imageMessage的thumbnailBase64
  //         child: Container(color: Colors.transparent),
  //       ),
  //       if (videoMessage.unlocked && videoMessage.isInitialization) renderUnlockMaskIfNeeded(),
  //     ],
  //   );
  // }

  Widget renderUnlockMaskIfNeeded() {
    return Container(
      padding: EdgeInsets.only(top: type == ChatCellType.chat ? 32 : 20, bottom: type == ChatCellType.chat ? 20 : 10),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          // Obx(() =>
          Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              ImageView("btn_video.png", width: 36, height: 36),
              SizedBox(height: 8),

              //解锁
              if (preparedButNotUnlock && !showFreeImage)
                Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    ImageView(videoMessage.currencyType == 1 ? "gem.png" : "coin.png", width: 24, height: 24),
                    SizedBox(width: 4),
                    Text('${videoMessage.unlockPrice}', style: TextStyle(color: Colors.white, fontWeight: AppFonts.black, fontSize: 16)),
                  ],
                ),

              //视频生成
              if (!preparedButNotUnlock)
                hasVideoConfig
                    ? Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        if (isGenerateVideoNotFree)
                          Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              ImageView(generateVideoCostIcon, width: 24, height: 24),
                              SizedBox(width: 4),
                              Text('$videoConfigCost', style: TextStyle(color: Colors.white, fontWeight: AppFonts.black, fontSize: 16)),
                            ],
                          ),

                        if (isGenerateVideoFree || isGenerateVideoPremiumFree)
                          Text(Security.security_Free, style: TextStyle(color: Colors.white, fontWeight: AppFonts.black, fontSize: 16)),
                      ],
                    )
                    : SizedBox(height: 20, width: 20, child: CircularProgressIndicator(strokeWidth: 2)),
            ],
          ),
          // ),
          // Obx(() =>
          preparedButNotUnlock ? renderUnlockButton() : renderGenerateButton(),
          // ),
        ],
      ),
    );
  }

  Widget renderUnlockButton() {
    Widget premiumBtn = Stack(
      children: [
        Container(
          width: double.infinity,
          height: double.infinity,
          decoration: BoxDecoration(borderRadius: BorderRadius.all(Radius.circular(8)), color: Color(0xFF110803).withValues(alpha: 0.4)),
          child: Row(
            spacing: 7,
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              ImageView("premium.png", width: 16, height: 16),
              Text(Copywriting.security_premium_Free, style: TextStyle(color: Color(0xFFFFE96F), fontSize: 12, fontWeight: AppFonts.medium)),
            ],
          ),
        ),
        if (MyAccount.isWkPrem)
          Positioned(
            right: 0,
            top: 0,
            child: Container(
              decoration: BoxDecoration(
                color: Color(0xFF000000).withValues(alpha: 0.11),
                borderRadius: BorderRadius.only(topRight: Radius.circular(8), bottomLeft: Radius.circular(8)),
              ),
              padding: EdgeInsets.symmetric(horizontal: 4),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.end,
                children: [
                  Padding(
                    padding: EdgeInsets.symmetric(horizontal: 4),
                    child: Obx(() {
                      int totalTimes = MyAccount.freeVdoUsedTimes + MyAccount.freeVdoLeftTimes;
                      return Text(
                        '${MyAccount.freeVdoUsedTimes}/$totalTimes',
                        style: TextStyle(color: Color(0xFFE9E7C3), fontSize: 9, fontWeight: FontWeight.w400),
                      );
                    }),
                  ),
                ],
              ),
            ),
          ),
      ],
    );
    Widget costUnlockBtn = Container(
      decoration: BoxDecoration(borderRadius: BorderRadius.all(Radius.circular(8)), color: AppColors.primary),
      alignment: Alignment.center,
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          ImageView("unlock.png", width: 16, height: 16),
          SizedBox(width: 4),
          Text(Security.security_Unlock, style: TextStyle(color: Colors.white, fontWeight: AppFonts.medium, fontSize: 14)),
        ],
      ),
    );

    return GestureDetector(
      onTap: showUnlockDialogIfNeeded,
      child: Column(
        children: [
          // if (videoMessage.currencyType == 0 && videoMessage.unlockPrice > 0 && !showFreeImage)
          //   Container(
          //     margin: EdgeInsets.only(bottom: 8),
          //     height: type == ChatCellType.chat ? 40 : 28,
          //     width: type == ChatCellType.chat ? 132 : 90,
          //     child: MediaAdsButton(
          //       videoMessage.uuid,
          //       1,
          //       grantAdCallback: (adAwardRsp) async {
          //         videoMessage.unlocked = true;
          //         Get.find<ChatRoomViewController>().update([refreshId]);
          //         ChatManager.instance.messageHandler.insertMessage(videoMessage);
          //       },
          //     ),
          //   ),
          SizedBox(height: type == ChatCellType.chat ? 40 : 28, width: type == ChatCellType.chat ? 132 : 90, child: showFreeImage ? premiumBtn : costUnlockBtn),
        ],
      ),
    );
  }

  Widget renderGenerateButton() {
    Widget freeBtn = Stack(
      children: [
        Container(
          width: double.infinity,
          height: double.infinity,
          decoration: BoxDecoration(borderRadius: BorderRadius.all(Radius.circular(8)), color: Color(0xFF110803).withValues(alpha: 0.4)),
          child: Row(
            spacing: 7,
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              if (isGenerateVideoPremiumFree) ImageView("premium.png", width: 16, height: 16),
              Text(
                isGenerateVideoPremiumFree ? Copywriting.security_premium_Free : Security.security_Free,
                style: TextStyle(color: Color(0xFFFFE96F), fontSize: 12, fontWeight: AppFonts.medium),
              ),
            ],
          ),
        ),
      ],
    );
    Widget costUnlockBtn = Container(
      decoration: BoxDecoration(borderRadius: BorderRadius.all(Radius.circular(8)), color: AppColors.primary),
      alignment: Alignment.center,
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          ImageView("unlock.png", width: 16, height: 16),
          SizedBox(width: 4),
          Text(Security.security_Unlock, style: TextStyle(color: Colors.white, fontWeight: AppFonts.medium, fontSize: 14)),
        ],
      ),
    );

    return hasVideoConfig
        ? GestureDetector(
          onTap: showUnlockDialogIfNeeded,
          child: SizedBox(
            height: type == ChatCellType.chat ? 40 : 28,
            width: type == ChatCellType.chat ? 132 : 90,
            child: (!isGenerateVideoNotFree) ? freeBtn : costUnlockBtn,
          ),
        )
        : SizedBox.shrink();
  }

  Widget renderLoadingMask() {
    return Stack(
      fit: StackFit.expand,
      children: [
        ImageView("chat_img_placeholder.png", fit: BoxFit.cover, width: 172, height: 256),
        Center(child: CircularProgressIndicator(color: AppColors.primary, strokeWidth: 2)),
      ],
    );
  }
}
