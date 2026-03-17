import 'package:biz/base/crypt/routes.dart';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:get/get.dart';
import 'package:biz/base/assets/image_path.dart';
import 'package:biz/base/crypt/apis.dart';
import 'package:biz/base/crypt/copywriting.dart';
import 'package:biz/base/crypt/security.dart';
import 'package:biz/business/chat/chat_room_cells/chat_message.dart';
import 'package:biz/business/chat/chat_room_cells/chat_text_cell.dart';
import 'package:biz/business/chat/chat_room_cells/chat_tip_message.dart';
import 'package:biz/shared/toast/toast.dart';

import '../../../base/api_service/api_request.dart';
import '../../../base/api_service/api_response.dart';
import '../../../base/api_service/api_service.dart';
import '../../../base/assets/image_view.dart';
import '../../../base/ui/overlay_popup.dart';
import '../chat_manager.dart';
import '../chat_room/chat_room_view.dart';

class MessageOptionView extends StatelessWidget {
  final ChatMessage message;

  final ChatRoomViewController controller;

  final List<MsgOptionItem> optionItemList;

  final Function() dismiss;

  RxInt likeStatus = 0.obs;

  MessageOptionView(this.message, this.controller, this.dismiss, {super.key})
    : optionItemList = _createOptionList(message, controller.isAiChat),
      likeStatus = message.like.obs;

  @override
  Widget build(BuildContext context) {
    int count = optionItemList.length;
    int crossAxisCount = count > 4 ? 4 : count;
    return Container(
      width: 48 * crossAxisCount + 12 * (crossAxisCount - 1) + 40,
      decoration: const BoxDecoration(color: Color(0xe6000000), borderRadius: BorderRadius.all(Radius.circular(12))),
      child: GridView.count(
        shrinkWrap: true,
        padding: EdgeInsets.symmetric(horizontal: 20, vertical: 10),
        crossAxisCount: crossAxisCount,
        mainAxisSpacing: 12,
        crossAxisSpacing: 12,
        childAspectRatio: 48 / 52,
        children: optionItemList.map((e) => _buildOptionItem(e)).toList(),
      ),
    );
  }

  static List<MsgOptionItem> _createOptionList(ChatMessage message, bool isAi) {
    List<MsgOptionItem> optionList = [MsgOptionItem("ic_chat_msg_delete.png", Copywriting.security_delete_Message)];
    if (message.type == ChatMessageType.text || message.type == ChatMessageType.tip) {
      optionList.add(MsgOptionItem("ic_chat_msg_copy.png", Security.security_copy));
      if (message.type == ChatMessageType.text) {
        if ((message as ChatTextMessage).translationText.value.isEmpty) {
          optionList.add(MsgOptionItem("ic_chat_msg_translate.webp", Security.security_translate));
        } else {
          optionList.add(MsgOptionItem("ic_chat_msg_hide_translate.webp", 'Hide\nTranslate'));
        }
      }
    }
    if (message.type == ChatMessageType.text && !message.isMine() && isAi) {
      optionList.add(MsgOptionItem("ic_chat_msg_reset.png", Copywriting.security_rewind_to_here));
      optionList.add(MsgOptionItem("ic_chat_msg_like.png", Security.security_like));
      optionList.add(MsgOptionItem("ic_chat_msg_unlike.png", Security.security_dislike));
    }
    if (isAi && (message.type == ChatMessageType.text || message.type == ChatMessageType.image) && !message.isMine()) {
      optionList.add(MsgOptionItem("ic_chat_msg_gen_video.png", Copywriting.security_generate_video));
    }

    return optionList;
  }

  Widget _buildOptionItem(MsgOptionItem optionItem) {
    String? replaceImage;
    if (optionItem.icon == "ic_chat_msg_like.png" && likeStatus.value == 1) {
      replaceImage = "ic_chat_msg_like_select.png";
    } else if (optionItem.icon == "ic_chat_msg_unlike.png" && likeStatus.value == 2) {
      replaceImage = "ic_chat_msg_unlike_select.png";
    }
    return SizedBox(
      width: 48,
      height: 52,
      child: GestureDetector(
        onTap: () async {
          doClickOption(optionItem);
        },
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.center,
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            ImageView(replaceImage ?? optionItem.icon, width: 24, height: 24),
            Text(optionItem.title, style: TextStyle(color: Colors.white, fontSize: 9), textAlign: TextAlign.center, maxLines: 2),
          ],
        ),
      ),
    );
  }

  void doClickOption(MsgOptionItem optionItem) async {
    switch (optionItem.icon) {
      case "ic_chat_msg_delete.png":
        await doDeleteOption();
        break;
      case "ic_chat_msg_copy.png":
        doCopyOption();
        break;
      case "ic_chat_msg_reset.png":
        await doResetMsgOption();
        break;
      case "ic_chat_msg_translate.webp":
        await doTranslateMsg();
        break;
      case "ic_chat_msg_hide_translate.webp":
        doHideTranslate();
        break;
      case "ic_chat_msg_like.png":
        doLikeMsg(1);
        break;
      case "ic_chat_msg_unlike.png":
        doLikeMsg(2);
        break;
      case "ic_chat_msg_gen_video.png":
        _doGenerateVideo();
        break;
    }
    dismiss();
  }

  _doGenerateVideo() {
    dismiss();
    controller.generateVideoByMessage(message);
  }

  void doLikeMsg(int status) {
    if (status == likeStatus.value) {
      return;
    }
    likeStatus.value = status;
    message.like = status;
    ChatManager.instance.messageHandler.updateLocalMessage(message);
  }

  Future doResetMsgOption() async {
    Toast.loading();
    ApiRequest request = ApiRequest(
      Apis.security_aiResetMsg,
      params: {Security.security_cidUid: controller.userId, Security.security_msgId: message.id, Security.security_sessionId: controller.session.id},
    );
    ApiResponse response = await ApiService.instance.sendRequest(request);
    if (response.isSuccess) {
      ChatManager.instance.messageHandler.deleteMessagesFromId(controller.session.id, message.id);
      controller.messages.removeWhere((element) => element.id > message.id);
      controller.messages.refresh();
      updateSessionMessage();
    }
    Toast.dismiss();
    dismiss();
  }

  void doCopyOption() {
    String text = "";
    if (message is ChatTextMessage) {
      text = (message as ChatTextMessage).text;
    } else if (message is ChatTipsMessage) {
      text = (message as ChatTipsMessage).text;
    }
    Clipboard.setData(ClipboardData(text: text));
    Toast.show(Security.security_copied);
  }

  Future doDeleteOption() async {
    Toast.loading();
    ApiRequest request = ApiRequest(
      Apis.security_batchDeleteUserMsg,
      params: {
        Security.security_toUid: controller.userId,
        Security.security_sessionId: controller.session.id,
        Security.security_chatStatus: controller.isAiChat ? 2 : 1,
        Security.security_msgId: [message.id],
      },
    );
    ApiResponse response = await ApiService.instance.sendRequest(request);
    if (response.isSuccess) {
      controller.messages.removeWhere((element) => element.id == message.id);
      updateSessionMessage();
      ChatManager.instance.messageHandler.deleteMessageById(message.id);
    }
    Toast.dismiss();
    dismiss();
  }

  void updateSessionMessage() {
    ChatMessage? lastMessage = controller.messages.firstOrNull;
    if (lastMessage != null) {
      controller.session.lastMessageText = lastMessage.externalText;
      controller.session.lastMessageTime = lastMessage.date;
      ChatManager.instance.updateChatSession(controller.session);
    }
  }

  Future doTranslateMsg() async {
    if (message is ChatTextMessage) {
      ChatTextMessage textMessage = message as ChatTextMessage;
      textMessage.translationText.value = 'Translating…';
      ApiRequest request = ApiRequest(Apis.security_choseLangTranslateText, params: {Security.security_text: textMessage.text});
      ApiResponse response = await ApiService.instance.sendRequest(request);
      if (response.isSuccess) {
        textMessage.translationText.value = response.data[Security.security_translatedText] ?? "";
      } else {
        textMessage.translationText.value = '';
        Toast.show(response.description);
      }
    }
  }

  void doHideTranslate() {
    if (message is ChatTextMessage) {
      ChatTextMessage textMessage = message as ChatTextMessage;
      textMessage.translationText.value = '';
    }
  }
}

class MsgOptionItem {
  String icon;
  String title;

  MsgOptionItem(this.icon, this.title);
}
