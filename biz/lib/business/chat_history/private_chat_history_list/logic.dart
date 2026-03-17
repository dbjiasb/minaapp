import 'package:get/get.dart';
import 'package:biz/business/chat/chat_session.dart';
import 'package:biz/business/chat/chat_session_handler.dart';
import 'package:biz/business/chat/chat_manager.dart';
import 'package:biz/base/event_center/event_center.dart';
import 'package:pull_to_refresh/pull_to_refresh.dart';

class PrivateChatHistoryListLogic extends GetxController {
  final RxList<ChatSession> dataList = <ChatSession>[].obs;
  final RxBool isLoading = true.obs;
  final RefreshController refreshController = RefreshController(initialRefresh: false);

  @override
  void onInit() {
    super.onInit();
    loadData();

    // 监听会话变化事件
    EventCenter.instance.addListener(kEventCenterDidChangeSession, (event) {
      loadData();
    });
    EventCenter.instance.addListener(kEventCenterDidDeleteSession, (event) {
      loadData();
    });
  }

  @override
  void onClose() {
    refreshController.dispose();
    super.onClose();
  }

  Future<void> loadData() async {
    try {
      isLoading.value = true;
      final sessions = await ChatSessionHandler().queryPrivateChatSessions();
      dataList.value = sessions;
    } catch (e) {
      print('加载私聊会话列表失败: $e');
    } finally {
      isLoading.value = false;
    }
  }

  void onRefresh() async {
    await loadData();
    refreshController.refreshCompleted();
  }

  Future<bool> deleteSession(ChatSession session) async {
    try {
      // 删除数据库中的会话
      await ChatSessionHandler().deleteSessionById(session.id);
      // 删除消息
      await ChatManager.instance.messageHandler.deleteMessagesBySessionId(session.id);
      // 从列表中移除
      dataList.remove(session);
      return true;
    } catch (e) {
      print('删除会话失败: $e');
      return false;
    }
  }
}
