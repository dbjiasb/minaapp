import 'package:biz/base/crypt/routes.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'dart:math' as math;
import 'package:get/get.dart';

import 'package:biz/base/assets/image_path.dart';
import 'package:biz/base/router/route_helper.dart';
import 'package:biz/core/account/account_service.dart';
import 'package:biz/shared/widget/app_widgets.dart';
import '../../../../base/assets/image_view.dart';
import '../../../../base/crypt/copywriting.dart';
import '../../../../base/crypt/images.dart';
import '../../../../base/crypt/security.dart';
import '../../../../core/util/cached_image.dart';
import '../widgets/animated_view.dart';
import '../widgets/gradient_bound_painter.dart';
import 'logic.dart';
import '../service/servce.dart';

class ScenePlayView extends GetView<ScenePlayLogic> {
  ScenePlayView({super.key});

  Map get currentNode => controller.currentNode;
  Map<String, String> avatars = {};

  AnimatedTextController textAnimatedController = AnimatedTextController();
  AnimatedViewController animatedViewController = AnimatedViewController();

  Widget drawWealthView(int type) {
    return ElevatedButton(
      onPressed: () {
        RouteHelper.toRecharge(type);
      },
      style: ButtonStyle(
        backgroundColor: WidgetStateProperty.all(Colors.transparent),
        elevation: WidgetStateProperty.all(0),
        padding: WidgetStateProperty.all(const EdgeInsets.only(right: 16)),
      ),
      child: Stack(
        alignment: Alignment.centerLeft,
        children: [
          Container(
            padding: const EdgeInsets.only(left: 22, right: 8),
            margin: const EdgeInsets.only(left: 5, top: 2, bottom: 2),
            decoration: BoxDecoration(
              color: Colors.white.withOpacity(0.3),
              borderRadius: BorderRadius.circular(10),
            ),
            child: Obx(() {
              return Text(
                '${type == 0 ? MyAccount.coins : MyAccount.gems}',
                textAlign: TextAlign.right,
                style: const TextStyle(
                  color: Colors.white,
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                ),
              );
            }),
          ),
          ImageView(
            type == 0
                ? Images.security_coin_png
                : Images.security_gem_png,
            height: 16,
            width: 16,
          )
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Obx(() {
      List<Widget> contentList = [drawBG(), drawCharacter()];
      if ((currentNode[Security.security_id] ?? 0) > 0) {
        if (currentNode.isNarrator) {
          contentList.add(drawNarrator());
        } else if (currentNode.isUserAction) {
          contentList.add(drawOptions());
        } else {
          contentList.add(drawConversationContent());
        }
      }

      contentList.add(drawClickTips());

      return Scaffold(
        backgroundColor: Colors.black,
        extendBodyBehindAppBar: true,
        appBar: AppBar(
          backgroundColor: Colors.transparent,
          elevation: 0.0,
          systemOverlayStyle: SystemUiOverlayStyle.light,
          leading: Padding(
            padding: const EdgeInsets.only(left: 8),
            child: AppWidgets.backBtn(color: Colors.white),
          ),
          actions: [
            Obx(() => currentNode.needCost ? drawWealthView(1) : Container()),
            Obx(() => currentNode.needCost ? drawWealthView(0) : Container()),
            // Obx(() => curNode.canSkip ? skipBtn : Container()),
          ],
        ),
        body: (controller.isReady.value && controller.isResPrepared.value)
            ? Stack(alignment: Alignment.center, children: contentList)
            : Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  const Center(
                    child: CircularProgressIndicator(color: Color(0xFFFF56BB)),
                  ),
                  const SizedBox(height: 8),
                  !controller.isResPrepared.value
                      ? Text(
                          'Loading（${controller.progress.value}%）',
                          style: const TextStyle(color: Colors.white),
                        )
                      : Container(),
                ],
              ),
      );
    });
  }

  Widget drawCharacter() {
    String ci = currentNode[Security.security_ci] ?? '';
    return ci.isNotEmpty
        ? Positioned.fill(
            bottom: 0,
            top: 100,
            child: IgnorePointer(
              ignoring: true,
              child: AnimatedView(
                controller: animatedViewController,
                child: Container(
                  alignment: Alignment.bottomCenter,
                  child: controller.imageAsset(
                    ci,
                    fit: BoxFit.fitHeight,
                    width: double.infinity,
                  ),
                ),
              ),
            ),
          )
        : Container();
  }

  Widget drawOtherProfile() {
    String name =
        currentNode[Security.security_character] ?? controller.tName ?? '';
    String avatar = currentNode[Security.security_avatar] ?? '';
    if (avatar.isEmpty && (avatars[name]?.isNotEmpty ?? false)) {
      avatar = avatars[name]!;
    }
    avatars[name] = avatar;

    return Row(
      children: [
        const SizedBox(width: 5),
        Container(
          height: 32,
          width: 32,
          decoration: BoxDecoration(
            color: Colors.white.withValues(alpha: 0.3),
            borderRadius: BorderRadius.circular(16),
            border: Border.all(color: Colors.white, width: 2),
          ),
          child: ClipRRect(
            borderRadius: BorderRadius.circular(14),
            child: controller.imageAsset(
              avatar,
              fit: BoxFit.cover,
              width: 28,
              height: 28,
            ),
          ),
        ),
        Container(
          height: 50,
          alignment: Alignment.center,
          padding: const EdgeInsets.only(left: 8),
          child: Text(
            name,
            style: const TextStyle(
              color: Colors.white,
              fontSize: 14,
              fontWeight: FontWeight.bold,
            ),
          ),
        ),
      ],
    );
  }

  Widget drawMyProfile() {
    return Row(
      mainAxisAlignment: MainAxisAlignment.end,
      children: [
        Flexible(
          child: Container(
            height: 40,
            alignment: Alignment.center,
            padding: const EdgeInsets.only(right: 8),
            child: Text(
              MyAccount.name,
              style: const TextStyle(
                color: Colors.white,
                fontSize: 16,
                fontWeight: FontWeight.bold,
              ),
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
            ),
          ),
        ),
        Container(
          height: 32,
          width: 32,
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(14),
            border: Border.all(color: Colors.white, width: 2),
          ),
          child: ClipRRect(
            borderRadius: BorderRadius.circular(14),
            child: CachedImage(
              imageUrl: MyAccount.avatar,
              width: 28,
              height: 28,
            ),
          ),
        ),
      ],
    );
  }

  /// 对话视图
  Widget drawConversationContent() {
    bool isMine = currentNode.isMyNode;
    Widget userInfo = Flexible(
      child: Container(
        alignment: Alignment.center,
        decoration: BoxDecoration(
          borderRadius: BorderRadius.only(
            topLeft: isMine ? Radius.circular(0) : Radius.circular(20),
            topRight: isMine ? Radius.circular(20) : Radius.circular(0),
            bottomLeft: isMine ? Radius.circular(0) : Radius.circular(4),
            bottomRight: isMine ? Radius.circular(4) : Radius.circular(0),
          ),
          gradient: LinearGradient(
            begin: isMine ? Alignment.centerRight : Alignment.centerLeft,
            end: isMine ? Alignment.centerLeft : Alignment.centerRight,
            stops: const [0.0, 1],
            colors: [Color(0xFFFF6595), Color(0xFF9378FB)],
          ),
        ),
        padding: isMine
            ? const EdgeInsets.only(right: 6, left: 80)
            : const EdgeInsets.only(left: 6, right: 80),
        child: isMine ? drawMyProfile() : drawOtherProfile(),
      ),
    );

    Widget userInfoTail = CachedImage(
      imageUrl: ImagePath.game_name_trail,
      width: 40,
      height: 40,
    );

    return Positioned(
      bottom: 80,
      left: 16,
      right: 16,
      child: IgnorePointer(
        ignoring: true,
        child: Column(
          crossAxisAlignment: isMine
              ? CrossAxisAlignment.end
              : CrossAxisAlignment.start,
          children: [
            IntrinsicWidth(
              child: Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: isMine
                    ? [userInfoTail, userInfo]
                    : [userInfo, userInfoTail],
              ),
            ),
            const SizedBox(height: 2),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
              width: double.infinity,
              decoration: BoxDecoration(
                color: const Color(0xFFFBF8FC),
                borderRadius: BorderRadius.all(Radius.circular(4)).copyWith(
                  bottomLeft: isMine ? Radius.circular(12) : Radius.circular(4),
                  bottomRight: isMine
                      ? Radius.circular(4)
                      : Radius.circular(12),
                ),
              ),
              child: AnimatedTextView(
                text: currentNode[Security.security_value] ?? '',
                style: const TextStyle(
                  color: Color(0xFF727272),
                  fontSize: 14,
                  fontWeight: FontWeight.w500,
                  height: 1.4,
                ),
                controller: textAnimatedController,
              ),
            ),
          ],
        ),
      ),
    );
  }

  /// 底部按钮
  Widget drawClickTips() {
    return Positioned(
      bottom: 30,
      right: 20,
      child: IgnorePointer(
        ignoring: true,
        child: Row(
          mainAxisAlignment: MainAxisAlignment.end,
          children: [
            Text(
              Copywriting.security_click_anywhere_to_continue___,
              style: const TextStyle(color: Colors.white, fontSize: 12),
            ),
            // Image.asset('assets/images/dating/ic_next.png', package: Security.security_message, width: 20,),
          ],
        ),
      ),
    );
  }

  ///旁白
  Widget drawNarrator() {
    return Positioned(
      left: 0,
      right: 0,
      child: IgnorePointer(
        ignoring: true,
        child: Stack(
          children: [
            Container(
              padding: const EdgeInsets.all(30),
              child: Text(
                currentNode[Security.security_value] ?? '',
                style: const TextStyle(
                  color: Colors.transparent,
                  fontSize: 20,
                  fontWeight: FontWeight.w400,
                  height: 1.4,
                ),
              ),
            ),
            Container(
              alignment: Alignment.topLeft,
              decoration: BoxDecoration(
                // color: Color(0xFF3B356F).withValues(alpha: 0.8),
                gradient: LinearGradient(
                  begin: Alignment.topCenter,
                  end: Alignment.bottomCenter,
                  stops: const [0.0, 0.2, 0.8, 1],
                  colors: [
                    Color(0xFF3B356F).withValues(alpha: 0),
                    Color(0xFF3B356F).withValues(alpha: 0.9),
                    Color(0xFF3B356F).withValues(alpha: 0.9),
                    Color(0xFF3B356F).withValues(alpha: 0),
                  ],
                ),
              ),
              padding: const EdgeInsets.symmetric(
                horizontal: 30.0,
                vertical: 60,
              ),
              child: AnimatedTextView(
                text: currentNode[Security.security_value] ?? '',
                style: const TextStyle(
                  color: Colors.white,
                  fontSize: 20,
                  fontWeight: FontWeight.w400,
                  height: 1.5,
                ),
                controller: textAnimatedController,
              ),
            ),
          ],
        ),
      ),
    );
  }

  ///背景
  Widget drawBG() {
    return Obx(() {
      String bgName = controller.currentNodeBg.value;
      return ConstrainedBox(
        constraints: const BoxConstraints.expand(),
        child: GestureDetector(
          onTap: () {
            if (textAnimatedController.isAnimating()) {
              textAnimatedController.finish();
            } else {
              controller.goNext();
            }
          },
          child: bgName.isNotEmpty
              ? controller.imageAsset(bgName, fit: BoxFit.cover)
              : Container(color: Colors.black),
        ),
      );
    });
  }

  ///有多个选择的时候才需要用到
  Widget drawOptions() {
    List<dynamic> actions = currentNode[Security.security_values] ?? [];
    if (actions.isEmpty) {
      return Container();
    }

    List<Widget> contentList = [];
    for (int i = 0; i < actions.length; i++) {
      Map action = actions[i];
      Map mode = action[ES.mode] ?? {};

      int cost = action[Security.security_cost];
      int disCost = action[Security.security_disCost];
      int costType = action[Security.security_costType];
      Color fontColor = cost > 0 ? Colors.white : Color(0xFF333333);
      bool selectBefore = action[ES.sb] == 1;
      bool isLock = cost > 0 && !selectBefore;

      Widget buildLockingItem() {
        Widget buildPriceItem(bool small, String tmpCost) {
          return Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              SizedBox(width: 20),
              ImageView(
                costType == 0
                    ? Images.security_coin_png
                    : Images.security_gem_png,
                height: 16,
                width: 16,
              ),
              SizedBox(width: !small ? 2 : 1),
              Text(
                tmpCost,
                style: TextStyle(
                  /*fontFamily: AppFont.rammettoOne,*/
                  color: Colors.white,
                  fontSize: !small ? 14 : 12,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ],
          );
        }

        return Container(
          alignment: Alignment.center,
          decoration: BoxDecoration(
            image: DecorationImage(
              image: CachedImageProvider(
                costType == 1
                    ? ImagePath.game_option_cost_bg_gem
                    : ImagePath.game_option_cost_bg_coin,
              ),
              fit: BoxFit.cover,
            ),
          ),
          width: 88,
          height: 68,
          child: Stack(
            alignment: Alignment.center,
            children: [
              SizedBox(width: 88, height: 68),
              Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  disCost == 0
                      ? Container(
                          width: 88,
                          alignment: Alignment.center,
                          margin: EdgeInsets.only(left: 20),
                          child: Text(
                            Security.security_fREE,
                            style: TextStyle(
                              color: Colors.white,
                              fontSize: 20,
                              fontWeight: FontWeight.w900,
                            ),
                          ),
                        )
                      : buildPriceItem(false, cost.toString()),
                  if (disCost >= 0)
                    Stack(
                      alignment: Alignment.center,
                      children: [
                        buildPriceItem(true, cost.toString()),
                        Container(
                          width: 44,
                          height: 1,
                          color: Colors.red,
                        ).marginOnly(left: 20),
                      ],
                    ),
                ],
              ),
            ],
          ),
        );
      }

      Widget buildModelTipsView() {
        List<Color> modelBorderColors = [
          const Color(0xFFFFB121),
          const Color(0xFFFFCD6F),
          const Color(0xFFFFE1A4),
          const Color(0xFFFFA63E),
          const Color(0xFFFFDF9E),
          const Color(0xFFFFA63E),
        ];
        return GestureDetector(
          onTap: () {
            controller.showModePreview(mode);
          },
          child: Container(
            margin: const EdgeInsets.only(top: 2),
            padding: const EdgeInsets.only(left: 16),
            width: 200,
            height: 60,
            alignment: Alignment.centerRight,
            decoration: BoxDecoration(
              image: DecorationImage(
                image: CachedImageProvider(ImagePath.game_mode_bg),
                fit: BoxFit.cover,
              ),
            ),
            child: Row(
              children: [
                // const SizedBox(width: 4),
                Stack(
                  alignment: Alignment.center,
                  children: [
                    const SizedBox(width: 40, height: 40),
                    Positioned(
                      left: 4,
                      child: LayoutBuilder(
                        builder:
                            (BuildContext context, BoxConstraints constraints) {
                              return CustomPaint(
                                painter: GradientBoundPainter(
                                  radius: 8,
                                  strokeWidth: 3,
                                  width: 36,
                                  height: 36,
                                  from: Alignment.topCenter,
                                  to: Alignment.bottomCenter,
                                  colors: modelBorderColors,
                                ),
                                child: Container(
                                  decoration: BoxDecoration(
                                    border: Border.all(
                                      color: Colors.white,
                                      width: 1,
                                    ),
                                    borderRadius: BorderRadius.circular(8),
                                  ),
                                  child: ClipRRect(
                                    borderRadius: BorderRadius.circular(8),
                                    child: CachedImage(
                                      imageUrl:
                                          mode[Security.security_avatar] ?? '',
                                      width: 34,
                                      height: 34,
                                      fit: BoxFit.cover,
                                    ),
                                  ),
                                ),
                              );
                            },
                      ),
                    ),
                    Positioned(
                      bottom: 1,
                      child: Stack(
                        alignment: Alignment.center,
                        children: [
                          CachedImage(
                            imageUrl: ImagePath.dating_mode_bg,
                            width: 40,
                            height: 10,
                            fit: BoxFit.fill,
                          ),
                          Text(
                            Security.security_mode,
                            style: TextStyle(
                              color: Colors.white,
                              fontWeight: FontWeight.bold,
                              fontSize: 8,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(
                    mode[Security.security_name] ?? '',
                    style: TextStyle(
                      /*fontFamily: AppFont.rammettoOne, */
                      color: Colors.white,
                      fontSize: 11,
                      height: 1.4,
                      fontWeight: FontWeight.bold,
                    ),
                    maxLines: 2,
                  ),
                ),
                // Image.asset('assets/images/date/img_failed_grey.png', package: Security.security_message, width: 15, height: 15)
              ],
            ),
          ),
        );
      }

      Widget item = Column(
        key: GlobalKey(),
        crossAxisAlignment: CrossAxisAlignment.end,
        children: [
          GestureDetector(
            onTap: () {
              controller.onSelectAction(action);
            },
            child: Stack(
              alignment: Alignment.bottomCenter,
              children: [
                Container(height: 75),
                Stack(
                  alignment: Alignment.centerRight,
                  children: [
                    Container(
                      padding: const EdgeInsets.only(left: 24, right: 16),
                      height: 68,
                    ),
                    Positioned(
                      child: Container(
                        padding: EdgeInsets.only(
                          left: 24,
                          right: cost > 0 ? 74 : 16,
                        ),
                        height: 60,
                        decoration: BoxDecoration(
                          color: cost > 0 ? null : Colors.white,
                          borderRadius: cost > 0
                              ? null
                              : const BorderRadius.only(
                                  topLeft: Radius.circular(30),
                                  bottomLeft: Radius.circular(30),
                                ),
                          image: cost > 0
                              ? DecorationImage(
                                  image: CachedImageProvider(
                                    costType == 0
                                        ? ImagePath.game_option_bg_coin
                                        : ImagePath.game_option_bg_gem,
                                  ),
                                  fit: BoxFit.cover,
                                )
                              : null,
                        ),
                        child: Row(
                          children: [
                            Expanded(
                              child: Text(
                                '${action[Security.security_value]}',
                                style: TextStyle(
                                  /*fontFamily: AppFont.rammettoOne, */
                                  color: fontColor,
                                  fontSize: 12,
                                  fontWeight: FontWeight.bold,
                                ),
                                maxLines: 2,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                    isLock ? buildLockingItem() : Container(),
                  ],
                ),
                selectBefore
                    ? Positioned(
                        top: 0,
                        left: 16,
                        child: Container(
                          alignment: Alignment.center,
                          width: 88,
                          height: 24,
                          decoration: BoxDecoration(
                            image: DecorationImage(
                              image: CachedImageProvider(ImagePath.game_option_before),
                              fit: BoxFit.cover,
                            ),
                          ),
                          child: Text(
                            Security.security_bEFORE,
                            style: TextStyle(
                              /*fontFamily: AppFont.rammettoOne, */
                              color: Colors.white,
                              fontSize: 13,
                              fontWeight: FontWeight.w900,
                            ),
                          ),
                        ),
                      )
                    : Container(),
              ],
            ),
          ),
          ((mode[Security.security_id] ?? '').isNotEmpty && !selectBefore)
              ? buildModelTipsView()
              : Container(),

          /// Mode tips
        ],
      );

      contentList.add(item);
      if (i < actions.length - 1) {
        contentList.add(const SizedBox(height: 16));
      }
    }

    return Center(
      child: Container(
        margin: const EdgeInsets.only(left: 32),
        alignment: Alignment.center,
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: contentList,
        ),
      ),
    );
  }
}
