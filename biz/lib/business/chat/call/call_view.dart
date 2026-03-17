import 'package:biz/base/crypt/routes.dart';
import 'dart:ui';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:biz/base/assets/image_path.dart';
import 'package:biz/business/chat/call/call_manager.dart';
import 'package:biz/business/chat/chat_room_cells/chat_text_cell.dart';
import 'package:biz/business/chat/gift/gift_panel.dart';
import 'package:biz/core/account/account_service.dart';
import 'package:biz/shared/widget/avatar_view.dart';
import '../../../base/assets/image_view.dart';
import '../../../base/crypt/copywriting.dart';
import '../../../base/crypt/security.dart';
import '../../../core/util/cached_image.dart';
import '../../../core/util/log_util.dart';
import '../chat_room_cells/chat_gift_cell.dart';
import '../chat_room_cells/chat_message.dart';
import 'av_engine.dart';
import 'call_info.dart';
import 'controller.dart';

const kFloatingWidth = 100.0;
const kFloatingHeight = 220.0;
const kFloatingPadding = 10.0;

class CallView extends GetView<CallController> {
  CallView({Key? key, int type = 0, bool callOut = true}) : super(key: key);

  OverlayEntry? overlayEntry;
  Rx<Offset> floatingOffset = const Offset(kFloatingPadding, kFloatingPadding + 140).obs;
  Widget? floatingView;

  @override
  CallController get controller => _controller!;
  CallController? _controller;
  Widget? get nativeView => controller.mineView.value.core;
  Widget? get otherView => controller.otherView.value.core;

  @override
  Widget build(BuildContext context) {
    Map args = Get.arguments;
    if (args[Security.security_isCallOut] ?? false) {
      _controller ??= CallController(
          otherUid: int.parse(args[Security.security_targetUid] ?? '0'),
          otherName: args[Security.security_targetName] ?? '',
          otherAvatar: args[Security.security_targetAvatar] ?? '',
          isCallOut: args[Security.security_isCallOut],
          type: StreamType.values[args[Security.security_type]],
          autoAnswer: args[Security.security_autoAnswer] ?? false
      );
    } else {
      VeoCall? call = CallManager.instance.curCall;
      _controller ??= CallController(
          otherUid: call?.from ?? 0,
          otherName: call?.name ?? '',
          otherAvatar: call?.avatar ?? '',
          isCallOut: args[Security.security_isCallOut] ?? false,
          type: StreamType.values[call?.type ?? 0],
          autoAnswer: args[Security.security_autoAnswer] ?? false
      );
    }
    Get.put(controller);

    return Scaffold(
      backgroundColor: Colors.black,
      extendBodyBehindAppBar: true,
      // appBar: _buildAppBar(),
      body: WillPopScope(
          onWillPop: () async {
            // controller.close();
            return false;
          },
          child: GestureDetector(
              onTap: () {
                FocusScope.of(context).unfocus();
              },
              child: Container(
                color: Colors.black,
                child: Stack(
                  children: [
                    controller.isVideo ? _drawFullVideoView() : _drawBg(),
                    Obx(() {
                      return (controller.callState == CallState.answered || controller.everConnected) ? _buildConnectedView() : _drawCallingView();
                    }),
                    if (controller.isVideo) _drawMiniCallWidget()
                  ],
                ),
              )
          )
      ),
    );
  }

  Widget _buildWaitingButtons() {
    Widget hangupBtn = IconButton(
      onPressed: () {
        controller.endCall();
      },
      icon: Container(
        decoration: const BoxDecoration(
          color: Color(0xFFF32D42),
          borderRadius: BorderRadius.all(Radius.circular(36)),
        ),
        padding: const EdgeInsets.all(16),
        child: const Icon(
          Icons.call_end,
          color: Colors.white,
          size: 32,
        ),
      ),
      iconSize: 64,
    );

    Widget acceptBtn = IconButton(
      onPressed: () {
        controller.accept();
      },
      icon: Container(
        decoration: const BoxDecoration(
          color: Color(0xFF14EB61),
          borderRadius: BorderRadius.all(Radius.circular(36)),
        ),
        padding: const EdgeInsets.all(16),
        child: Icon(
          Icons.call,
          color: Colors.white,
          size: 32,
        ),
      ),
      iconSize: 72,
    );
    Widget space = SizedBox(width: 36);

    return Obx(() {
      List<Widget> actions;
      switch (controller.callState) {
        case CallState.init:
          actions = controller.isCallOut ? [hangupBtn] : [hangupBtn, space, acceptBtn];
          break;
        default:
          actions = [];
          // actions = controller.isVideoCall ? [micBtn, space, cameraBtn, space, speakerBtn] : [micBtn, space, hangupBtn, space, speakerBtn];
          break;
      }

      Widget firstRow = Row(mainAxisAlignment: MainAxisAlignment.center, children: actions);

      return firstRow;
    });
  }

  ///未接通时view
  Widget _drawCallingView() {

    return Padding(
      padding: const EdgeInsets.only(top: 84, bottom: 100),
      child: Stack(
        alignment: Alignment.center,
        children: [
          Positioned(
            top: 0,
            left: 0,
            right: 0,
            child: Obx(() {

              int freeMins = controller.freeCallRemainTime.value;
              bool needCost = controller.needCost;

              return Column(
                children: [
                  Column(
                    children: [
                      Text(
                        (freeMins > 0 ? '${Copywriting.security_free_for_first}$freeMins minutes' : (needCost ? Copywriting.security_consuming_gems_during_call : Copywriting.security_free_Call)),
                        style: const TextStyle(color: Colors.white, fontSize: 16, fontWeight: FontWeight.bold),
                      ),
                      if (!controller.hasFreeTime && needCost)
                        Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Obx(() {
                              return Text(controller.costDescTitle.value, style: const TextStyle(color: Colors.white, fontSize: 13));
                            }),
                          ],
                        ).marginOnly(top: 8)
                    ],
                  ),
                  Obx(() {
                    return (controller.callState != CallState.answered)
                        ? Column(
                            children: [
                              AvatarView(url: controller.otherAvatar, size: 44),
                              const SizedBox(height: 16),
                              Text(controller.otherName, style: const TextStyle(color: Colors.white, fontSize: 14, fontWeight: FontWeight.bold)),
                            ],
                          ).marginOnly(top: 96)
                        : Container();
                  }),
                ],
              );
            }),
          ),
          Positioned(
            bottom: 0,
            left: 0,
            right: 0,
            child: Column(
              children: [
                Text(controller.curStatusDesc(), style: const TextStyle(color: Colors.white, fontSize: 14, fontWeight: FontWeight.w500)),
                SizedBox(height: 36),
                _buildWaitingButtons()
              ],
            ),
          )
        ],
      ),
    );
  }

  ///接通后view
  Widget _buildConnectedView() {
    return SafeArea(
      child: Column(
        children: [
          _drawTitleWidget(),
          _drawTalkWidget(),
          _drawBottomWidget(),
        ],
      ),
    );
  }

  Widget _drawTitleWidget() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Stack(
          alignment: Alignment.topCenter,
          children: [
            Container(
              width: double.infinity,
              height: 32,
            ),
            Positioned(
                left: 0,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    InkWell(
                      onTap: () async {
                        // BankRoute.toHalfGems();
                      },
                      child: Container(
                        padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 2),
                        decoration: BoxDecoration(
                          color: Colors.black26,
                          borderRadius: BorderRadius.circular(10),
                        ),
                        child: Row(
                          children: [
                            ImageView('gem.png', height: 16, width: 16),
                            SizedBox(width: 4),
                            Obx(() {
                              return Text('${MyAccount.gems}', style: const TextStyle(color: Colors.white, fontSize: 11, fontWeight: FontWeight.bold)).marginOnly(right: 2);
                            }),
                          ],
                        ),
                      ),
                    ),
                  ],
                )),
            Obx(() {
              return Text(controller.connectState.value == CallRoomConnectState.connected ? controller.curStatusDesc() : Copywriting.security_connecting___,
                  style: const TextStyle(color: Colors.white, fontSize: 14, fontWeight: FontWeight.bold));
            }),
            Positioned(
              right: 0,
              child: SizedBox(
                width: 32,
                height: 32,
                child: IconButton(
                  padding: EdgeInsets.zero,
                  onPressed: () {
                    controller.endCall();
                  },
                  icon: Container(
                    decoration: const BoxDecoration(
                      color: Color(0xFFF32D42),
                      borderRadius: BorderRadius.all(Radius.circular(36)),
                    ),
                    padding: const EdgeInsets.all(6),
                    child: const Icon(
                      Icons.call_end,
                      color: Colors.white,
                      size: 16,
                    ),
                  ),
                  iconSize: 32,
                ),
              ),
            )
          ],
        ),
        Obx(() {
          int freeTime = controller.freeCallRemainTime.value;
          String freeTimeTips = 'Free for first $freeTime minutes';
          String finalTips = controller.needCost ? (freeTime > 0 ? freeTimeTips : controller.costDescTitle.value) : Copywriting.security_free_Call;
          return Container(
              constraints: BoxConstraints(maxWidth: 150),
              child: Text(
                  finalTips,
                  style: const TextStyle(color: Colors.white, fontSize: 13, fontWeight: FontWeight.bold)));
        }),
      ],
    ).marginSymmetric(horizontal: 16, vertical: 4);
  }

  Widget _drawTalkWidget() {
    return Expanded(
      child: Stack(
        children: [
          if (!controller.isVideo)
            Positioned(
              top: 124,
              left: 0,
              right: 0,
              child: Column(
                children: [
                  AvatarView(url: controller.otherAvatar, size: 44),
                  const SizedBox(height: 16),
                  Text(controller.otherName, style: const TextStyle(color: Colors.white, fontSize: 14, fontWeight: FontWeight.bold)),
                ],
              ),
            ),
          Positioned(
            bottom: 0,
            left: 0,
            right: 0,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Container(
                  height: 168,
                  child: AnimatedList(
                    key: controller.listViewKey,
                    reverse: true,
                    initialItemCount: controller.messages.length,
                    itemBuilder: (BuildContext context, int index, Animation<double> animation) {
                      ChatMessage msgItem = controller.messages[index];
                      return SlideTransition(
                        position: Tween<Offset>(
                          begin: const Offset(0, 1),
                          end: const Offset(0, 0),
                        ).chain(CurveTween(curve: Curves.easeInOut)).animate(animation),
                        child: Align(
                          alignment: Alignment.centerLeft,
                          child: Row(
                            children: [
                              Container(
                                decoration: BoxDecoration(
                                  color: Colors.black.withValues(alpha: 0.3),
                                  borderRadius: const BorderRadius.all(Radius.circular(12)),
                                ),
                                constraints: BoxConstraints(maxWidth: 260),
                                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                                child: Text.rich(
                                  TextSpan(
                                    children: [
                                      TextSpan(
                                          text: '${msgItem.createSenderName(controller.otherName)}: ',
                                          style: TextStyle(color: msgItem.isMine() ? const Color(0xFF7FE4FF) : const Color(0xFFFDA7FF), fontSize: 12, fontWeight: FontWeight.w600)),
                                      if (msgItem.isText) TextSpan(text: (msgItem as ChatTextMessage).text, style: const TextStyle(color: Colors.white, fontSize: 12, fontWeight: FontWeight.w600)),
                                      if (msgItem.isGift)
                                        TextSpan(children: [
                                          TextSpan(
                                              text: 'Send a ${(msgItem as ChatGiftMessage).giftName} ', style: const TextStyle(color: Color(0xFFFFDD44), fontSize: 12, fontWeight: FontWeight.w600)),
                                          WidgetSpan(
                                            child: CachedImage(imageUrl: msgItem.imageUrl, width: 20, height: 20, fit: BoxFit.cover),
                                          ),
                                          TextSpan(text: ' x${msgItem.giftCount}', style: const TextStyle(color: Color(0xFFFFDD44), fontSize: 12, fontWeight: FontWeight.w600)),
                                        ])
                                    ],
                                  ),
                                ),
                              ),
                              SizedBox(width: 8,),
                              Obx(() {
                                switch (msgItem.sendState.value) {
                                  case ChatMessageSendStatus.sending:
                                    return const SizedBox(
                                        width: 12,
                                        height: 12,
                                        child: CircularProgressIndicator(
                                          color: Colors.white,
                                          strokeWidth: 2,
                                          valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
                                        ));
                                  case ChatMessageSendStatus.failed:
                                    return GestureDetector(
                                      onTap: () {
                                        controller.sendMsg(msgItem, isResend: true);
                                      },
                                      child: Container(
                                        width: 18,
                                        height: 18,
                                        decoration: BoxDecoration(
                                          color: Colors.black,
                                          borderRadius: BorderRadius.circular(10),
                                        ),
                                        child: const Icon(Icons.refresh, color: Colors.white, size: 12),
                                      ),
                                    );
                                  default:
                                    return Container();
                                }
                              }),
                            ],
                          ),
                        ),
                      ).marginOnly(bottom: 4);
                    },
                  ),
                ).marginOnly(left: 12),
                Obx(() {
                  return AnimatedContainer(
                    height: 40,
                    width: controller.hasFocusOnInput.value ? 350 : 180,
                    padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 9),
                    margin: EdgeInsets.symmetric(horizontal: controller.hasFocusOnInput.value ? 12 : 0),
                    alignment: Alignment.centerLeft,
                    decoration: BoxDecoration(
                      color: const Color(0xffA1908A),
                      borderRadius: BorderRadius.only(
                          topLeft: Radius.circular(controller.hasFocusOnInput.value ? 20 : 0),
                          bottomLeft: Radius.circular(controller.hasFocusOnInput.value ? 20 : 0),
                          topRight: const Radius.circular(20),
                          bottomRight: const Radius.circular(20)),
                    ),
                    duration: const Duration(milliseconds: 300),
                    child: TextField(
                      focusNode: controller.focusNode,
                      controller: controller.inputController,
                      onSubmitted: (value) {
                        if (value.isEmpty) return;
                        controller.sendTextMsg(value);
                        controller.inputController.clear();
                        controller.focusNode.requestFocus();
                      },
                      textAlignVertical: TextAlignVertical.center,
                      style: const TextStyle(color: Colors.white, fontSize: 13, fontWeight: FontWeight.w600, height: 1.4),
                      decoration: InputDecoration(
                        hintText: Copywriting.security_send_a_message_,
                        hintStyle: const TextStyle(color: Colors.white60, fontSize: 13, fontWeight: FontWeight.w600, height: 1.4),
                        filled: true,
                        isCollapsed: true,
                        fillColor: Colors.transparent,
                        border: InputBorder.none,
                      ),
                      cursorColor: Colors.white,
                      textInputAction: TextInputAction.send,
                      maxLines: 4,
                      keyboardType: TextInputType.text,
                    ),
                  );
                }).marginOnly(top: 8)
              ],
            ),
          )
        ],
      ),
    );
  }

  Widget _drawBottomWidget() {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      mainAxisSize: MainAxisSize.min,
      children: [
        IconButton(
          padding: EdgeInsets.zero,
          onPressed: () {
            GiftPanel.show(controller.otherUid);
          },
          icon: Container(
            decoration: BoxDecoration(
              color: Colors.black.withValues(alpha: 0.3),
              borderRadius: const BorderRadius.all(Radius.circular(20)),
            ),
            padding: const EdgeInsets.all(6),
            child: ImageView(
              "func_gift.png",
              width: 28,
              height: 28,
              color: Colors.white,
            )
          ),
          iconSize: 40,
        ),
        Obx(() {
          return IconButton(
            padding: EdgeInsets.zero,
            onPressed: () {
              controller.isMute.value = !controller.isMute.value;
              controller.onMuteTaped(controller.isMute.value);
            },
            icon: Container(
              decoration: BoxDecoration(
                color: Colors.black.withValues(alpha: 0.3),
                borderRadius: const BorderRadius.all(Radius.circular(20)),
              ),
              padding: const EdgeInsets.all(6),
              child: Icon(
                !controller.isMute.value ? Icons.mic : Icons.mic_off,
                size: 28,
                color: !controller.isMute.value ? Colors.white : Colors.white.withValues(alpha: 0.5),
              ),
            ),
            iconSize: 40,
          );
        }),
        Obx(() {
          return IconButton(
            padding: EdgeInsets.zero,
            onPressed: () {
              controller.isSpeaker.value = !controller.isSpeaker.value;
              controller.onSpeakerTaped(controller.isSpeaker.value);
            },
            icon: Container(
              decoration: BoxDecoration(
                color: Colors.black.withValues(alpha: 0.3),
                borderRadius: const BorderRadius.all(Radius.circular(20)),
              ),
              padding: const EdgeInsets.all(6),
              child: Icon(
                controller.isSpeaker.value ? Icons.volume_up : Icons.volume_off,
                color: controller.isSpeaker.value ? Colors.white : Colors.white54,
                size: 28,
              )
            ),
            iconSize: 40,
          );
        }),
        if (controller.isVideo)
          Obx(() {
            return IconButton(
              padding: EdgeInsets.zero,
              onPressed: () {
                controller.cameraEnable.value = !controller.cameraEnable.value;
                controller.onCameraTaped(controller.cameraEnable.value);
              },
              icon: Container(
                decoration: BoxDecoration(
                  color: Colors.black.withValues(alpha: 0.3),
                  borderRadius: const BorderRadius.all(Radius.circular(20)),
                ),
                padding: const EdgeInsets.all(6),
                child: Icon(
                  controller.cameraEnable.value ? Icons.videocam : Icons.videocam_off,
                  color: controller.cameraEnable.value ? Colors.white : Colors.white54,
                  size: 28,
                )
              ),
              iconSize: 40,
            );
          }),
        if (controller.isVideo)
          IconButton(
            padding: EdgeInsets.zero,
            onPressed: () {
              controller.isFrontCamera.value = !controller.isFrontCamera.value;
              controller.onSwitchCamera(controller.isFrontCamera.value);
            },
            icon: Container(
              decoration: BoxDecoration(
                color: Colors.black.withValues(alpha: 0.3),
                borderRadius: const BorderRadius.all(Radius.circular(20)),
              ),
              padding: const EdgeInsets.all(6),
              child: Icon(
                Icons.cameraswitch,
                color: controller.isFrontCamera.value ? Colors.white : Colors.white54,
                size: 24,
              )
            ),
            iconSize: 40,
          ),
        // IconButton(
        //   padding: EdgeInsets.zero,
        //   onPressed: () async {
        //     // Get.put(UserSettingController.build(controller.targetUid, controller.targetName));
        //     // await Get.dialog(ReportView(), useSafeArea: false);
        //     // Get.delete<UserSettingController>();
        //   },
        //   icon: Container(
        //     decoration: BoxDecoration(
        //       color: Colors.black.withOpacity(0.3),
        //       borderRadius: const BorderRadius.all(Radius.circular(20)),
        //     ),
        //     padding: const EdgeInsets.all(6),
        //     child: Image.asset(
        //       '$staticImage/message/ic_report_call_user.webp',
        //       width: 28,
        //       height: 28,
        //     ),
        //   ),
        //   iconSize: 40,
        // ),
      ],
    ).marginSymmetric(horizontal: 16, vertical: 4);
  }

  Widget _drawFullVideoView() {
    return Obx(() {
      bool isRemoteFull = controller.sizeType.value == VideoSizeType.remoteFull;
      Widget? expectFullView = isRemoteFull ? otherView : (controller.cameraEnable.value ? nativeView : null);

      return IgnorePointer(
        child: Container(
          color: Colors.black,
          child: expectFullView ?? _drawBg(),
        ),
      );
    });
  }

  Widget _drawBg() {
    return Stack(children: [
      ImageFiltered(
          imageFilter: ImageFilter.blur(sigmaX: 15, sigmaY: 15),
          child: CachedImage(
            imageUrl: controller.otherAvatar,
            placeholder: (context, url) {
              return Container(color: Colors.black, width: double.infinity, height: double.infinity);
            },
            errorWidget: (context, url, error) {
              return Container(color: Colors.black, width: double.infinity, height: double.infinity);
            },
            width: double.infinity,
            height: double.infinity,
            fit: BoxFit.cover,
          )),
      Container(
        color: Colors.black.withValues(alpha: 0.5),
      )
    ]);
  }

  Widget _drawMiniCallWidget() {
    double maxX = Get.width - kFloatingWidth - kFloatingPadding;
    double maxY = Get.height - kFloatingHeight - kFloatingPadding;

    safeOffsetConvert(offset) {
      Offset temp = offset;
      L.i('[VeoCall] safeOffsetConvert, offset: $temp');
      temp = Offset(temp.dx < kFloatingPadding ? kFloatingPadding : temp.dx, temp.dy < kFloatingPadding ? kFloatingPadding : temp.dy);
      temp = Offset(temp.dx > maxX ? maxX : temp.dx, temp.dy > maxY ? maxY : temp.dy);
      return temp;
    }

    return Obx(() {
      return controller.videoAvailable.value
          ? Positioned(
              top: floatingOffset.value.dy,
              left: floatingOffset.value.dx,
              child: Draggable(
                  feedback: Container(),
                  childWhenDragging: _drawFloatingWidget(),
                  //拖动过程回调
                  onDraggableCanceled: (Velocity velocity, Offset offset) {
                    // floatingOffset.value = offset;
                  },
                  onDragStarted: () {
                    controller.dragging.value = true;
                  },
                  onDragEnd: (DraggableDetails details) {
                    floatingOffset.value = safeOffsetConvert(details.offset);
                    controller.dragging.value = false;
                  },
                  onDragUpdate: (DragUpdateDetails details) {
                    floatingOffset.value += details.delta;
                  },
                  child: _drawFloatingWidget()))
          : Container();
    });
  }

  Widget _drawFloatingWidget() {
    if (floatingView != null) {
      return floatingView!;
    }

    floatingView = Stack(children: [
      ClipRRect(
          borderRadius: BorderRadius.circular(8),
          child: Container(
              color: Colors.black,
              width: kFloatingWidth,
              height: kFloatingHeight,
              child: Obx(() {
                return controller.sizeType.value == VideoSizeType.remoteFull
                    ? (controller.cameraEnable.value
                        ? (nativeView ?? const Text('loading...'))
                        : Container(
                            alignment: Alignment.center,
                            color: Colors.black,
                            child: Icon(
                              Icons.videocam_off,
                              color: Colors.white.withValues(alpha: 0.5),
                              size: 36,
                            )
                          ))
                    : (otherView ?? const Text('loading...'));
              }))),
      InkWell(
        onTap: () {
          controller.sizeType.value = controller.sizeType.value == VideoSizeType.localFull ? VideoSizeType.remoteFull : VideoSizeType.localFull;
        },
        child: SizedBox(
          width: kFloatingWidth,
          height: kFloatingHeight,
        ),
      )
    ]);

    return floatingView!;
  }

  void deleteFloatingWidget() {
    if (overlayEntry != null) {
      overlayEntry!.remove();
      overlayEntry = null;
    }
  }
}
