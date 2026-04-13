import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';

import 'package:biz/base/crypt/routes.dart';
import 'package:biz/base/router/router_names.dart';
import 'package:biz/core/account/account_service.dart';
import 'package:uuid/uuid.dart';

import '../../../base/crypt/security.dart';
import '../../../base/router/route_helper.dart';
import '../../../shared/app_theme.dart';
import '../../../shared/widget/avatar_view.dart';
// import '../../../shared/widget/video_file_view.dart';
import '../../../shared/widget/video_file_view.dart';
import './chat_cell.dart';
import 'chat_message.dart';

class ChatAnchorAlbumMessage extends ChatMessage {
  Map anchorInfo;

  ChatAnchorAlbumMessage({
    required super.id,
    required super.senderId,
    required super.receiverId,
    required super.date,
    required super.ownerId,
    required super.type,
    required super.uuid,
    required super.nativeId,
    required this.anchorInfo,
    required super.senderName,
    required super.senderAvatar,
    required super.sessionType, required super.lockInfo, required super.info,
  });

  ChatAnchorAlbumMessage.fromAnchorInfo(this.anchorInfo, {super.session})
    : super(
        id: 0,
        senderId: 0,
        receiverId: 0,
        date: DateTime.now(),
        ownerId: MyAccount.userId,
        type: ChatMessageType.anchorCard,
        uuid: '',
        nativeId: (const Uuid().v4()).replaceAll('-', ''),
        senderName: '',
        senderAvatar: '',
        sessionType: session?.type ?? 0,
      lockInfo: {},
      info: '{}'
      );
}

class ChatAnchorCardCell extends ChatCell {
  ChatAnchorCardCell(super.message);

  ChatAnchorAlbumMessage get cardMessage => super.message as ChatAnchorAlbumMessage;

  @override
  Widget build(BuildContext context) {
    if (cardMessage.anchorInfo[Security.security_resInfoList]?.isEmpty ?? true) {
      return Container();
    }
    return Container(
      margin: const EdgeInsets.only(bottom: 16),
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: Color(0xFF1B181F).withValues(alpha: 0.8),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        spacing: 8,
        children: [
          InkWell(
            onTap: () {
              if (Get.previousRoute == Routers.person) {
                Get.back();
                return;
              }
              RouteHelper.toPage(Routers.person, args: {Security.security_personInfo: cardMessage.anchorInfo});
            },
            child: Row(
              children: [
                AvatarView(url: cardMessage.anchorInfo[Security.security_userInfo]?[Security.security_baseInfo]?[Security.security_avatarUrl] ?? '', size: 48, strokeWidth: 1, strokeColor: Colors.white),
                const SizedBox(width: 8),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        cardMessage.anchorInfo[Security.security_userInfo]?[Security.security_baseInfo]?[Security.security_nickName] ?? '',
                        style: TextStyle(fontWeight: AppFonts.semiBold, color: Colors.white, fontSize: 14, height: 20 / 14),
                      ),
                      if (cardMessage.anchorInfo[Security.security_userInfo]?[Security.security_bio]?.isNotEmpty ?? false)
                        Text(
                          cardMessage.anchorInfo[Security.security_userInfo]?[Security.security_bio] ?? "",
                          style: TextStyle(fontWeight: AppFonts.medium, fontSize: 12, color: Color(0xFF9D9EA5), height: 16 / 12),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ).marginOnly(top: 4),
                    ],
                  ),
                ),
              ],
            ),
          ),
          SizedBox(
            height: 66,
            child: ListView.separated(
              scrollDirection: Axis.horizontal,
              itemBuilder: (context, index) => ClipRRect(
                borderRadius: BorderRadius.circular(8),
                child: GestureDetector(
                  onTap: () {
                    if (cardMessage.anchorInfo[Security.security_resInfoList]![index][Security.security_type] == 1) {
                      toViewer(cardMessage.anchorInfo[Security.security_resInfoList]![index][Security.security_url] ?? '');
                    } else {
                      Get.toNamed(Routers.videoPlayer, arguments: {Security.security_videoUrl: cardMessage.anchorInfo[Security.security_resInfoList]![index][Security.security_url] ?? ''});
                    }
                  },
                  child: cardMessage.anchorInfo[Security.security_resInfoList]![index][Security.security_type] == 1
                      ? CachedNetworkImage(imageUrl: cardMessage.anchorInfo[Security.security_resInfoList]![index][Security.security_url] ?? '', fit: BoxFit.cover, width: 66, height: 66)
                      : SizedBox(height: 66, width: 66, child: VideoFileView(url: cardMessage.anchorInfo[Security.security_resInfoList]![index][Security.security_url] ?? '')),
                ),
              ),
              itemCount: cardMessage.anchorInfo[Security.security_resInfoList]?.length ?? 0,
              separatorBuilder: (context, index) => SizedBox(width: 4),
            ),
          ),
        ],
      ),
    );
  }

  void toViewer(String url) {
    Map arguments = {
      Security.security_imageUrl: url,
      Security.security_canDownload: 0,
      Security.security_canGenerateVideo: false,
    };
    Get.toNamed(Routers.imageBrowser, arguments: arguments);

    // List<String>? list = cardMessage.anchorInfo[Security.security_resInfoList]?.where((e) => e.type == 1).map((e) => e.url ?? "").toList();
    // if (list != null) {
    //   Map arguments = {
    //     Security.security_imageUrl: url,
    //     Security.security_canDownload: 0,
    //     Security.security_canGenerateVideo: false,
    //   };
    //   Get.toNamed(Routers.imageBrowser, arguments: arguments);
    // }
  }
}
