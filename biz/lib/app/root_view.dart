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

import '../business/chat/chat_room/chat_theater_room_view.dart';
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
            GetPage(name: Routers.chatTheater, page: () => ChatTheaterRoomView()),
            GetPage(name: Routers.home, page: () => HomePageView()),
            GetPage(name: Routers.webView, page: () => WebView()),
            GetPage(name: Routers.loginChannel, page: () => LoginChannelView()),
            GetPage(name: Routers.imageBrowser, page: () => ImageViewer()),
            // GetPage(name: Routers.editMe, page: () => EditMyInfoPage()),
            GetPage(name: Routers.videoPlayer, page: () => VideoPlayerView()),
          ],
          routingCallback: (route) {
            Toast.dismiss();
          },
        );
      },
    );
  }
}
