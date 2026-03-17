# CLAUDE.md

This file provides guidance to Claude Code (claude.ai/code) when working with code in this repository.

## 项目概述

这是一个采用多模块架构的 Flutter 应用，包含以下模块：
- **biz**: 核心业务逻辑包，包含所有应用功能
- **external_modules**: 第三方依赖和自定义 Flutter 包
- **debug**: 调试构建变体（引用 biz 包）
- **dis**: 发布/分发构建变体（引用 biz 包）

`debug` 和 `dis` 都是轻量级的包装器，它们导入并调用 `biz` 包中的 `startApp()`。所有实际的应用代码都在 `biz` 中。

## 架构说明

### 模块结构
```
biz/lib/
├── app/              # 根视图和骨架页面
├── base/             # 基础层（API、数据库、文件管理、路由等）
├── business/         # 业务功能模块（账号、聊天、首页、剧场等）
├── core/             # 核心工具（账号服务、用户管理、上报）
└── shared/           # 共享 UI 组件和工具
```

### 核心技术栈
- **状态管理**: GetX (get: 4.7.2)
- **数据库**: sqflite_sqlcipher（加密数据库）
- **网络请求**: Dio 5.9.0
- **存储**: get_storage、flutter_secure_storage（钥匙串）
- **多媒体**: audioplayers、cached_video_player_plus、image_picker
- **数据分析**: Adjust SDK、自定义上报系统

### 应用启动流程
应用通过 `biz/lib/main.dart:startApp()` 初始化，依次设置：
1. 日志系统（AppLog）
2. 偏好设置（Preferences）
3. 设备工具（DeviceUtil）
4. 应用管理器（AppManager）
5. 数据库（DataCenter）
6. 文件管理器（FileManager）
7. 上报、事件中心、推送服务、账号服务、聊天管理器

## 构建命令

### 调试构建（测试/内部）
```bash
cd debug
flutter clean
flutter pub get
flutter build apk --release --dart-define=buildType=debug --no-tree-shake-icons
```

自动化脚本：`toolchain/build_app/build_apk_test.sh`
- 自动递增构建号
- 上传到腾讯云 COS
- 发送飞书通知

### 正式构建（发布）
```bash
cd dis
flutter clean
flutter pub get

# Android AAB
flutter build appbundle --release --obfuscate --split-debug-info=./sybol_adr_<version>

# iOS
flutter build ios --release --obfuscate --split-debug-info=./sybol_ios_<version>
```

自动化脚本：
- `dis/build_aab_dis.sh` - Android 正式包
- `dis/build_ios_dis.sh` - iOS 正式包
- `dis/build_ios_upload.sh` - iOS 构建并上传

### 测试
```bash
cd biz
flutter test
```

## 开发流程

### 添加依赖
将依赖添加到 `external_modules/pubspec.yaml`，而不是单独的应用模块。`biz` 包依赖 `external_modules`，`debug` 和 `dis` 依赖 `biz`。

### 图标管理
- 调试图标：`debug/android/app/src/main/res/mipmap-*/ic_launcher.png`
- 正式图标：`dis/android/app/src/main/res/mipmap-*/ic_launcher.png`
- iOS 图标：通过 Xcode 资源目录管理

### 构建变体
- 调试构建使用 `--dart-define=buildType=debug`
- 正式构建使用混淆 `--obfuscate --split-debug-info`

## 业务模块详解

### 1. 账号系统 (business/account)
- **账号管理**: 支持 Email、Apple、Google 三种登录方式
- **用户信息**: 头像、昵称、性别、个人简介等
- **账号服务**: `AccountService` 单例管理登录状态、Token、用户信息
- **功能页面**:
  - 账号主页 (`account_view.dart`)
  - 编辑个人信息 (`edit_my_info_view.dart`)
  - 关于页面 (`about_view.dart`)

### 2. 聊天系统 (business/chat)
- **核心管理器**:
  - `ChatManager`: 聊天总控，管理消息同步、会话切换
  - `ChatSessionHandler`: 会话管理（创建、更新、删除会话）
  - `ChatMessageHandler`: 消息处理（发送、接收、存储）
  - `ChatVoiceManager`: 语音消息管理
  - `PersonManager`: 用户收藏/关注管理
- **消息类型**: 文本、语音、系统消息、礼物、剧场简报等
- **聊天室**:
  - 剧场聊天室 (`chat_theater_room_view.dart`)
  - Muse 聊天视图 (`chat_muse_view.dart`)
- **实时通信**: 通过 WebSocket 推送服务接收消息

### 3. 首页系统 (business/home_page_lists)
- **首页视图**: Tab 切换式主页，支持多个角色列表
- **角色管理**: `RoleManager` 管理 AI 角色、剧本角色、真人角色等
- **角色类型**:
  - AI 角色 (ai)
  - 剧本角色 (script)
  - 真人角色 (real)
  - 自定义 AI (custom_ai)
  - 角色扮演 (role_play)
  - UGC 内容 (ugc)
  - 约会模式 (dating)
  - 写实风格 (realistic)
  - 动漫风格 (anime)

### 4. 剧场系统 (business/theater)
- **剧场列表**: 推荐剧场场景列表 (`theater_list`)
- **历史记录**: 剧场历史浏览记录 (`theater_history_list`)
- **分页加载**: 支持下拉刷新和上拉加载更多

## 基础设施层 (base/)

### API 服务 (base/api_service)
- `ApiService`: 单例网络请求服务，基于 Dio
- `ApiRequest`: 请求封装
- `ApiResponse`: 响应封装
- `ApiConfig`: API 配置管理

### 数据库 (base/database)
- `DataCenter`: 加密 SQLite 数据库管理（sqflite_sqlcipher）
- 存储聊天消息、会话、用户信息等

### 推送服务 (base/push_service)
- `PushService`: WebSocket 长连接推送服务
- 支持心跳保活、断线重连
- 消息类型：聊天消息、系统通知、踢下线等

### 路由管理 (base/router)
- `RouteHelper`: 路由跳转辅助类
- `RouterNames`: 路由名称常量
- 使用 GetX 路由系统

### 事件中心 (base/event_center)
- `EventCenter`: 应用内事件总线
- 关键事件：登录/登出、消息接收、进入/退出聊天室等

### 文件管理 (base/file_manager)
- `FileManager`: 文件存储管理
- 处理图片、音频、视频等多媒体文件

### 数据上报 (base/report)
- `ReportManager`: Adjust SDK 集成
- 事件追踪、归因分析

### 加密模块 (base/crypt)
- `security.dart`: 安全相关常量和加密字符串
- `apis.dart`: API 端点定义
- `copywriting.dart`: 文案常量
- `constants.dart`: 应用常量

## 核心工具层 (core/)

### 用户管理 (core/user_manager)
- `UserManager`: 用户信息缓存和管理
- `UserProfileInfo`: 用户详细资料

### 工具类 (core/util)
- `log_util.dart`: 日志工具
- `device_util.dart`: 设备信息获取
- `audio_manager.dart`: 音频播放管理
- `permission_util.dart`: 权限请求
- `file_upload.dart`: 文件上传
- `cached_image.dart`: 图片缓存
- `calendar_helper.dart`: 日历辅助
- `string_ext.dart`: 字符串扩展

## 应用架构

### 主要页面流程
1. **启动**: `RootView` → 检查登录状态
2. **未登录**: `LoginChannelView` → 选择登录方式 → `CreateAccountView`
3. **已登录**: `SkeletonView` (底部导航) → 包含首页、消息、我的等 Tab
4. **聊天**: 从首页选择角色 → 进入 `ChatTheaterRoomView`

### 状态管理
- 使用 GetX 进行状态管理
- 每个页面通常有对应的 Controller (logic.dart)
- 使用 Obx/GetBuilder 实现响应式更新

### 数据流
1. **网络数据**: ApiService → ApiResponse → 业务逻辑 → UI
2. **本地数据**: DataCenter/Preferences → 业务逻辑 → UI
3. **实时消息**: PushService → EventCenter → ChatManager → UI

## 重要说明

- 项目使用 Flutter SDK 3.35.7，dart SDK ^3.7.2
- 构建脚本需要 Python 3 和 PyYAML 来管理版本号
- Android 构建使用加密 SQLite（sqflite_sqlcipher）
- iOS 使用 flutter_secure_storage 访问钥匙串
- 所有业务逻辑必须放在 `biz` 包中，不要放在 `debug` 或 `dis` 中
- 代码中大量使用 `Security.security_*` 常量，这些是混淆后的字符串，用于保护敏感信息，新开发的功能不需要自动加密字符串，开发人员会手动加密
- 图片无需放在ImagePath里面
- 下拉刷新和上拉加载更多使用pull_to_refresh插件
- 总结文档都用中文命名
- Plan mode时使用中文
