import 'package:biz/base/crypt/copywriting.dart';
import 'dart:async';
import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:get/get.dart';
import 'package:biz/base/crypt/security.dart';
import 'package:biz/base/event_center/event_center.dart';
import 'package:biz/base/privacy/ai_consent_service.dart';
import 'package:biz/base/router/route_helper.dart';
import 'package:biz/business/chat/chat_manager.dart';
import 'package:biz/business/chat/chat_session.dart';
import 'package:biz/business/chat/chat_room_cells/chat_message.dart';
import 'package:biz/business/chat/chat_room_cells/chat_text_cell.dart';
import 'package:biz/core/util/cached_image.dart';
import 'package:biz/core/account/account_service.dart';
import 'package:biz/business/chat/chat_room/chat_private_bottom_bar.dart';
import 'package:biz/business/chat/chat_room/chat_introduction_card.dart';
import 'package:biz/business/chat/chat_room/chat_continue_button.dart';

class ChatPrivateRoomView extends StatelessWidget {
  const ChatPrivateRoomView({super.key});

  @override
  Widget build(BuildContext context) {
    final controller = Get.put(ChatPrivateRoomViewController(Get.arguments));

    return PopScope(
      onPopInvokedWithResult: (didPop, ret) {
        if (didPop) {
          ChatManager.instance.updateChatSession(controller.session);
        }
      },
      child: Scaffold(
        backgroundColor: const Color(0xFF07070A),
        resizeToAvoidBottomInset: true,
        body: Stack(
          fit: StackFit.expand,
          children: [
            // 背景图片
            _buildBackground(controller),
            // 深色遮罩
            Container(color: Colors.black.withOpacity(0.2)),
            // 主要内容
            SafeArea(
              child: Column(
                children: [
                  _buildTopBar(controller),
                  Expanded(
                    child: Padding(
                      padding: EdgeInsets.only(bottom: 60.w), // 为底部输入栏留出空间
                      child: _buildMessageList(controller),
                    ),
                  ),
                ],
              ),
            ),
            // 底部输入栏
            Positioned(
              left: 0,
              right: 0,
              bottom: 0,
              child: ChatPrivateBottomBar(onSendText: controller.sendText),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildBackground(ChatPrivateRoomViewController controller) {
    final bgUrl = controller.session.backgroundUrl.value;
    if (bgUrl.isEmpty) {
      return Container(color: const Color(0xFF07070A));
    }
    return Obx(
      () => CachedImage(
        imageUrl: controller.session.backgroundUrl.value,
        width: double.infinity,
        height: double.infinity,
        fit: BoxFit.cover,
      ),
    );
  }

  Widget _buildTopBar(ChatPrivateRoomViewController controller) {
    return Container(
      height: 44.w,
      padding: EdgeInsets.symmetric(horizontal: 16.w),
      child: Row(
        children: [
          // 返回按钮
          GestureDetector(
            onTap: () {
              ChatManager.instance.updateChatSession(controller.session);
              RouteHelper.back();
            },
            child: Icon(Icons.arrow_back_ios, color: Colors.white, size: 20.w),
          ),
          SizedBox(width: 12.w),
          // 头像
          ClipRRect(
            borderRadius: BorderRadius.circular(14.w),
            child: CachedImage(
              imageUrl: controller.session.avatar,
              width: 28.w,
              height: 28.w,
              fit: BoxFit.cover,
            ),
          ),
          SizedBox(width: 8.w),
          // 名称
          Text(
            controller.session.name,
            style: TextStyle(
              color: Colors.white,
              fontSize: 14.sp,
              fontWeight: FontWeight.bold,
              fontFamily: Copywriting.security_sF_Pro,
            ),
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
          ),
          SizedBox(width: 8.w),
          // Current:AI 徽章
          if (controller.session.isAiChat)
            Container(
              padding: EdgeInsets.symmetric(horizontal: 8.w, vertical: 4.w),
              decoration: BoxDecoration(
                color: Colors.black.withOpacity(0.4),
                borderRadius: BorderRadius.circular(7.r),
              ),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(
                    'Current:AI',
                    style: TextStyle(
                      color: const Color(0xFFFFF37C),
                      fontSize: 12.sp,
                      fontWeight: FontWeight.w500,
                      fontFamily: Copywriting.security_sF_Pro,
                    ),
                  ),
                  SizedBox(width: 4.w),
                  Icon(
                    Icons.swap_horiz,
                    color: const Color(0xFFFFF37C),
                    size: 14.w,
                  ),
                ],
              ),
            ),
          Spacer(),
          // 更多按钮
          GestureDetector(
            onTap: () {
              // TODO: 显示更多菜单
            },
            child: Icon(Icons.more_vert, color: Colors.white, size: 24.w),
          ),
        ],
      ),
    );
  }

  Widget _buildNotice() {
    return Container(
      margin: EdgeInsets.symmetric(horizontal: 50.w, vertical: 12.w),
      padding: EdgeInsets.symmetric(horizontal: 16.w, vertical: 8.w),
      decoration: BoxDecoration(
        color: Colors.black.withOpacity(0.2),
        borderRadius: BorderRadius.circular(22.w),
      ),
      child: Text(
        Copywriting
            .security_notice__AI_responses_are_fictional_and_for_entertainment_only,
        style: TextStyle(color: Colors.white, fontSize: 11.sp),
        textAlign: TextAlign.center,
      ),
    );
  }

  Widget _buildMessageList(ChatPrivateRoomViewController controller) {
    return Obx(() {
      final messageCount = controller.messages.length;
      return ListView.builder(
        reverse: true,
        padding: EdgeInsets.symmetric(horizontal: 16.w, vertical: 12.w),
        itemCount: messageCount + 2, // +1 for introduction card, +1 for notice
        itemBuilder: (context, index) {
          // 最后一项显示介绍卡片（因为列表是反向的，最后一项在顶部）
          if (index == messageCount + 1) {
            return ChatIntroductionCard(session: controller.session);
          }

          // 倒数第二项显示 Notice
          if (index == messageCount) {
            return _buildNotice();
          }

          final message = controller.messages[index];
          return _buildMessageCell(message, controller);
        },
      );
    });
  }

  Widget _buildMessageCell(
    ChatMessage message,
    ChatPrivateRoomViewController controller,
  ) {
    if (message is ChatTextMessage) {
      return Column(
        children: [
          Container(
            margin: EdgeInsets.only(bottom: 12.w),
            child: ChatTextCell(
              message,
              onTap: (msg) {
                // TODO: 长按消息菜单
              },
            ),
          ),
          // 如果是AI消息且显示继续按钮
          if (!message.isMine())
            Obx(
              () =>
                  message.showContinue.value
                      ? ChatContinueButton(
                        onTap: () => controller.onContinue(message),
                      )
                      : const SizedBox.shrink(),
            ),
        ],
      );
    }

    // 其他消息类型
    return Container(
      margin: EdgeInsets.only(bottom: 12.w),
      child: Text(
        Copywriting.security_unsupported_message_type,
        style: TextStyle(color: Colors.white.withOpacity(0.5)),
      ),
    );
  }
}

class ChatPrivateRoomViewController extends GetxController {
  final Map<String, dynamic> arguments;
  late final ChatSession session;
  final RxList messages = [].obs;

  Function(Event)? _messageListener;

  ChatPrivateRoomViewController(this.arguments);

  @override
  void onInit() {
    super.onInit();
    session = _createSession(arguments);
    if (session.isAiChat) {
      AIConsentService.promptForEntryIfNeeded(feature: AIConsentFeature.chat);
    }
    _loadMessages();
    _listenToMessages();
  }

  @override
  void onClose() {
    if (_messageListener != null) {
      EventCenter.instance.removeListener(
        kEventCenterDidReceivedNewMessages,
        _messageListener!,
      );
    }
    ChatManager.instance.updateChatSession(session);
    super.onClose();
  }

  ChatSession _createSession(Map<String, dynamic> arguments) {
    String sessionJson = arguments[Security.security_session];
    Map<String, dynamic> sessionMap = jsonDecode(sessionJson);

    ChatSession chatSession = ChatSession.fromRouter(sessionMap);

    // 确保是私聊类型
    if (sessionMap[Security.security_type] == 3) {
      chatSession.type = 3;
      chatSession.sessionId = chatSession.id;
    }

    return chatSession;
  }

  Future<void> _loadMessages() async {
    try {
      final loadedMessages = await ChatManager.instance.messageHandler
          .queryMessages(session.sessionId);
      messages.assignAll(loadedMessages.reversed);

      // 设置最后一条AI消息显示继续按钮
      if (messages.isNotEmpty) {
        for (var msg in messages) {
          msg.showContinue.value = false;
        }
        final lastMessage = messages.first;
        if (!lastMessage.isMine()) {
          lastMessage.showContinue.value = true;
        }
      }
    } catch (e) {
      print('Load messages error: $e');
    }
  }

  void _listenToMessages() {
    _messageListener = (event) {
      if (event.data is Map<String, dynamic>) {
        final sessionId = event.data[Security.security_sessionId];
        if (sessionId == session.sessionId) {
          _loadMessages();
        }
      }
    };
    EventCenter.instance.addListener(
      kEventCenterDidReceivedNewMessages,
      _messageListener!,
    );
  }

  void onContinue(ChatMessage message) {
    // TODO: 实现继续生成功能
    print('Continue from message: ${message.id}');
  }

  Future<void> sendText(String text) async {
    if (text.trim().isEmpty) return;
    final agreed = await AIConsentService.ensureConsent(
      feature: AIConsentFeature.chat,
    );
    if (!agreed) return;

    try {
      // 创建文本消息
      final message = ChatTextMessage.fromText(
        text,
        AccountService.instance.account.userId,
        session: session,
      );

      // 先插入到数据库
      int result = await ChatManager.instance.messageHandler.insertMessage(
        message,
      );
      if (result <= 0) return;

      // 更新消息列表
      messages.insert(0, message);

      // 更新会话
      session.lastMessageText = message.externalText;
      session.lastMessageTime = DateTime.now();
      ChatManager.instance.updateChatSession(session);

      // 发送消息
      await ChatManager.instance.sendMessage(message);

      // 重新加载消息列表
      _loadMessages();
    } catch (e) {
      print('Send message error: $e');
    }
  }
}
