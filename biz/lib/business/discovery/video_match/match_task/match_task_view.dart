import 'package:biz/base/crypt/images.dart';
import 'package:biz/base/assets/image_view.dart';
// import 'package:jce/tudou/DailyTaskProcess.dart';
// import 'package:jce/tudou/ETaskFinishStatus.dart';
// import 'package:jce/tudou/ETaskType.dart';
// import 'package:jce/tudou/TaskAward.dart';
// import 'package:list/main/logic.dart';
// import 'package:main/main_page/controller.dart';
import 'package:biz/base/report/report_manager.dart';
import 'package:biz/core/util/cached_image.dart';
// import 'package:common/ui/gradient_text.dart';
import 'package:flutter/material.dart';
import 'package:flutter_easyloading/flutter_easyloading.dart';
import 'package:get/get.dart';

import '../../../../base/crypt/copywriting.dart';
import '../../../../base/crypt/security.dart';
import '../../services/match_service.dart';
import '../match_const.dart';

// import 'package:tasks/services/tasks_service.dart';
// import 'package:utils/gime_theme.dart';
//
// import '../services/match_service.dart';
// import 'package:utils/app_report.dart';

class MatchTaskView extends StatefulWidget {
  const MatchTaskView({super.key});

  @override
  State<MatchTaskView> createState() => _MatchTaskViewState();

  static showMatchTask() {
    ReportManager.sendEvent(Security.security_click_match_card_task, {});
    Get.bottomSheet(const MatchTaskView());
  }
}

class _MatchTaskViewState extends State<MatchTaskView> {
  @override
  Widget build(BuildContext context) {
    return Container(
      height: 438,
      decoration: const BoxDecoration(color: Color(0xFFF8F3FF), borderRadius: BorderRadius.only(topRight: Radius.circular(30), topLeft: Radius.circular(30))),
      child: Stack(
        children: [
          CachedImage(imageUrl: MatchRes.base + Images.security_ic_match_task_bg_webp, width: double.infinity, fit: BoxFit.fitHeight),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 24),
            child: Obx(() {
              return Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  ShaderMask(
                    shaderCallback: (Rect bounds) {
                      return const LinearGradient(
                        colors: [Color(0xFF8E3170), Color(0xFF300D4A), Color(0xFF300D4A)],
                        begin: Alignment.topLeft,
                        end: Alignment.bottomRight,
                      ).createShader(Rect.fromLTWH(0.0, 0.0, bounds.width, bounds.height));
                    },
                    blendMode: BlendMode.srcIn,
                    child: Text(Copywriting.security_complete_tasks_to_get_rewards, style: const TextStyle(fontSize: 19, fontWeight: FontWeight.bold)),
                  ),
                  const SizedBox(height: 20),
                  ...(MatchService.to.matchTaskCache[Security.security_childrenTaskProcesses] ?? []).map((e) => _buildTaskView(e)),
                  const Spacer(),
                  _buildButtonView(MatchService.to.matchTaskCache[Security.security_mainTaskProcesses] ?? {}),
                ],
              );
            }),
          ),
          Positioned(
            top: 16,
            right: 16,
            child: GestureDetector(
              onTap: () {
                Get.back();
              },
              child: ImageView(Images.security_ic_close_png, width: 24, height: 24),
            ),
          ),
        ],
      ),
    );
  }

  @override
  void initState() {
    ReportManager.sendEvent(Security.security_pv_match_card_task, {});
    MatchService.to.getMatchTaskProcess();
    super.initState();
  }

  String _getTaskIconByType(int taskType) {
    switch (taskType) {
      case 26:
        return Images.security_ic_match_task_chat_webp;
      case 27:
        return Images.security_ic_match_task_photo_webp;
      case 28:
        return Images.security_ic_match_task_hot_webp;
    }
    return Images.security_ic_match_task_chat_webp;
  }

  void _goTaskAction(int taskType) {
    Get.back();
    toRealTab();
  }

  Widget _buildTaskView(Map dailyTaskProcess) {
    bool notFinish = dailyTaskProcess[[Security.security_finishStatus]] == ETaskFinishStatus.NOT_FINISH;
    return GestureDetector(
      onTap: () {
        if (notFinish) {
          _goTaskAction(dailyTaskProcess[Security.security_task]?[Security.security_taskType] ?? 0);
        }
      },
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 14, horizontal: 12),
        margin: const EdgeInsets.only(bottom: 8),
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(12),
          gradient: const LinearGradient(begin: Alignment.centerLeft, end: Alignment.centerRight, colors: [Color(0xFFF6E7FE), Color(0xFFE7E2FF)]),
        ),
        child: Row(
          children: [
            Container(
              margin: const EdgeInsets.only(right: 12),
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(100)),
              child: CachedImage(
                imageUrl: MatchRes.base + _getTaskIconByType(dailyTaskProcess[Security.security_task]?[Security.security_taskType] ?? 0),
                width: 28,
                height: 28,
                fit: BoxFit.cover,
              ),
            ),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    dailyTaskProcess[Security.security_task]?[Security.security_taskName] ?? '',
                    style: const TextStyle(color: Color(0xFF080E1B), fontSize: 14, fontWeight: FontWeight.bold),
                  ),
                  Text(
                    "${dailyTaskProcess['process']}/${dailyTaskProcess[Security.security_task]?['total']}",
                    style: const TextStyle(color: Color(0xFFFF56BB), fontSize: 12),
                  ),
                ],
              ).marginOnly(right: 12),
            ),
            Container(
              width: 78,
              height: 36,
              alignment: Alignment.center,
              decoration: BoxDecoration(
                color: notFinish ? const Color(0xFF120204) : const Color(0xFF120204).withOpacity(0.5),
                borderRadius: BorderRadius.circular(100),
              ),
              child: Text(
                notFinish ? Security.security_go : Security.security_done,
                style: TextStyle(fontSize: 14, fontWeight: FontWeight.bold, color: notFinish ? Colors.white : Colors.white.withOpacity(0.5)),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildButtonView(Map mainTaskProcess) {
    return GestureDetector(
      onTap: () {
        if (mainTaskProcess[Security.security_finishStatus] == ETaskFinishStatus.HAS_FINISHED) {
          claim(mainTaskProcess);
        }
      },
      child: Opacity(
        opacity: mainTaskProcess[Security.security_finishStatus] == ETaskFinishStatus.HAS_FINISHED ? 1 : 0.5,
        child: Container(
          height: 56,
          width: double.infinity,
          alignment: Alignment.center,
          decoration: const BoxDecoration(
            gradient: LinearGradient(
              colors: [Color(0xFFFF56BB), Color(0xFF6B39FF)],
              // 渐变色数组
              begin: Alignment.centerLeft,
              // 渐变起始点
              end: Alignment.centerRight,
            ),
            borderRadius: BorderRadius.all(Radius.circular(16)),
          ),
          child: Text(
            mainTaskProcess[Security.security_finishStatus] == ETaskFinishStatus.NOT_FINISH
                ? 'In progress (${mainTaskProcess['process']}/${mainTaskProcess[Security.security_task]?['total']})'
                : (mainTaskProcess[Security.security_finishStatus] == ETaskFinishStatus.HAS_FINISHED ? Security.security_claim.tr : Security.security_rewarded),
            style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 16),
          ),
        ),
      ),
    );
  }

  void claim(Map taskProcess) {
    EasyLoading.show();
    // TaskService.to
    //     .claimTaskAward(taskProcess.task?.taskType ?? 0)
    //     .then((value) {
    //   MatchService.to.getMatchTaskProcess();
    //   EasyLoading.dismiss();
    //   Get.back();
    //   showRewardDialog(taskProcess.task?.award);
    // }).onError((error, stackTrace) {
    //   EasyLoading.showToast('FailedClaimed'.tr);
    //   EasyLoading.dismiss();
    // });
  }

  void showRewardDialog(Map? award) async {
    if (award == null) {
      return;
    }
    // await Alert.show(
    //     title: 'Rewards',
    //     contentWidget: Row(
    //       mainAxisAlignment: MainAxisAlignment.center,
    //       children: [
    //         Image.asset('assets/images/ic_property_free_call.webp',
    //             package: Security.security_app_common, width: 64, height: 64),
    //         Text('${award.count}',
    //             style: const TextStyle(
    //                 color: Color(0xFFFF56BB),
    //                 fontSize: 32,
    //                 fontWeight: FontWeight.w500))
    //       ],
    //     ),
    //     confirmButton: 'Okay');
  }

  void toRealTab() {
    try {
      // Get.find<MainController>().selectList();
      // Get.find<ListMainLogic>().selectRealTab();
    } catch (e) {}
  }
}
