import 'package:biz/base/crypt/routes.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:biz/base/crypt/security.dart';
import 'package:biz/core/util/ui_util.dart';
import 'package:biz/shared/widget/keep_alive_wrapper.dart';

import '../../base/assets/image_path.dart';
import '../../base/assets/image_view.dart';
import '../../base/crypt/copywriting.dart';
import '../../base/router/router_names.dart';
import '../../shared/app_theme.dart';
import 'advance_page.dart';
import 'basic_page.dart';
import 'character_service.dart';

class EditAiPage extends StatefulWidget {
  late Map editInfo;

  EditAiPage();

  @override
  State<EditAiPage> createState() => _EditAiPageState();
}

class _EditAiPageState extends State<EditAiPage>
    with SingleTickerProviderStateMixin {
  late TabController _tabController;

  late int targetUid;
  BasicController baseController = Get.put(BasicController());
  AdvanceController advanceController = Get.put(AdvanceController());
  late Map roleConfig;
  late Map costInfo;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 2, vsync: this);
    targetUid = Get.arguments[Security.security_targetUid] ?? 0;
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  AppBar _buildAppBar() {
    return AppBar(
      toolbarHeight: 40,
      leading: InkWell(
        onTap: Get.back,
        child: Center(
          // padding: EdgeInsets.all(16),
          child: ImageView("back.png", fit: BoxFit.fill, width: 24, height: 24),
        ),
      ),
      backgroundColor: Colors.transparent,
      title: Text(
        Copywriting.security_edit_My_Character,
        style: TextStyle(color: Colors.white, fontSize: 16, fontWeight: FontWeight.bold),
      ),
    );
  }

  Widget _buildBody() {
    return SafeArea(
      bottom: false,
      child: UiUtils.buildFutureView<Map?>(
        CharacterService.instance.getEditRoleInfo(targetUid),
        (data, context) {
          if ((data ?? {}).isEmpty) {
            return UiUtils.buildCommonEmptyView();
          } else {
            initConfig(data!);
            return Column(
              children: [
                SizedBox(
                  width: 200.w,
                  child: TabBar(
                    overlayColor: WidgetStateProperty.all(Colors.transparent),
                    tabs: [
                      Tab(text: Security.security_basic),
                      Tab(text: Security.security_advance)
                    ],
                    controller: _tabController,
                    indicatorColor: AppColors.primary,
                    indicatorSize: TabBarIndicatorSize.label,
                    indicatorPadding: const EdgeInsets.only(bottom: 10),
                    labelColor: AppColors.primary,
                    unselectedLabelColor: Colors.white,
                    dividerColor: Colors.transparent,

                  ),
                ),
                SizedBox(height: 8),
                Expanded(
                  child: TabBarView(
                    controller: _tabController,
                    children: [
                      KeepAliveWrapper(child: BasicCore()),
                      KeepAliveWrapper(child: AdvanceCore()),
                    ],
                  ),
                ),
                SafeArea(
                  top: false,
                  child: _buildUpdateButton(),)
              ],
            );
          }
        },
      ),
    );
  }

  void initConfig(Map configs) {
    roleConfig = configs[Security.security_customRoleInfo];
    costInfo = configs[Security.security_modifyCostInfo]??{};
    baseController.loadCharacterInfo(roleConfig);
    advanceController.loadCharacterInfo(roleConfig);
  }

  @override
  Widget build(BuildContext context) {
    return DefaultTabController(
      length: 2,
      child: Scaffold(
        backgroundColor: AppColors.main,
        appBar: _buildAppBar(),
        body: _buildBody(),
      ),
    );
  }

  Widget _buildUpdateButton() {
    return Container(
      // color: SWColors.dark_bg,
      width: double.infinity,
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
      child: InkWell(
        onTap: () {
          Get.toNamed(Routers.createGen, arguments: {
            Security.security_customRoleInfo: roleConfig,
            Security.security_modifyCostInfo: costInfo
          });
        },
        child: Container(
          padding: const EdgeInsets.symmetric(vertical: 12),
          alignment: Alignment.center,
          decoration: BoxDecoration(
            color: AppColors.primary,
            borderRadius: BorderRadius.circular(12),
          ),
          child: Text(
            Security.security_Save,
            style: TextStyle(
              color: Colors.white,
              fontSize: 14,
              fontWeight: FontWeight.w700,
            ),
          ),
        ),
      ),
    );
  }

  Map getCharacterInfo() {
    return {};
  }
}
