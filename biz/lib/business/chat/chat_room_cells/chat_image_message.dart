import 'package:biz/base/crypt/images.dart';
import 'package:biz/base/crypt/routes.dart';
import 'dart:convert';
import 'dart:ui';

import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:biz/base/api_service/api_response.dart';
import 'package:biz/base/assets/image_path.dart';
import 'package:biz/base/crypt/copywriting.dart';
import 'package:biz/base/crypt/security.dart';
import 'package:biz/base/preferences/preferences.dart';
import 'package:biz/base/router/router_names.dart';
import 'package:biz/core/account/account_service.dart';
import 'package:biz/shared/alert.dart';
import 'package:biz/shared/app_theme.dart';
import 'package:uuid/uuid.dart';

import '../../../base/ads/ad_unlock_button.dart';
import '../../../base/assets/image_view.dart';
import '../../../core/util/cached_image.dart';
import '../chat_manager.dart';
import '../chat_room/chat_room_view.dart';
import '../chat_room_cells/chat_cell.dart';
import 'chat_message.dart';

class ChatImageMessage extends ChatMessage {
  ChatImageMessage({
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

  @override
  Map<String, dynamic> toServer() {
    return {...super.toServer(), Security.security_jsonBody: info, Security.security_id: id};
  }

  @override
  Map<String, Object?> toDatabase() {
    return {...super.toDatabase()};
  }

  ChatImageMessage.fromDatabase(Map<String, Object?> map) : super.fromLocalData(map) {
    // updateInfoIfNeed();
  }


  Future<void> updateInfoIfNeed() async {
    if (isPrepared) return;

    final String key = 'kMsgLastUpdateTime_$uuid';
    final int lastUpdateTime = Preferences.instance.getInt(key);
    final DateTime now = DateTime.now();

    if (lastUpdateTime > 0) {
      final lastTime = DateTime.fromMillisecondsSinceEpoch(lastUpdateTime);
      if (now.difference(lastTime).inMinutes < 2) {
        return;
      }
    }

    Preferences.instance.setInt(key, now.millisecondsSinceEpoch);
    ApiResponse response = await ChatManager.instance.queryMsgWithUuid(uuid);
    if (!response.isSuccess) return;
    Map msg = response.data[Security.security_msg] ?? {};
    if (msg.isEmpty) return;
    ChatImageMessage message = ChatImageMessage.fromServer(msg);
    if (message.isPrepared) {
      ChatManager.instance.onImagePrepared(msg);
    }
  }

  ChatImageMessage.fromServer(Map map) : super.fromServerData(map) {}

  ChatImageMessage.fromImage(String url, String? base64, int receiverId, {super.specifyRepliers, super.bannedRepliers, super.session})
    : super(
        id: DateTime.now().microsecondsSinceEpoch,
        senderId: AccountService.instance.account.userId,
        receiverId: receiverId,
        date: DateTime.now(),
        ownerId: AccountService.instance.account.userId,
        senderName: AccountService.instance.account.name,
        senderAvatar: AccountService.instance.account.avatar,
        type: ChatMessageType.image,
        uuid: '',
        info: '',
        sessionType: session?.type ?? 0,
        lockInfo: {},
        nativeId: (const Uuid().v4()).replaceAll('-', ''),
      ) {
    Map body = {Security.security_url: url, Security.security_base64: base64 ?? ''};
    info = jsonEncode(body);
    sendState = ChatMessageSendStatus.sending.obs;
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

  String get imageUrl => decodedMap[Security.security_url] ?? '';
  String get imageDesc => decodedMap[Security.security_desc] ?? '';

  bool get isLoading => prepared == 0;
  bool get isPrepared => prepared == 1 || (decodedMap[Security.security_prepared] == null && imageUrl.isNotEmpty);
  bool get isInit => prepared == 2;

  int get prepared => decodedMap[Security.security_prepared] ?? 0;
  set prepared(int value) {
    decodedMap[Security.security_prepared] = value;
    info = jsonEncode(decodedMap);
  }

  String get thumbnailBase64 {
    return decodedMap[Security.security_base64] ?? '';
  }

  bool get canReload => unlocked && renewInfo[Security.security_reload] == 1 && isPrepared;

  int get reloadPrice => renewInfo[Security.security_cost] ?? 0;

  int get reloadCurrencyType => renewInfo[Security.security_costType] ?? 0;

  String get externalText => '[IMAGE]';
}

class ChatImageCell extends ChatCell {
  ChatRoomViewController roomViewController = Get.find<ChatRoomViewController>();

  bool get isReal => roomViewController.isRealChat;

  String get refreshId => 'IMG_${imageMessage.uuid}';

  bool get supportGenerateVideo => !isReal && Preferences.instance.supportVeo(message.senderId.toString()) && !imageMessage.isMine();

  ChatImageCell(super.message, {super.key, super.resend, super.unlock, super.reload, super.onTap, super.onContinue, super.generateVideo}) {
    if (!isReal) imageMessage.updateInfoIfNeed();
  }

  ChatImageMessage get imageMessage => message as ChatImageMessage;

  Widget buildImagePageView(String url, int prepared) {
    bool isLoading = prepared == 0;

    Widget child = GetBuilder<ChatRoomViewController>(
      builder: (_) {
        if (isLoading) {
          return renderLoadingMask();
        } else {
          return GestureDetector(
            onTap: () {
              Map arguments = {Security.security_imageUrl: url, Security.security_canDownload: imageMessage.currencyType == 0 ? 1 : 0};
              arguments[Security.security_canGenerateVideo] = false; ///supportGenerateVideo;
              arguments[Security.security_imageDes] = imageMessage.decodedMap[Security.security_desc];
              Get.toNamed(Routers.imageBrowser, arguments: arguments);
            },
            child: CachedImage(
              imageUrl: url,
              placeholder: (context, url) => renderLoadingMask(),
              errorWidget: (context, url, error) => renderLoadingMask(),
              imageBuilder: (context, imageProvider) => Image(image: imageProvider, fit: BoxFit.cover),
              fit: BoxFit.cover,
            ),
          );
          ;
        }
      },
    );

    return ClipRRect(borderRadius: BorderRadius.circular(12), child: child);
  }

  Widget buildImageView() {
    Widget child = GetBuilder<ChatRoomViewController>(
      id: refreshId,
      builder: (_) {
        if (imageMessage.isLoading) {
          return renderLoadingMask();
        } else if (imageMessage.unlocked) {
          return GestureDetector(
            onTap: () {
              Map arguments = {Security.security_imageUrl: imageMessage.imageUrl, Security.security_canDownload: imageMessage.currencyType == 0 ? 1 : 0};
              arguments[Security.security_canGenerateVideo] = false;
              arguments[Security.security_imageDes] = imageMessage.decodedMap[Security.security_desc];
              Get.toNamed(Routers.imageBrowser, arguments: arguments);
            },
            child: CachedImage(
              imageUrl: imageMessage.imageUrl,
              placeholder: (context, url) => renderLoadingMask(),
              errorWidget: (context, url, error) => renderLoadingMask(),
              imageBuilder: (context, imageProvider) => Image(image: imageProvider, fit: BoxFit.cover),
              fit: BoxFit.cover,
            ),
          );
        } else {
          return renderImageMask(imageMessage.imageUrl);
        }
      },
    );

    return ClipRRect(borderRadius: BorderRadius.circular(12), child: child);
  }

  RxInt imageIndicator = 0.obs;

  Widget buildChatCell() {
    List<Map> messageReloadHistory = imageMessage.decodedMap[Security.security_res] != null ? (imageMessage.decodedMap[Security.security_res] as List).cast<Map>() : [];
    int length = messageReloadHistory.length;
    return Container(
      margin: const EdgeInsets.only(bottom: 8),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisSize: MainAxisSize.min,
        children: [
          Row(
            mainAxisAlignment: imageMessage.isMine() ? MainAxisAlignment.end : MainAxisAlignment.start,
            children: [
              SizedBox.fromSize(
                size: Size(172, 256),
                child:
                length <= 1
                        ? buildImageView()
                        : Stack(
                      children: [
                        PageView(
                          onPageChanged: (index) {
                            imageIndicator.value = index;
                          },
                          children:
                          messageReloadHistory.reversed.map((e) => buildImagePageView(e[Security.security_url], e[Security.security_prepared])).toList(),
                        ),
                        Positioned(
                          bottom: 2,
                          left: 0, right: 0,
                          child: SizedBox(
                            height: 20,
                            child: Row(
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: List.generate(length, (index) {
                                return Obx(()=>Container(
                                  width: 6.0,
                                  height: 6.0,
                                  margin: EdgeInsets.symmetric(horizontal: 2.0),
                                  decoration: BoxDecoration(
                                    shape: BoxShape.circle,
                                    color: imageIndicator.value == index
                                        ? Colors.white // 当前页用蓝色
                                        : Colors.grey.withValues(alpha: 0.5), // 其他页用灰色
                                  ),
                                ));
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

  Widget buildImageCell() {
    return AspectRatio(aspectRatio: 109 / 168, child: buildImageView());
  }

  @override
  Widget buildView() {
    return type == ChatCellType.category ? buildImageCell() : buildChatCell();
  }

  Widget renderReloadViewIfNeeded() {
    //使Container根据自身内容自适应宽度
    if (!imageMessage.canReload || type == ChatCellType.category) return SizedBox.shrink();
    String text =
        imageMessage.reloadPrice == 0 ? Security.security_Free : '${imageMessage.reloadPrice} ${imageMessage.reloadCurrencyType == 1 ? 'Gems' : 'Coins'}';

    return Row(
      mainAxisAlignment: MainAxisAlignment.start,
      children: [
        if (supportGenerateVideo)
          GestureDetector(
            onTap: () {
              super.generateVideo?.call(imageMessage);
            },
            child: Container(
              height: 22,
              margin: EdgeInsets.only(top: 8),
              padding: EdgeInsets.symmetric(horizontal: 8),
              alignment: Alignment.centerLeft,
              decoration: BoxDecoration(borderRadius: BorderRadius.all(Radius.circular(10)), color: Color(0x33000000)),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                mainAxisAlignment: MainAxisAlignment.start,
                children: [ImageView(Images.security_btn_video_png, width: 16, height: 16)],
              ),
            ),
          ).marginOnly(right: 4),
        GestureDetector(
          onTap: () {
            super.reload?.call(imageMessage);
          },
          child: Container(
            height: 22,
            margin: EdgeInsets.only(top: 8),
            padding: EdgeInsets.symmetric(horizontal: 8),
            alignment: Alignment.centerLeft,
            decoration: BoxDecoration(borderRadius: BorderRadius.all(Radius.circular(10)), color: Color(0x33000000)),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              mainAxisAlignment: MainAxisAlignment.start,
              children: [
                ImageView(Images.security_refresh_png, width: 12, height: 12),
                SizedBox(width: 4),
                Text(text, style: TextStyle(color: Colors.white, fontSize: 12, fontWeight: AppFonts.medium)),
              ],
            ),
          ),
        ),
      ],
    );
  }

  Widget renderImageMask(String imageUrl) {
    return Stack(
      fit: StackFit.expand,
      children: [
        ClipRRect(borderRadius: BorderRadius.circular(12),child: imageMessage.isPrepared ? CachedImage(imageUrl: imageUrl, fit: BoxFit.cover) : ImageView(Images.security_chat_img_placeholder_png, fit: BoxFit.cover),),
        BackdropFilter(
          filter: ImageFilter.blur(sigmaX: 16.0, sigmaY: 16.0),
          //显示imageMessage的thumbnailBase64
          child: Container(color: Colors.transparent),
        ),
        //如果图片已经准备好
        renderUnlockMaskIfNeeded(),
      ],
    );
  }

  static String kChatImageUnlockPromptKey = Security.security_kHasImagePrompted;

  bool get prompted => Preferences.instance.getString(kChatImageUnlockPromptKey) != null;

  set prompted(bool value) {
    if (value) {
      Preferences.instance.setString(kChatImageUnlockPromptKey, '$kChatImageUnlockPromptKey:1');
    } else {
      Preferences.instance.remove(kChatImageUnlockPromptKey);
    }
  }

  void showUnlockDialogIfNeeded() {
    bool needAlert = imageMessage.unlockPrice > 0 && !prompted;
    if (needAlert && imageMessage.currencyType == 0) {
      needAlert = !MyAccount.isSuperPrem && !MyAccount.hasFreeImgForAI;
    }
    if (needAlert) {
      showUnlockDialog();
    } else {
      unlock?.call(imageMessage);
    }
  }

  void showUnlockDialog() {
    showConfirmAlert(
      Copywriting.security_unlock_Image,
      Copywriting.unlockCost(imageMessage.unlockPrice, imageMessage.currencyType),
      onConfirm: () {
        prompted = true;
        unlock?.call(imageMessage);
      },
    );
  }

  bool get showFreeImage => imageMessage.currencyType == 0 && MyAccount.hasFreeImgForAI;

  Widget renderUnlockMaskIfNeeded() {
    return Container(
      padding: EdgeInsets.only(top: type == ChatCellType.chat ? 32 : 20, bottom: type == ChatCellType.chat ? 20 : 10),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              ImageView(Images.security_btn_pic_png, width: 36, height: 36),
              SizedBox(height: 8),
              if (!showFreeImage)
                Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    ImageView(imageMessage.currencyType == 1 ? Images.security_gem_png : Images.security_coin_png, width: 24, height: 24),
                    SizedBox(width: 4),
                    Text('${imageMessage.unlockPrice}', style: TextStyle(color: Colors.white, fontWeight: AppFonts.black, fontSize: 16)),
                  ],
                ),
            ],
          ),
          renderUnlockButton(),
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
              ImageView(Images.security_premium_png, width: 16, height: 16),
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
                    child: Obx(
                      () => Text(
                        '${MyAccount.freeImgUsedTimes}/${MyAccount.freeImgUsedTimes + MyAccount.freeImgLeftTimes}',
                        style: TextStyle(color: Color(0xFFE9E7C3), fontSize: 9, fontWeight: FontWeight.w400),
                      ),
                    ),
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
          ImageView(Images.security_unlock_png, width: 16, height: 16),
          SizedBox(width: 4),
          Text(Security.security_Unlock, style: TextStyle(color: Colors.black, fontWeight: AppFonts.medium, fontSize: 14)),
        ],
      ),
    );

    return GestureDetector(
      onTap: showUnlockDialogIfNeeded,
      child: Column(
        children: [
          if (imageMessage.currencyType == 0 && imageMessage.unlockPrice > 0 && !showFreeImage)
            Container(
              margin: EdgeInsets.only(bottom: 8),
              height: type == ChatCellType.chat ? 40 : 28,
              width: type == ChatCellType.chat ? 132 : 90,
              child: MediaAdsButton(
                imageMessage.uuid,
                0,
                grantAdCallback: (adAwardRsp) async {
                  imageMessage.unlocked = true;
                  Get.find<ChatRoomViewController>().update([refreshId]);
                  ChatManager.instance.messageHandler.insertMessage(imageMessage);
                },
              ),
            ),
          SizedBox(height: type == ChatCellType.chat ? 40 : 28, width: type == ChatCellType.chat ? 132 : 90, child: showFreeImage ? premiumBtn : costUnlockBtn),
        ],
      ),
    );
  }

  Widget renderLoadingMask() {
    return Stack(
      fit: StackFit.expand,
      children: [
        ImageView(Images.security_chat_img_placeholder_png, fit: BoxFit.cover, width: 172, height: 256),
        Center(child: CircularProgressIndicator(color: AppColors.primary, strokeWidth: 2)),
      ],
    );
  }
}
