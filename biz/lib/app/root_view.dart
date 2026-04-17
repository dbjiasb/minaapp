import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';

import 'package:biz/base/router/router_names.dart';
import 'package:biz/base/webview/web_view.dart';
import 'package:biz/business/home_page_lists/home_page.dart';
import 'package:biz/core/account/account_service.dart';
import 'package:biz/core/account/create_account.dart';
import 'package:biz/core/account/login_channel.dart';
import 'package:biz/shared/widget/image_viewer.dart';
import 'package:biz/shared/widget/video_player_view.dart';

import '../business/account/collections_view.dart';
import '../business/account/edit_my_info_view.dart';
import '../business/account/settings.dart';
import '../business/chat/ai_mode/my_mode/binding.dart';
import '../business/chat/ai_mode/my_mode/view.dart';
import '../business/chat/ai_mode/store/view.dart';
import '../business/chat/call/ai_call_view.dart';
import '../business/chat/call/call_view.dart';
import '../business/chat/chat_record/chat_record_view.dart';
import '../business/chat/chat_room/chat_room_view.dart';
import '../business/chat/chat_room/chat_theater_room_view.dart';
import '../business/chat/chat_room/chat_private_room_view.dart';
import '../business/chat_history/chat_history_view.dart';
import '../business/create_center/advance_page.dart';
import '../business/create_center/basic_page.dart';
import '../business/create_center/edit_oc_page.dart';
import '../business/create_center/gen_page.dart';
import '../business/create_center/voice_page.dart';
import '../business/crowd/create_crowed_binding.dart';
import '../business/crowd/create_crowed_page.dart';
import '../business/crowd/info/binding.dart';
import '../business/crowd/info/view.dart';
import '../business/moment/create_moment_view/create_moment_view_binding.dart';
import '../business/moment/create_moment_view/create_moment_view_view.dart';
import '../business/moment/create_post_image/create_post_image_binding.dart';
import '../business/moment/create_post_image/create_post_image_view.dart';
import '../business/moment/moment_detail_view/moment_detail_view_binding.dart';
import '../business/moment/moment_detail_view/moment_detail_view_view.dart';
import '../business/purchase/recharge_currency_view.dart';
import '../business/purchase/recharge_premium_view.dart';
import '../business/search/binding.dart';
import '../business/search/view.dart';
import '../business/user_page/person_view.dart';
import '../shared/toast/toast.dart';
import './skeleton_view.dart';

class RootView extends StatelessWidget {
  const RootView({super.key});

  @override
  Widget build(BuildContext context) {
    return ScreenUtilInit(
      designSize: const Size(375, 812),
      minTextAdapt: true,
      splitScreenMode: true,
      builder: (_, child) {
        return GetMaterialApp(
          theme: ThemeData(colorScheme: ColorScheme.fromSeed(seedColor: Colors.deepPurple), useMaterial3: true),
          builder: Toast.init(),
          initialRoute: AccountService.instance.loggedIn ? Routers.root : Routers.loginChannel,
          getPages: [
            GetPage(name: Routers.login, page: () => CreateAccountView()),
            GetPage(name: Routers.root, page: () => SkeletonView()),
            GetPage(name: Routers.chat, page: () => ChatRoomView()),
            GetPage(name: Routers.chatHistory, page: () => ChatRecordView()),
            GetPage(name: Routers.chatTheater, page: () => ChatTheaterRoomView()),
            GetPage(name: Routers.home, page: () => HomePageView()),
            GetPage(name: Routers.webView, page: () => WebView()),
            GetPage(name: Routers.loginChannel, page: () => LoginChannelView()),
            GetPage(name: Routers.imageBrowser, page: () => ImageViewer()),
            GetPage(name: Routers.editMe, page: () => EditMyInfoPage()),
            GetPage(name: Routers.person, page: () => PersonViewPage()),
            GetPage(name: Routers.videoPlayer, page: () => VideoPlayerView()),
            GetPage(name: Routers.crowedInfo, page: () => CrowedInfoView(), binding: CrowedInfoBinding()),
            GetPage(name: Routers.call, page: () => CallView()),
            GetPage(name: Routers.aiCall, page: () => AICallView()),
            GetPage(name: Routers.modeStore, page: () => AIModeStoreView()),
            GetPage(name: Routers.modeList, page: () => MyAIModeView(), binding: MyAIModeBinding()),
            // GetPage(name: Routers.datingList, page: () => SceneListView(), binding: SceneListBinding()),
            GetPage(name: Routers.createBasic, page: () => BasicPage()),
            GetPage(name: Routers.createVoice, page: () => OCVoicePage()),
            GetPage(name: Routers.editOC, page: () => EditAiPage()),
            GetPage(name: Routers.createAdvance, page: () => AdvancePage()),
            GetPage(name: Routers.createGen, page: () => GenPage()),
            GetPage(name: Routers.setting, page: () => AccountSettings()),
            // GetPage(name: Routers.myOC, page: () => MyCompanionView(), binding: ScenePlayBinding()),
            GetPage(name: Routers.rechargePremium, page: () => RechargePremiumView()),
            GetPage(name: Routers.rechargeCurrency, page: () => RechargeCurrencyView()),
            GetPage(
              name: Routers.createPostImage,
              page: () => const CreatePostImagePage(),
              binding: CreatePostImageBinding(),
            ),
            GetPage(
              name: Routers.createMoment,
              page: () => const CreateMomentViewPage(),
              binding: CreateMomentViewBinding(),
            ),
            GetPage(
              name: Routers.detailMoment,
              page: () => const MomentDetailViewPage(),
              binding: MomentDetailViewBinding(),
            ),
            GetPage(name: Routers.createCrowed, page: () => CreateCrowedPage(), binding: CreateCrowedBinding()),
            GetPage(name: Routers.crowedInfo, page: () => CrowedInfoView(), binding: CrowedInfoBinding()),
            GetPage(name: Routers.search, page: () => SearchView(), binding: SearchBinding()),
            GetPage(name: Routers.collections, page: () => CollectionsView()),
          ],
          routingCallback: (route) {
            Toast.dismiss();
          },
        );
      },
    );
  }
}
