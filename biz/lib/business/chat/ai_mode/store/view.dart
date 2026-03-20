import 'package:biz/base/crypt/images.dart';
import 'package:biz/base/crypt/routes.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:get/get.dart';
import 'package:biz/base/assets/image_path.dart';
import 'package:biz/base/router/route_helper.dart';
import 'package:biz/core/account/account_service.dart';
import 'package:biz/shared/widget/app_widgets.dart';
import '../../../../base/assets/image_view.dart';
import '../../../../base/crypt/security.dart';
import '../../../../base/router/router_names.dart';
import '../../../../core/util/cached_image.dart';
import '../../../../shared/app_theme.dart';
import '../service/ai_mode_service.dart';
import '../widget/mode_widget.dart';
import 'controller.dart';

class AIModeStoreView extends GetView<AIModeStoreController> {

  AIModeStoreView({super.key});

  final logic = Get.put(AIModeStoreController());

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF12151C),
      extendBody: true,
      extendBodyBehindAppBar: true,
      appBar: AppBar(
        toolbarHeight: 34,
        titleSpacing: 8,
        leadingWidth: 40,
        centerTitle: false,
        // automaticallyImplyLeading: false,
        title: Text('Store${''}', style: TextStyle(color: Colors.white, fontSize: 20, fontWeight: FontWeight.bold), textAlign: TextAlign.start,),
        backgroundColor: Colors.transparent,
        elevation: 0.0,
        // titleSpacing: titleSpacing,
        systemOverlayStyle: SystemUiOverlayStyle.light,
        leading: Center(child: InkWell(
          onTap: () {
            Get.back();
          },
          child: Padding(padding: EdgeInsets.only(left: 8), child: AppWidgets.backBtn(),)),
        ),
        actions: [
          GestureDetector(
            onTap: () {
              RH.toCoins();
            },
            child: Obx(() {
              return ModeWidget.wealthView(
                   0,
                  MyAccount.coins
              );
            }),
          ),
          const SizedBox(width: 8),
          GestureDetector(
              onTap: () {
                RH.toGems();
              },
              child: Obx(() {
                return ModeWidget.wealthView(
                    1,
                    MyAccount.gems
                );
              })
          ),
          const SizedBox(width: 12)
        ],
      ),
      body: Stack(
          children: [
            IgnorePointer(child: drawBG()),
            FutureBuilder(future: controller.refresh(), builder: (ctx, snapshot){

              if (snapshot.connectionState == ConnectionState.done) {
                return SafeArea(
                  // bottom: false,
                    child: Padding(padding: EdgeInsets.only(top: 8), child: drawContent(),)
                );
              } else {
                return Center(
                child: CircularProgressIndicator(
                  color: AppColors.primary,
                ),
              );
              }
            }),
          ]
      ),
    );
  }

  Widget drawBG() {
    return ImageView(
      Images.security_mode_store_top_bg_webp,
      fit: BoxFit.cover,
    );
  }

  Widget drawContent() {
    return CustomScrollView(
      slivers: [
        const SliverSafeArea(bottom: false, sliver: SliverToBoxAdapter(child: SizedBox())),
        SliverPadding(
          sliver: SliverGrid.count(
            crossAxisCount: 3,
            mainAxisSpacing: 16,
            crossAxisSpacing: 8,
            childAspectRatio: 109.0 / 260.0,//194
            children: controller.personalities.map((e) => drawStoreItem(e)).toList(),
          ),
          padding: const EdgeInsets.only(left: 16, right: 16, bottom: 12),
        )
      ],
    );
  }

  Widget drawStoreItem(Map mode) {
    return SizedBox(
      width: double.infinity,
      height: double.infinity,
      child: Column(
        children: [
          Expanded(
              child: AspectRatio(
                  aspectRatio: 109.0 / 190.0,
                  child: InkWell(
                    onTap: () {
                      controller.onClickCard(mode);
                    },
                    child: Stack(
                      alignment: Alignment.bottomCenter,
                      children: [
                        ClipRRect(
                          borderRadius: BorderRadius.circular(12),
                          child: CachedImage(
                            imageUrl: mode[ES.sb] ?? mode[ES.cb] ?? "",
                            width: double.infinity,
                            height: double.infinity,
                            fit: BoxFit.cover,
                          ),
                        ),
                        Positioned(
                            left: 0, right: 0, bottom: 0,
                            child: Container(
                              alignment: Alignment.bottomCenter,
                              height: 109,
                              decoration: BoxDecoration(
                                gradient: LinearGradient(
                                    begin: Alignment.topCenter,
                                    end: Alignment.bottomCenter,
                                    colors: [
                                      Colors.transparent,
                                      Colors.black,
                                    ]
                                ),
                                borderRadius: const BorderRadius.only(bottomLeft: Radius.circular(8), bottomRight: Radius.circular(8)),
                              ),
                              child: Column(
                                mainAxisAlignment: MainAxisAlignment.end,
                                children: [
                                  Padding(
                                      padding: const EdgeInsets.symmetric(horizontal: 5),
                                      child: Text('${mode[Security.security_name]}', style: const TextStyle(color: Colors.white, fontSize: 13),textAlign: TextAlign.center, maxLines: 3, overflow: TextOverflow.ellipsis,)
                                  ),
                                  SizedBox(height: 8,),
                                  Row(
                                    mainAxisAlignment: MainAxisAlignment.center,
                                    children: List.generate(
                                        5,
                                            (index) => ImageView(
                                            index < (mode[Security.security_star]?[Security.security_star] ?? 1) ? Images.security_mode_star_light_webp : Images.security_mode_star_unlight_webp,
                                            width: 18,
                                            height: 18,
                                        )),
                                  ),
                                  const SizedBox(height: 12,)
                                ],
                              ),
                            )
                        ),
                        if ((mode[ES.tagURL] ?? '').isNotEmpty)
                          Positioned(
                              right: 0, top: 0, width: 60, height: 30,
                              child: CachedImage(
                                imageUrl: mode[ES.tagURL],
                                fit: BoxFit.cover,
                                width: 60, height: 30
                                // radius: 4,
                              )
                          ),
                        ImageView(
                          Images.security_mode_frame_webp, fit: BoxFit.fill,
                          width: double.infinity,
                          height: double.infinity,
                        ),
                      ],
                    ),
                  )
              )
          ),
          Container(
            alignment: Alignment.center,
            height: 34,
            child: Text('${mode[ES.cName]}', style: const TextStyle(color: Color(0xFFDFD1FF), fontSize: 14),),
          ),
          GetBuilder<AIModeStoreController>(
              id: 'StoreObj_${mode[Security.security_id]}',
              builder: (c) {
                return GestureDetector(
                  onTap: (){
                    if (mode[Security.security_own] == 0) controller.pay(mode);
                  },
                  child: Container(
                    alignment: Alignment.center,
                    height: 32,
                    decoration: mode[Security.security_own] == 0 ? BoxDecoration(
                        image: DecorationImage(
                            image: ImageView.getImageProvider(Images.security_mode_buy_webp),
                            fit: BoxFit.fill
                        )
                    ) : null,
                    child: mode[Security.security_own] == 0 ? drawPayBtn(mode) : Text(Security.security_owned, style: TextStyle(color: Colors.white, fontSize: 14, fontWeight: FontWeight.bold)),
                  ),
                );
              }
          ),
        ],
      ),
    );
  }

  Widget drawPayBtn(Map mode) {
    bool hasDiscount = mode[ES.dp] > 0 && mode[ES.dp] < mode[Security.security_price];
    return Column(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        const SizedBox(height: 1),
        Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            ImageView(mode[ES.costType] == 0 ? Images.security_coin_png : Images.security_gem_png, width: 16, height: 16),
            const SizedBox(width: 2),
            Text('${hasDiscount ? mode[ES.dp] : mode[Security.security_price]}', style: const TextStyle(color: Colors.white, fontSize: 14, fontWeight: FontWeight.bold))
          ],
        ),
        if (hasDiscount) Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            ImageView(mode[ES.costType] == 0 ?  Images.security_coin_png : Images.security_gem_png, width: 10, height: 10),
            const SizedBox(width: 1),
            Text('${mode[Security.security_price]}', style: const TextStyle(color: Colors.white, fontSize: 9, decoration: TextDecoration.lineThrough, height: 1))
          ],
        )
      ],
    );
  }
}
