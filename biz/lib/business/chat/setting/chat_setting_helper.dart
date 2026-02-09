import 'package:biz/base/crypt/copywriting.dart';
import 'package:biz/base/crypt/apis.dart';
import 'dart:ui';

import 'package:get/get.dart';
import 'package:biz/shared/toast/toast.dart';
import '../../../base/api_service/api_request.dart';
import '../../../base/api_service/api_response.dart';
import '../../../base/api_service/api_service.dart';
import '../../../base/crypt/security.dart';
import '../../../shared/alert.dart';
import '../chat_manager.dart';

class ChatSettingHelper {
  static void doReset({
    String userName = '',
    String sessionId = '',
    int tUid = 0,
  }) async {
    showConfirmAlert(
      "Reset $userName?",
      Copywriting.security_she_will_forget_conversation_history_with_you_,
      onConfirm: () async {
        Toast.loading();
        ApiRequest request = ApiRequest(Apis.security_resetAiModel,
          params: {
            Security.security_targetUid: tUid,
            Security.security_sessionId: sessionId,
          },
        );
        ApiResponse response = await ApiService.instance.sendRequest(request);
        if (response.isSuccess) {
          Toast.show(Copywriting.security_reset_Success_);
        } else {
          Toast.show(response.description);
        }
      },
    );
  }

  static void doClearHistory({String userName = "", VoidCallback? onConfirm}) {
    showConfirmAlert(
      'Clear history with "$userName"',
      'Are you sure to clear all history with "$userName" (including texts, images, videos...)? This action cannot be undone.',
      onConfirm: onConfirm,
    );
  }

  static Future<bool> deleteRemoteSession({
    String sessionId = '',
    int tUid = 0,
  }) async {
    ApiRequest request = ApiRequest(Apis.security_deleteSession,
      params: {
        Security.security_targetUid: tUid,
        Security.security_sessionId: sessionId,
      },
    );
    ApiResponse response = await ApiService.instance.sendRequest(request);
    if (response.isSuccess) {
      ChatManager.instance.messageHandler.deleteMessagesBySessionId(sessionId);
      return true;
    }
    return false;
  }
}
