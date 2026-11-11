import 'package:biz/business/purchase/recharge_premium_view.dart';
import 'package:biz/shared/app_theme.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:get/get.dart';

class PreviewPremiumController extends RechargePremiumViewController {
  var backCalls = 0;

  @override
  void initIap() {}

  @override
  Future<void> loadSubscriptionData() async {}

  @override
  void navigateBack() {
    backCalls++;
    super.navigateBack();
  }
}

void main() {
  tearDown(() => Get.reset());

  for (final state in ['loading', 'error', 'loaded']) {
    testWidgets('premium back button is reachable over $state content', (
      tester,
    ) async {
      tester.view.physicalSize = const Size(375, 812);
      tester.view.devicePixelRatio = 1;
      addTearDown(tester.view.resetPhysicalSize);
      addTearDown(tester.view.resetDevicePixelRatio);
      final controller = PreviewPremiumController()
        ..isLoading.value = state == 'loading'
        ..isError.value = state == 'error';
      Get.put<RechargePremiumViewController>(controller);
      await tester.pumpWidget(
        GetMaterialApp(
          theme: AppTheme.theme,
          home: const Scaffold(body: Text('account')),
        ),
      );
      Get.to<void>(() => const RechargePremiumView());
      await tester.pump();
      await tester.pump(const Duration(seconds: 1));
      expect(find.byTooltip('Back').hitTestable(), findsOneWidget);
      await tester.tap(find.byTooltip('Back'));
      await tester.pump();
      await tester.pump(const Duration(seconds: 1));
      expect(controller.backCalls, 1);
      expect(find.text('account'), findsOneWidget);
      expect(find.byType(RechargePremiumView), findsNothing);
      expect(tester.takeException(), isNull);
      await tester.pumpWidget(const SizedBox.shrink());
    });
  }
}
