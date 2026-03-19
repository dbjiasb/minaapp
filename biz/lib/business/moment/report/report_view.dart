import 'package:biz/base/crypt/routes.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import '../../../base/crypt/copywriting.dart';
import '../../../base/crypt/security.dart';
import '../../../shared/app_theme.dart';
import '../report/report_logic.dart';

class ReportView extends StatefulWidget {
  final int targetId;
  final int type;

  const ReportView(this.targetId, this.type, {super.key});

  @override
  State<ReportView> createState() => _ReportViewState();
}

class _ReportViewState extends State<ReportView> {
  late final ReportLogic _logic = Get.put(ReportLogic());
  final TextEditingController _editingController = TextEditingController();
  bool _isLoading = true;
  late Map _reportData;

  @override
  void initState() {
    super.initState();
    _loadReportConfig();
  }

  Future<void> _loadReportConfig() async {
    setState(() => _isLoading = true);
    try {
      _reportData = await _logic.loadReportConfig();
    } finally {
      if (mounted) {
        setState(() => _isLoading = false);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(resizeToAvoidBottomInset: true, backgroundColor: Colors.transparent, body: Center(child: _buildView()));
  }

  Widget _buildView() {
    return UnconstrainedBox(constrainedAxis: Axis.horizontal, child: _buildContent());
  }

  Widget _buildContent() {
    if (_isLoading) {
      // 可以替换为你自己的加载组件
      return const Center(child: CircularProgressIndicator());
    }
    List reasons =_reportData[Security.security_reasons]??[];

    if ((reasons).isEmpty) {
      // 可以替换为你自己的空状态组件
      return Center(child: Text(Copywriting.security_no_report_reasons_available));
    }

    return _buildReportContent(reasons.cast<Map>());
  }

  Widget _buildReportContent(List<Map> reasons) {
    return SingleChildScrollView(
      child: Container(
        margin: const EdgeInsets.symmetric(horizontal: 48),
        padding: const EdgeInsets.all(24),
        decoration: const BoxDecoration(color: Color(0xFF12151C), borderRadius: BorderRadius.all(Radius.circular(16))),
        child: GetBuilder<ReportLogic>(
          builder: (logic) {
            return Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(Security.security_report.tr, style: TextStyle(color: Color(0xFFAAAAAA), fontFamily: Security.security_specialFont.tr, fontSize: 16)),
                const SizedBox(height: 6),
                ...reasons.map((e) => _buildCheckBox(e, logic)),
                const SizedBox(height: 6),
                TextField(
                  controller: _editingController,
                  decoration: InputDecoration(
                    filled: true,
                    labelStyle: const TextStyle(color: Colors.white, fontSize: 14),
                    hintText: Security.security_description.tr,
                    fillColor: Color(0xFFF5F5F5),
                    contentPadding: const EdgeInsets.symmetric(horizontal: 16),
                    hintStyle: const TextStyle(color: Color(0xFF999999), fontSize: 14),
                    enabledBorder: const OutlineInputBorder(
                      gapPadding: 0,
                      borderRadius: BorderRadius.all(Radius.circular(40)),
                      borderSide: BorderSide(color: Colors.transparent, style: BorderStyle.none, width: 1),
                    ),
                    focusedBorder: const OutlineInputBorder(
                      gapPadding: 0,
                      borderSide: BorderSide(color: Colors.transparent, width: 0),
                      borderRadius: BorderRadius.all(Radius.circular(40)),
                    ),
                  ),
                ).marginOnly(top: 10),
                _buildActionButtons(logic),
              ],
            );
          },
        ),
      ),
    );
  }

  Widget _buildCheckBox(Map reason, ReportLogic logic) {
    return Obx(
      () => InkWell(
        onTap: () {
          logic.updateReason(reason);
        },
        child: Row(
          children: [
            Radio.adaptive(
              activeColor: AppColors.primary,
              value: reason,
              groupValue: logic.currentReason.value,
              onChanged: (value) {
                if (value == null) return;
                logic.updateReason(value);
              },
            ),
            const SizedBox(width: 4),
            Text(reason[Security.security_desc] ?? "", style: const TextStyle(fontSize: 12, color: Colors.white)),
          ],
        ).marginOnly(top: 8),
      ),
    );
  }

  Widget _buildActionButtons(ReportLogic logic) {
    return Row(
      children: [
        Expanded(
          child: TextButton(
            onPressed: () {
              Get.back();
            },
            style: TextButton.styleFrom(
              backgroundColor: Color(0xFF12151C),
              side: BorderSide(color: Colors.white.withValues(alpha: .7), width: 1),
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(32)),
            ),
            child: Text(Security.security_cancel, style: TextStyle(color: Colors.white.withValues(alpha: .7), fontSize: 16, fontWeight: FontWeight.w700)),
          ),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: TextButton(
            onPressed: () {
              logic.report(widget.targetId, widget.type, _editingController.text);
            },
            style: TextButton.styleFrom(
              minimumSize: const Size(0, 0),
              backgroundColor: AppColors.primary,
              side: const BorderSide(color: Color(0xFFF96F88), width: 1),
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(32)),
            ),
            child: Text(Security.security_report, style: const TextStyle(color: Colors.white, fontSize: 16, fontWeight: FontWeight.w700)),
          ),
        ),
      ],
    ).marginOnly(top: 24);
  }
}
