import 'package:biz/base/crypt/routes.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import 'package:flutter/services.dart';
import 'package:get/get.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:biz/base/app_info/app_manager.dart';
import 'package:biz/base/assets/image_path.dart';
import 'package:biz/business/chat/ai_mode/widget/mode_widget.dart';
import 'package:biz/shared/app_theme.dart';
import 'package:biz/shared/widget/app_widgets.dart';

import '../../../../base/api_service/api_config.dart';
import '../../../../base/api_service/api_response.dart';
import '../../../../base/assets/image_view.dart';
import '../../../../base/crypt/copywriting.dart';
import '../../../../base/crypt/security.dart';
import '../../../../base/router/route_helper.dart';
import '../../../../core/util/cached_image.dart';
import 'logic.dart';
import '../widget/aimode_intro.dart';
import '../service/ai_mode_service.dart';

class MyAIModeView extends GetView<MyAIModeLogic> {
  MyAIModeView({Key? key}) : super(key: key);

  Map get curMode => controller.curMode;

  set curMode(Map value) => controller.curMode.value = value;

  @override
  Widget build(BuildContext context) {
    Map params = Get.parameters;
    controller.uid = int.parse(params[Security.security_uid]);
    controller.selectedId = params[Security.security_defaultId] ?? '';

    return FutureBuilder(
        future: AIModeService.instance.queryAIMode(controller.uid),
        builder: (context, snapshot) {
          bool hasData = false;
          Widget body;
          if (snapshot.connectionState != ConnectionState.done) {
            body = Center(
              child: SizedBox(
                width: 32,
                height: 32,
                child: CircularProgressIndicator(strokeWidth: 3.0, color: Colors.white,),
              ),
            );
          } else {
            hasData = snapshot.data != null && (snapshot.data!.data[ES.modes]?.isNotEmpty ?? false);
            if (hasData) {
              controller.init(snapshot.data as ApiResponse);
            }
            body = hasData
                ? drawContent()
                : SizedBox(
                    width: double.infinity,
                    height: double.infinity,
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      crossAxisAlignment: CrossAxisAlignment.center,
                      children: [
                        Text(
                          snapshot.data?.description ?? Copywriting.security_an_error_occurred__please_try_again_later_,
                          style: const TextStyle(color: Colors.white, fontSize: 16),
                          textAlign: TextAlign.center,
                        ),
                      ],
                    ),
                  );
          }
          return Scaffold(
              extendBodyBehindAppBar: true,
              backgroundColor: Colors.black,
              appBar: AppBar(
                title: GetBuilder<MyAIModeLogic>(
                    id: kModeAppBarTitleId,
                    builder: (logic) {
                      return Text(hasData ? (curMode[ES.cName] ?? "") : '',
                          style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 18));
                    }),
                backgroundColor: Colors.transparent,
                elevation: 0.0,
                systemOverlayStyle: SystemUiOverlayStyle.light,
                actions: [
                  GestureDetector(
                    onTap: () {
                      RH.toWeb('${ApiConfig.cdn}/app/h5/terms/about_mode.html', title: Copywriting.security_about_AI_MODE);
                    },
                    child: ImageView(
                      "mode_question.webp",
                      width: 28,
                      height: 28,
                    ).marginOnly(right: 16),
                  )
                ],
                leading: Center(
                  child: InkWell(
                    onTap: () {
                      RH.back();
                    },
                    child: Container(padding: const EdgeInsets.only(left: 8, top: 4, bottom: 4), child: AppWidgets.backBtn()),
                  ),
                ),
              ),
              body: body);
        });
  }

  Widget drawContent() {
    return Stack(
      children: [
        Obx(() {
          return InkWell(
            onTap: () {
              if (controller.expand.value) {
                controller.expand.value = false;
              }
            },
            child: Container(
              // margin: EdgeInsets.only(top: 81.w, bottom: 81.w),
              width: double.infinity,
              height: double.infinity,
              decoration: BoxDecoration(
                  color: Colors.black,
                  image: DecorationImage(
                    image: CachedNetworkImageProvider(
                      curMode[ES.cb] ?? "",
                    ),
                    fit: BoxFit.cover,
                    // colorFilter: curPersonality.own == 0 ? const ColorFilter.mode(Colors.black, BlendMode.color) : null,
                  )),
            ),
          );
        }),
        Container(
          // margin: EdgeInsets.only(top: 81.w, bottom: 81.w),
          width: double.infinity,
          height: double.infinity,
          color: Colors.black.withValues(alpha: 0.15),
        ),
        Obx(() {
          return curMode[Security.security_own] == 0
              ? Container(
                  alignment: Alignment.center,
                  margin: const EdgeInsets.only(bottom: 100),
                  width: double.infinity,
                  height: double.infinity,
                  decoration: BoxDecoration(
                    color: Colors.black.withValues(alpha: 0.5),
                    borderRadius: BorderRadius.circular(7),
                  ),
                  child: ImageView(
                    "mode_lock.webp",
                    width: 50,
                    height: 53,
                  ),
                )
              : Container();
        }),
        // Positioned(
        //     child: Container(
        //       height: 230,
        // decoration: const BoxDecoration(
        //       gradient: LinearGradient(
        //         stops: [0.0, 0.4, 1],
        //           colors: [Colors.black, Colors.black, Colors.transparent],
        //           begin: Alignment.topCenter,
        //           end: Alignment.bottomCenter
        //       ),
        //   ),
        //     )
        // ),
        Positioned(
          top: 10,
          child: SafeArea(
              bottom: false,
              child: Container(
                // width: 41, height: 49,
                padding: const EdgeInsets.only(left: 8),
                alignment: Alignment.centerLeft,
                child: IconButton(
                    padding: EdgeInsets.zero,
                    onPressed: () {
                      controller.expand.value = true;
                    },
                    icon: ImageView(
                      "mode_story.webp",
                      width: 34,
                      fit: BoxFit.fitWidth,
                    )),
              )),
        ),
        Positioned(
          bottom: 0,
          left: 0,
          right: 0,
          child: Container(
            padding: const EdgeInsets.only(top: 10),
            alignment: Alignment.bottomCenter,
            decoration: const BoxDecoration(
              gradient: LinearGradient(
                  stops: [0.0, 0.71, 1], colors: [Colors.transparent, Colors.black, Colors.black], begin: Alignment.topCenter, end: Alignment.bottomCenter),
            ),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.end,
              children: [
                Container(
                  height: 40,
                  width: 288,
                  alignment: Alignment.center,
                  decoration: BoxDecoration(image: DecorationImage(image: ImageView.getImageProvider("mode_name_bg.webp"))),
                  child: Obx(() {
                    return Text('${curMode[Security.security_name]}'.tr, style: const TextStyle(color: Colors.white, fontSize: 14, fontWeight: FontWeight.bold))
                        .marginOnly(bottom: 2);
                  }),
                ),
                // Image.asset('assets/images/message/img_mode_name_decoration.png', package: Security.security_app_common,  width: 150, height: 20).marginOnly(bottom: 2),
                Container(
                  width: 168,
                  height: 28,
                  alignment: Alignment.center,
                  // decoration: const BoxDecoration(image: DecorationImage(image: AssetImage('/img_mymode_starbg.webp'))),
                  child: Obx(()=>ModeWidget.modeStarView(curMode[Security.security_star]?[Security.security_star] ?? 1)),
                ),
                Container(
                  margin: const EdgeInsets.symmetric(vertical: 12),
                  height: 110,
                  child: GridView.builder(
                    padding: const EdgeInsets.symmetric(horizontal: 16),
                    scrollDirection: Axis.horizontal,
                    itemCount: controller.aiModes.length,
                    gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                        crossAxisCount: 1, childAspectRatio: 216.0 / 110.0, mainAxisSpacing: 16, crossAxisSpacing: 1),
                    itemBuilder: (BuildContext context, int index) {
                      Map mode = controller.aiModes[index];
                      return drawItem(mode);
                    },
                  ),
                ),
                Obx(() {
                  return Container(
                      alignment: Alignment.center,
                      constraints: const BoxConstraints(minHeight: 64),
                      padding: const EdgeInsets.symmetric(horizontal: 12),
                      child: Text(curMode[Security.security_gainWayDesc] ?? '',
                          style: TextStyle(color: Colors.white.withValues(alpha: 0.5), fontSize: 14, fontWeight: FontWeight.w500)));
                }),
                Obx(() {
                  return drawActionButton(curMode);
                }),
                const SafeArea(
                    top: false,
                    child: SizedBox(
                      height: 10,
                    ))
              ],
            ),
          ),
        ),
        Obx(() {
          return Positioned(
              bottom: 0,
              right: 0,
              left: 0,
              child: controller.expand.value
                  ? AIModeIntro(curMode, () {
                      controller.expand.value = false;
                    })
                  : Container());
        })
      ],
    );
  }

  Widget drawActionButton(Map mode) {
    return GetBuilder<MyAIModeLogic>(
        id: '$kMyAIModeObjButtonId${mode[Security.security_id]}',
        builder: (c) {
          bool isOwned = mode[Security.security_own] == 1;
          int type = mode[Security.security_gainWay];
          int selected = mode[Security.security_selected];

          bool toBuy = !isOwned && type == 2;
          bool toDating = !isOwned && type == 1;
          bool toSwitch = isOwned && selected == 0;
          bool inUsing = isOwned && selected == 1;
          bool showTimeLimit = !isOwned && mode[Security.security_timeLimited] == 1;
          String btnBg() {
            // if (inUsing || showTimeLimit) return '$modeResPath/btn_mode_store_owe.webp';
            if (inUsing || showTimeLimit || toDating) return "mode_used.webp";
            if (toBuy) return "mode_buy.webp";
            return "mode_buy.webp";
          }

          String aText() {
            if (inUsing) return Copywriting.security_in_use.tr;
            if (showTimeLimit) return Copywriting.security_time_limit.tr;
            if (toBuy) return Security.security_buy.tr;
            if (toDating) return Copywriting.security_time_limit.tr; //Copywriting.security_go_Play.tr;
            if (toSwitch) return Security.security_switch.tr;
            return '';
          }

          Widget drawChild() {
            Widget child;
            if (toBuy) {
              child = drawPayButton(mode);
            } else {
              child = Text(aText(), style: const TextStyle(color: Colors.white, fontSize: 14, fontWeight: FontWeight.bold));
            }
            return child;
          }

          return GestureDetector(
            onTap: () {
              if (toSwitch) controller.switchToCur();
              // if (toDating) controller.toDating();
              if (toBuy) controller.pay();
            },
            child: Container(
              alignment: Alignment.center,
              height: 37,
              // width: 140,
              decoration: BoxDecoration(image: DecorationImage(image: ImageView.getImageProvider(btnBg()), fit: BoxFit.fitHeight)),
              child: drawChild(),
            ),
          );
        });
  }

  Widget drawPayButton(Map mode) {
    bool hasDiscount = mode[ES.dp] > 0 && mode[ES.dp] < mode[Security.security_price];
    return Column(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        const SizedBox(height: 1),
        Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            ModeWidget.wealthIcon(mode[ES.costType]),
            const SizedBox(width: 2),
            Text('${hasDiscount ? mode[ES.dp] : mode[Security.security_price]}', style: const TextStyle(color: Colors.white, fontSize: 14, fontWeight: FontWeight.bold))
          ],
        ),
        if (hasDiscount)
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              ModeWidget.wealthIcon(mode[ES.costType], width: 10, height: 10),
              const SizedBox(width: 1),
              Text('${mode[Security.security_price]}', style: const TextStyle(color: Colors.white, fontSize: 9, decoration: TextDecoration.lineThrough, height: 1))
            ],
          )
      ],
    );
  }

  Widget drawItem(Map mode) {
    return GetBuilder<MyAIModeLogic>(
        id: '$kMyAIModeObjId${mode[Security.security_id]}',
        builder: (logic) {
          return GestureDetector(
            onTap: () {
              controller.resetCurAIMode(mode);
            },
            child: Obx(() {
              return SizedBox(
                // height: 110, width: 57,
                child: Column(
                  children: [
                    if (curMode[Security.security_id] != mode[Security.security_id])
                      const SizedBox(
                        height: 10,
                      ),
                    Container(
                      // decoration: BoxDecoration(
                      //   borderRadius: BorderRadius.circular(mode.own == 1 ? 4 : 0),
                      //   border: Border.all(color: mode.own == 1 ? const Color(0xFFFFCE37) : Colors.transparent, width: 2)
                      // ),
                      height: 100,
                      child: Stack(
                        children: [
                          ClipRRect(
                            borderRadius: BorderRadius.circular(4),
                            child: CachedImage(
                              imageUrl: mode[ES.sb] ?? mode[ES.cb] ?? "",
                              height: 100,
                              width: 57,
                              fit: BoxFit.cover,
                            ),
                          ),
                          if (mode[Security.security_own] == 0)
                            Container(
                              alignment: Alignment.center,
                              color: Colors.black.withOpacity(0.5),
                              height: 100,
                              width: 57,
                              child: ImageView(
                                "mode_lock.webp",
                                width: 18,
                                height: 20,
                              ),
                            ),
                          ClipRRect(
                              borderRadius: BorderRadius.circular(4),
                              child: ImageView(mode[Security.security_selected] == 1 ? "mode_frame_using.webp" : "mode_frame.webp",
                                  height: 100, width: 57, fit: BoxFit.fill)),
                          if (mode[Security.security_selected] == 1)
                            Positioned(
                              right: 4,
                              bottom: 4,
                              child: ImageView("mode_select.webp", width: 16, height: 16),
                            )
                        ],
                      ),
                    ),
                    if (curMode[Security.security_id] == mode[Security.security_id])
                      const SizedBox(
                        height: 10,
                      ),
                  ],
                ),
              );
            }),
          );
        });
  }
}
