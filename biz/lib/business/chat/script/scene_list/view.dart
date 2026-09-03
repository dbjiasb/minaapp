import 'package:biz/base/crypt/routes.dart';
import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:get/get.dart';
import 'package:bot_toast/bot_toast.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';

import 'package:biz/base/assets/image_path.dart';
import 'package:biz/base/router/route_helper.dart';

import '../../../../base/crypt/copywriting.dart';
import '../../../../base/crypt/security.dart';
import '../../../../base/router/router_names.dart';
import '../../../../core/util/cached_image.dart';
import '../../../../shared/toast/toast.dart';
import 'logic.dart';

class SceneListView extends GetView<SceneListController> {
  SceneListView({Key? key}) : super(key: key);

  @override
  late SceneListController controller;

  Widget drawContent() {
    return ListView.separated(
      padding: const EdgeInsets.symmetric(vertical: 12),
      itemBuilder: (context, index) {
        return drawItem(controller.sceneList[index]);
      },
      separatorBuilder: (context, index) {
        return const SizedBox(height: 12);
      },
      itemCount: controller.sceneList.length,
    );
  }

  Widget drawItem(Map dating) {
    return Container(
      height: 250,
      width: double.infinity,
      margin: const EdgeInsets.symmetric(horizontal: 12),
      child: Stack(
        children: [
          Positioned.fill(child: Container(color: Colors.transparent)),
          Positioned(
            left: 0,
            right: 0,
            bottom: 0,
            top: 40,
            child: Container(
              decoration: BoxDecoration(
                color: Color(0xFF3A0B4F),
                borderRadius: BorderRadius.circular(12),
              ),
              child: Row(
                children: [
                  SizedBox(width: 134.w + 24),
                  Expanded(
                    child: SizedBox(
                      width: double.infinity,
                      height: 210,
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          SizedBox(height: 12),
                          Text(
                            dating[Security.security_title] ?? "",
                            maxLines: 2,
                            overflow: TextOverflow.ellipsis,
                            style: TextStyle(
                              color: dating[Security.security_unlocked] == 0
                                  ? Colors.white.withValues(alpha: 0.7)
                                  : Colors.white,
                              fontSize: 13,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                          SizedBox(height: 8),
                          Text(
                            dating[Security.security_intro] ?? "",
                            maxLines: 3,
                            overflow: TextOverflow.ellipsis,
                            style: const TextStyle(
                              color: Colors.white,
                              fontSize: 11,
                              height: 1.3,
                            ),
                          ),
                          SizedBox(height: 8),
                          drawModes(dating[Security.security_gainedPersonas]),
                          Spacer(),
                          drawActionBtn(dating).marginSymmetric(horizontal: 8),
                          SizedBox(height: 16),
                        ],
                      ),
                    ),
                  ),
                  SizedBox(width: 16),
                ],
              ),
            ),
          ),
          Positioned(
            left: 12,
            height: 234,
            width: 134.w,
            child: ClipRRect(
              borderRadius: BorderRadius.circular(12),
              child: Stack(
                alignment: Alignment.center,
                children: [
                  Positioned.fill(
                    child: CachedImage(
                      imageUrl: dating[Security.security_cover] ?? "",
                      fit: BoxFit.cover,
                    ),
                  ),
                  if (dating[Security.security_unlocked] == 0)
                    Positioned.fill(
                      child: BackdropFilter(
                        filter: ImageFilter.blur(sigmaX: 5.0, sigmaY: 5.0),
                        child: Container(color: Colors.transparent),
                      ),
                    ),
                  if (dating[Security.security_unlocked] == 0)
                    Container(color: Colors.black38),
                  if (dating[Security.security_unlocked] == 0)
                    Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      crossAxisAlignment: CrossAxisAlignment.center,
                      children: [
                        CachedImage(
                          imageUrl: ImagePath.dating_list_lock,
                          height: 28,
                          width: 28,
                          fit: BoxFit.cover,
                        ).marginOnly(bottom: 3),
                        Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 8,
                            vertical: 4,
                          ),
                          decoration: BoxDecoration(
                            color: Colors.black26,
                            borderRadius: BorderRadius.circular(30),
                          ),
                          child: Text(
                            dating[Security.security_unlockConditionText] ?? "",
                            style: const TextStyle(
                              color: Colors.white,
                              fontSize: 12,
                              fontWeight: FontWeight.w500,
                            ),
                          ),
                        ),
                      ],
                    ),
                  Positioned(left: 2, top: 2, child: drawSceneTitle(dating)),
                ],
              ),
            ),
          ),
        ],
      ),
      // ),
    );
  }

  Widget drawSceneTitle(Map dating) {
    return Align(
      alignment: Alignment.topLeft,
      child: Container(
        alignment: Alignment.center,
        margin: const EdgeInsets.only(left: 8, top: 10),
        width: 56,
        height: 16,
        // padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
        decoration: BoxDecoration(
          image: DecorationImage(
            image: CachedImageProvider(ImagePath.dating_chapter_bg),
            fit: BoxFit.fill,
          ),
        ),
        child: Text(
          dating[Security.security_chapterName] ?? "",
          style: const TextStyle(
            color: Colors.white,
            fontSize: 11,
            fontWeight: FontWeight.w900,
          ),
        ),
      ),
    );
  }

  Widget drawModes(List<dynamic>? gainedPersonas) {
    if ((gainedPersonas ?? []).isEmpty) {
      return const Spacer();
    }
    return SizedBox(
      height: 48,
      width: double.infinity,
      child: ListView.separated(
        scrollDirection: Axis.horizontal,
        shrinkWrap: true,
        itemBuilder: (context, index) {
          return drawModeItem(gainedPersonas[index]);
        },
        separatorBuilder: (context, index) => const SizedBox(width: 8),
        itemCount: gainedPersonas!.length,
      ),
    );
  }

  Widget drawModeItem(Map datingGainedPersona) {
    return Stack(
      alignment: Alignment.bottomCenter,
      children: [
        Stack(
          children: [
            Container(
              height: 48,
              width: 48,
              decoration: BoxDecoration(
                color: Color(0xFFD9D9D9),
                borderRadius: BorderRadius.circular(8),
                border: Border.all(color: Color(0xFFFF7D7D), width: 1),
              ),
              child: ClipRRect(
                borderRadius: BorderRadius.circular(8),
                child: CachedImage(
                  imageUrl:
                      datingGainedPersona[Security.security_persona]?[Security
                          .security_avatar] ??
                      "",
                  height: double.infinity,
                  width: double.infinity,
                ),
              ),
            ),
            datingGainedPersona[Security.security_gained] == 0
                ? Positioned.fill(
                    child: Container(
                      decoration: BoxDecoration(
                        color: Colors.black26,
                        borderRadius: BorderRadius.circular(8),
                      ),
                    ),
                  )
                : Container(),
          ],
        ),
        Positioned(
          bottom: 0,
          child: Stack(
            alignment: Alignment.center,
            children: [
              CachedImage(
                imageUrl: ImagePath.dating_mode_bg,
                width: 56,
                height: 16,
                fit: BoxFit.fill,
              ),
              Text(
                Security.security_mode,
                style: TextStyle(
                  color: Colors.white,
                  fontWeight: FontWeight.w900,
                  fontSize: 10,
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget drawActionBtn(Map dating) {
    return GestureDetector(
      onTap: () => handleToDateAction(dating),
      child: Container(
        width: double.infinity,
        height: 42,
        alignment: Alignment.center,
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(8),
        ),
        foregroundDecoration: dating[Security.security_unlocked] == 0
            ? BoxDecoration(
                color: Color(0x80333333),
                borderRadius: BorderRadius.circular(8),
              )
            : null,
        child: Text(
          Copywriting.security_start_Game,
          style: const TextStyle(
            color: Color(0xFF080E1B),
            fontSize: 15,
            fontWeight: FontWeight.w900,
          ),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    try {
      SceneListController logic = Get.find<SceneListController>();
      controller = logic;
    } catch (e) {
      controller = SceneListController();
    }

    return Stack(
      children: [
        Positioned.fill(child: Container(color: Colors.black)),
        Positioned(
          left: 0,
          right: 0,
          height: 257,
          child: CachedImage(imageUrl: ImagePath.dating_list_bg, fit: BoxFit.fill),
        ),
        Scaffold(
          appBar: _buildAppBar(),
          backgroundColor: Colors.transparent,
          body: FutureBuilder(
            future: controller.querySceneList(),
            builder: (context, snapshot) {
              if (snapshot.connectionState == ConnectionState.waiting) {
                return const Center(child: CircularProgressIndicator());
              }
              return drawContent();
            },
          ),
        ),
      ],
    );
  }

  AppBar _buildAppBar() {
    return AppBar(
      title: Text(
        Copywriting.security_dating_Game,
        style: const TextStyle(
          color: Colors.white,
          fontSize: 20,
          fontWeight: FontWeight.bold,
        ),
      ),
      systemOverlayStyle: SystemUiOverlayStyle.light,
      backgroundColor: Colors.transparent,
      // titleTextStyle: TextStyle(
      //     color: SWColors.t2, fontSize: 20,  fontWeight: FontWeight.bold),
      leading: Padding(
        padding: const EdgeInsets.only(left: 8),
        child: IconButton(
          onPressed: Get.back,
          icon: CachedImage(imageUrl: ImagePath.back, width: 24, height: 24),
        ),
      ),
      actions: [
        // _buildModeButton(() {
        //   // MessageRoute.toModePage(targetUid);
        // })
      ],
    );
  }

  Widget _buildModeButton(GestureTapCallback? onTap) {
    return InkWell(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.only(top: 12, bottom: 12, right: 16),
        child: Container(
          alignment: Alignment.center,
          padding: const EdgeInsets.symmetric(horizontal: 8),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(30),
            color: Color(0xFF12151C),
          ),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Image.asset(
                'assets/images/ic_mode_game.png',
                package: Security.security_message,
                width: 24,
                height: 24,
              ),
              Text(
                Security.security_mode,
                style: TextStyle(color: Colors.white, fontSize: 12),
              ),
            ],
          ),
        ),
      ),
    );
  }

  void handleToDateAction(Map dating) {
    if (dating[Security.security_unlocked] == 0) {
      Toast.show(
        Copywriting.security_unlock_conditions_not_met__Upgrade_your_level_now_,
      );
    } else {
      if (dating[Security.security_resource]?[Security.security_resourceUrl]
              ?.isEmpty ??
          true) {
        Toast.show(
          Copywriting.security_some_error_occurred__Please_try_again_later_,
        );
        return;
      }

      // HistoryController.to.addHistory(dating);
      RouteHelper.toPage(
        Routers.datingGame,
        params: {
          Security.security_sceneName: dating[Security.security_name] ?? '',
          Security.security_targetAvatar:
              dating[Security.security_userAvatar] ?? '',
          Security.security_targetName:
              dating[Security.security_userNickname] ?? '',
          Security.security_sceneId: (dating[Security.security_id] ?? 0)
              .toString(),
          // Security.security_nextId: dating[Security.security_nextId],
          Security.security_targetUid: (dating[Security.security_userId] ?? 0)
              .toString(),
          // Security.security_type: dating[Security.security_type],
          Security.security_accType: '3',
          Security.security_resourceUrl:
              dating[Security.security_resource]?[Security
                  .security_resourceUrl] ??
              '',
          Security.security_resourceMd5:
              dating[Security.security_resource]?[Security
                  .security_resourceMd5] ??
              '',
        },
      );
      // HistoryController.to.addHistory(dating);
      // Get.toNamed(NavigatePath.scenePlay, parameters: {
      //   Security.security_sceneName: dating[Security.security_name] ?? '',
      //   Security.security_targetAvatar: dating[Security.security_userAvatar] ?? '',
      //   Security.security_targetName: dating[Security.security_userNickname] ?? '',
      //   Security.security_sceneId: (dating[Security.security_id] ?? 0).toString(),
      //   // Security.security_nextId: dating[Security.security_nextId],
      //   Security.security_targetUid: (dating[Security.security_userId] ?? 0).toString(),
      //   // Security.security_type: dating[Security.security_type],
      //   Security.security_accType: '3',
      //   Security.security_resourceUrl: dating[Security.security_resource]?[Security.security_resourceUrl] ?? '',
      //   Security.security_resourceMd5: dating[Security.security_resource]?[Security.security_resourceMd5] ?? ''
      // });
    }
  }
}
