# 亮色 UI 全面检查清单

本次从所有入口和共享状态检查，不再将通话、匹配、创作、充值等页面排除在亮色版本之外。默认 `LIGHT_UI=true`，所有页面画布、表单、卡片、系统栏和弹层使用语义颜色。照片、视频、角色立绘保留原图；直接叠在媒体上的遮罩和文字使用专门的 `mediaScrim`、`onMedia`，不作为页面底色。

## 覆盖范围

- 登录入口、邮箱登录与验证码。
- Discovery：外层、请求中、空列表、失败提示、角色信息卡。
- 首页：分类、角色、剧场、筛选、搜索、创建入口。
- Moment：列表、详情、评论、发布、角色选择、生成图片、举报。
- 聊天：普通、私聊、群聊、剧场、气泡、输入、生成状态、记录、相册、消息菜单、模型、图片和视频生成、礼物及授权弹窗。
- 通话与匹配：呼叫、连接、通话控件、匹配扫描、结果、任务和试用提示。
- AI 模式：我的模式、商店、翻转卡片、介绍、购买提示；剧情列表和剧情播放的加载状态、说明和选项。
- 创建中心：基础资料、高级属性、声音、生成、编辑、确认弹层。
- 群组：创建、信息、成员、设置。
- 个人资料：封面与浅色资料区、相册、动态、关注、收藏、我的伙伴。
- 充值与会员：加载、失败、产品卡片、选中价格、订阅与法律链接。
- 图片查看、视频查看、内置网页、返回按钮、余额、Toast、共享标题栏、弹窗、底部面板、加载、空状态与错误状态。

## 验证口径

静态检查覆盖 134 个 UI 文件、35 个命名路由和 50 个 Scaffold。检查脚本拦截旧颜色别名、硬编码深色页面/输入背景、固定亮色状态栏图标、以及误用背景色的文字/图标。媒体图片和后台内容本身不作为配色扫描对象。

组件测试覆盖共享异步组件的加载、空白、错误、成功状态，系统栏与全局组件默认色，以及消息正文/旁白/译文和卡片的大字号布局。全套 `biz` 测试与静态分析见下方命令。命名路由表表示代码覆盖；依赖账号、网络、相机、音视频和购买的完整业务流程仍需设备验收，不等同于逐条完成端到端测试。

```sh
python3 toolchain/ui_audit/check_light_surfaces.py
cd biz
flutter test --no-pub
flutter analyze --no-pub
```

## 本次结果

- 全套 `biz` 测试：40 项通过。
- `LIGHT_UI=false` 的主题、异步状态、卡片和聊天组件：15 项通过。
- 全量 Flutter 静态分析：0 个 error；仓库仍有已有 lint 提示。
- 源码配色检查：134 个 UI 文件、35 个命名路由、50 个 Scaffold，0 个命中项。
- 当前 iPhone 16 / iOS 18.5 模拟器已热重载，目视检查登录入口和邮箱表单，修正登录按钮同色问题。当前为未登录状态，其余依赖账号的业务页没有冒充逐页完成真机验收。

## 命名路由

| 入口 | 配色检查 |
| --- | --- |
| `Routers.login` | 已纳入全局主题与源码检查 |
| `Routers.root` | 已纳入全局主题与源码检查 |
| `Routers.chat` | 已纳入全局主题与源码检查 |
| `Routers.chatHistory` | 已纳入全局主题与源码检查 |
| `Routers.chatTheater` | 已纳入全局主题与源码检查 |
| `Routers.home` | 已纳入全局主题与源码检查 |
| `Routers.webView` | 已纳入全局主题与源码检查 |
| `Routers.loginChannel` | 已纳入全局主题与源码检查 |
| `Routers.imageBrowser` | 已纳入全局主题与源码检查 |
| `Routers.editMe` | 已纳入全局主题与源码检查 |
| `Routers.person` | 已纳入全局主题与源码检查 |
| `Routers.videoPlayer` | 已纳入全局主题与源码检查 |
| `Routers.crowedInfo` | 已纳入全局主题与源码检查 |
| `Routers.call` | 已纳入全局主题与源码检查 |
| `Routers.aiCall` | 已纳入全局主题与源码检查 |
| `Routers.modeStore` | 已纳入全局主题与源码检查 |
| `Routers.modeList` | 已纳入全局主题与源码检查 |
| `Routers.datingList` | 已纳入全局主题与源码检查 |
| `Routers.datingGame` | 已纳入全局主题与源码检查 |
| `Routers.createBasic` | 已纳入全局主题与源码检查 |
| `Routers.createVoice` | 已纳入全局主题与源码检查 |
| `Routers.editOC` | 已纳入全局主题与源码检查 |
| `Routers.createAdvance` | 已纳入全局主题与源码检查 |
| `Routers.createGen` | 已纳入全局主题与源码检查 |
| `Routers.setting` | 已纳入全局主题与源码检查 |
| `Routers.myOC` | 已纳入全局主题与源码检查 |
| `Routers.rechargePremium` | 已纳入全局主题与源码检查 |
| `Routers.rechargeCurrency` | 已纳入全局主题与源码检查 |
| `Routers.createPostImage` | 已纳入全局主题与源码检查 |
| `Routers.createMoment` | 已纳入全局主题与源码检查 |
| `Routers.detailMoment` | 已纳入全局主题与源码检查 |
| `Routers.createCrowed` | 已纳入全局主题与源码检查 |
| `Routers.search` | 已纳入全局主题与源码检查 |
| `Routers.collections` | 已纳入全局主题与源码检查 |
| `Routers.matchScan` | 已纳入全局主题与源码检查 |

## UI 源码清单

| 文件 | Scaffold | AppBar |
| --- | ---: | ---: |
| `biz/lib/app/root_view.dart` | 0 | 0 |
| `biz/lib/app/skeleton_view.dart` | 1 | 0 |
| `biz/lib/base/ads/ad_unlock_button.dart` | 0 | 0 |
| `biz/lib/base/assets/image_view.dart` | 0 | 0 |
| `biz/lib/base/privacy/ai_consent_service.dart` | 0 | 0 |
| `biz/lib/base/router/route_helper.dart` | 0 | 0 |
| `biz/lib/base/ui/anim_scale_image.dart` | 0 | 0 |
| `biz/lib/base/ui/lazy_indexed_stack.dart` | 0 | 0 |
| `biz/lib/base/ui/overlay_popup.dart` | 0 | 0 |
| `biz/lib/base/ui/timer_count_down.dart` | 0 | 0 |
| `biz/lib/base/ui/user_card_view.dart` | 0 | 0 |
| `biz/lib/base/webview/web_view.dart` | 1 | 1 |
| `biz/lib/business/account/about_view.dart` | 1 | 1 |
| `biz/lib/business/account/account_view.dart` | 1 | 1 |
| `biz/lib/business/account/collections_view.dart` | 1 | 1 |
| `biz/lib/business/account/companion_view.dart` | 1 | 1 |
| `biz/lib/business/account/edit_my_info_view.dart` | 1 | 1 |
| `biz/lib/business/account/my_group.dart` | 0 | 0 |
| `biz/lib/business/account/settings.dart` | 1 | 1 |
| `biz/lib/business/chat/ai_mode/my_mode/view.dart` | 1 | 1 |
| `biz/lib/business/chat/ai_mode/store/view.dart` | 1 | 1 |
| `biz/lib/business/chat/ai_mode/widget/ai_mode_card.dart` | 0 | 0 |
| `biz/lib/business/chat/ai_mode/widget/ai_mode_popup.dart` | 1 | 0 |
| `biz/lib/business/chat/ai_mode/widget/aimode_intro.dart` | 0 | 0 |
| `biz/lib/business/chat/ai_mode/widget/mode_widget.dart` | 0 | 0 |
| `biz/lib/business/chat/call/ai_call_view.dart` | 1 | 0 |
| `biz/lib/business/chat/call/av_engine.dart` | 0 | 0 |
| `biz/lib/business/chat/call/call_view.dart` | 1 | 0 |
| `biz/lib/business/chat/chat_record/chat_category_view.dart` | 0 | 0 |
| `biz/lib/business/chat/chat_record/chat_history_image_select_view.dart` | 1 | 1 |
| `biz/lib/business/chat/chat_record/chat_record_view.dart` | 1 | 1 |
| `biz/lib/business/chat/chat_room/chat_bottom_bar.dart` | 0 | 0 |
| `biz/lib/business/chat/chat_room/chat_continue_button.dart` | 0 | 0 |
| `biz/lib/business/chat/chat_room/chat_introduction_card.dart` | 0 | 0 |
| `biz/lib/business/chat/chat_room/chat_muse_view.dart` | 0 | 0 |
| `biz/lib/business/chat/chat_room/chat_private_bottom_bar.dart` | 0 | 0 |
| `biz/lib/business/chat/chat_room/chat_private_room_view.dart` | 1 | 0 |
| `biz/lib/business/chat/chat_room/chat_room_view.dart` | 1 | 0 |
| `biz/lib/business/chat/chat_room/chat_theater_bottom_bar.dart` | 0 | 0 |
| `biz/lib/business/chat/chat_room/chat_theater_room_view.dart` | 1 | 0 |
| `biz/lib/business/chat/chat_room/level_up_pop_up.dart` | 0 | 0 |
| `biz/lib/business/chat/chat_room/sidebar.dart` | 0 | 0 |
| `biz/lib/business/chat/chat_room_cells/chat_anchor_album_message.dart` | 0 | 0 |
| `biz/lib/business/chat/chat_room_cells/chat_audio_message.dart` | 0 | 0 |
| `biz/lib/business/chat/chat_room_cells/chat_call_cell.dart` | 0 | 0 |
| `biz/lib/business/chat/chat_room_cells/chat_cell.dart` | 0 | 0 |
| `biz/lib/business/chat/chat_room_cells/chat_generating_message.dart` | 0 | 0 |
| `biz/lib/business/chat/chat_room_cells/chat_gift_cell.dart` | 0 | 0 |
| `biz/lib/business/chat/chat_room_cells/chat_image_message.dart` | 0 | 0 |
| `biz/lib/business/chat/chat_room_cells/chat_system_message.dart` | 0 | 0 |
| `biz/lib/business/chat/chat_room_cells/chat_text_cell.dart` | 0 | 0 |
| `biz/lib/business/chat/chat_room_cells/chat_theater_brief_message.dart` | 0 | 0 |
| `biz/lib/business/chat/chat_room_cells/chat_time_message.dart` | 0 | 0 |
| `biz/lib/business/chat/chat_room_cells/chat_tip_message.dart` | 0 | 0 |
| `biz/lib/business/chat/chat_room_cells/chat_video_message.dart` | 0 | 0 |
| `biz/lib/business/chat/create_image/create_image_panel.dart` | 0 | 0 |
| `biz/lib/business/chat/generate_video/generate_video_panel.dart` | 0 | 0 |
| `biz/lib/business/chat/gift/gift_panel.dart` | 0 | 0 |
| `biz/lib/business/chat/script/scene_list/view.dart` | 1 | 1 |
| `biz/lib/business/chat/script/scene_play/logic.dart` | 0 | 0 |
| `biz/lib/business/chat/script/scene_play/view.dart` | 1 | 1 |
| `biz/lib/business/chat/script/widgets/animated_view.dart` | 0 | 0 |
| `biz/lib/business/chat/script/widgets/gradient_bound_painter.dart` | 0 | 0 |
| `biz/lib/business/chat/setting/chat_model_view.dart` | 0 | 0 |
| `biz/lib/business/chat/setting/message_option_view.dart` | 0 | 0 |
| `biz/lib/business/chat/setting/message_setting.dart` | 1 | 1 |
| `biz/lib/business/chat_history/chat_history_view.dart` | 1 | 1 |
| `biz/lib/business/chat_history/private_chat_history_list/private_chat_session_cell.dart` | 0 | 0 |
| `biz/lib/business/chat_history/private_chat_history_list/view.dart` | 0 | 0 |
| `biz/lib/business/chat_history/theater_history_list/view.dart` | 1 | 1 |
| `biz/lib/business/create_center/advance_page.dart` | 1 | 1 |
| `biz/lib/business/create_center/basic_page.dart` | 1 | 1 |
| `biz/lib/business/create_center/character_service.dart` | 0 | 0 |
| `biz/lib/business/create_center/create_oc_dialog.dart` | 0 | 0 |
| `biz/lib/business/create_center/create_oc_rv_dialog.dart` | 0 | 0 |
| `biz/lib/business/create_center/edit_oc_page.dart` | 1 | 1 |
| `biz/lib/business/create_center/gen_page.dart` | 1 | 0 |
| `biz/lib/business/create_center/voice_page.dart` | 1 | 0 |
| `biz/lib/business/crowd/create_crowed_page.dart` | 1 | 1 |
| `biz/lib/business/crowd/crowd_utils.dart` | 0 | 0 |
| `biz/lib/business/crowd/info/view.dart` | 1 | 1 |
| `biz/lib/business/discovery/discovery_view.dart` | 1 | 1 |
| `biz/lib/business/discovery/explore_item_view.dart` | 0 | 0 |
| `biz/lib/business/discovery/explore_view.dart` | 0 | 0 |
| `biz/lib/business/discovery/swipe_explore_view.dart` | 0 | 0 |
| `biz/lib/business/discovery/video_match/free_card_use_tips.dart` | 0 | 0 |
| `biz/lib/business/discovery/video_match/match_scan/match_scan_result.dart` | 1 | 1 |
| `biz/lib/business/discovery/video_match/match_scan/match_scan_view.dart` | 1 | 1 |
| `biz/lib/business/discovery/video_match/match_task/match_task_view.dart` | 0 | 0 |
| `biz/lib/business/discovery/video_match/video_match_view.dart` | 1 | 0 |
| `biz/lib/business/home_page_lists/category_tabs_widget.dart` | 0 | 0 |
| `biz/lib/business/home_page_lists/filter_view.dart` | 0 | 0 |
| `biz/lib/business/home_page_lists/home_page.dart` | 1 | 1 |
| `biz/lib/business/home_page_lists/list_item.dart` | 0 | 0 |
| `biz/lib/business/home_page_lists/role_card_widget.dart` | 0 | 0 |
| `biz/lib/business/home_page_lists/role_list_view.dart` | 0 | 0 |
| `biz/lib/business/moment/create_moment_view/create_moment_view_view.dart` | 1 | 1 |
| `biz/lib/business/moment/create_moment_view/post_as_page.dart` | 0 | 0 |
| `biz/lib/business/moment/create_moment_view/reorder_res_grid_view.dart` | 0 | 0 |
| `biz/lib/business/moment/create_post_image/create_post_image_view.dart` | 1 | 1 |
| `biz/lib/business/moment/moment_detail_view/comment_list_view.dart` | 0 | 0 |
| `biz/lib/business/moment/moment_detail_view/moment_detail_view_view.dart` | 1 | 1 |
| `biz/lib/business/moment/moment_list_view/moment_item_view.dart` | 0 | 0 |
| `biz/lib/business/moment/moment_list_view/moment_list_view_view.dart` | 1 | 0 |
| `biz/lib/business/moment/report/report_view.dart` | 1 | 0 |
| `biz/lib/business/purchase/recharge_currency_view.dart` | 1 | 1 |
| `biz/lib/business/purchase/recharge_premium_view.dart` | 1 | 0 |
| `biz/lib/business/search/view.dart` | 1 | 1 |
| `biz/lib/business/theater/theater_list/view.dart` | 1 | 1 |
| `biz/lib/business/user_page/person_view.dart` | 2 | 1 |
| `biz/lib/business/user_page/photo_view.dart` | 0 | 0 |
| `biz/lib/core/account/create_account.dart` | 1 | 1 |
| `biz/lib/core/account/login_channel.dart` | 1 | 1 |
| `biz/lib/core/report/report_helper.dart` | 0 | 0 |
| `biz/lib/core/report/report_view.dart` | 0 | 0 |
| `biz/lib/core/util/cached_image.dart` | 0 | 0 |
| `biz/lib/core/util/ui_util.dart` | 0 | 1 |
| `biz/lib/shared/alert.dart` | 0 | 0 |
| `biz/lib/shared/common_widget.dart` | 0 | 2 |
| `biz/lib/shared/dialog.dart` | 0 | 0 |
| `biz/lib/shared/rv_helper.dart` | 0 | 0 |
| `biz/lib/shared/sheet.dart` | 0 | 0 |
| `biz/lib/shared/toast/easy_toast_adapter.dart` | 0 | 0 |
| `biz/lib/shared/widget/app_widgets.dart` | 0 | 0 |
| `biz/lib/shared/widget/avatar_view.dart` | 0 | 0 |
| `biz/lib/shared/widget/balance_view.dart` | 0 | 0 |
| `biz/lib/shared/widget/character_card.dart` | 0 | 0 |
| `biz/lib/shared/widget/image_viewer.dart` | 1 | 1 |
| `biz/lib/shared/widget/keep_alive_wrapper.dart` | 0 | 0 |
| `biz/lib/shared/widget/list_status_view.dart` | 0 | 0 |
| `biz/lib/shared/widget/thinking_animated_view.dart` | 0 | 0 |
| `biz/lib/shared/widget/title_bar.dart` | 0 | 0 |
| `biz/lib/shared/widget/video_file_view.dart` | 0 | 0 |
| `biz/lib/shared/widget/video_player_view.dart` | 1 | 1 |
