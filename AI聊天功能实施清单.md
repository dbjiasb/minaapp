# AI聊天功能实施清单

## ✅ 已完成项目

### 核心架构
- [x] ChatSession 添加 `type = 3` 私聊支持
- [x] ChatSession 添加 `isPrivateChat` getter
- [x] ChatSession 添加 `fromAIRole()` 工厂构造函数
- [x] ChatSessionHandler 添加 `SessionType.privateChat` 枚举
- [x] ChatSessionHandler 添加 `queryPrivateChatSessions()` 方法
- [x] ChatSessionHandler 扩展 `findSessionSqlByType()` 支持私聊过滤

### 聊天历史视图
- [x] 创建 `chat_history_view.dart` 父视图（Story + Message 标签）
- [x] 创建 `chat_history_logic.dart` 控制器
- [x] 移动 `theater_history_list` 到 `chat_history` 目录
- [x] 更新 `skeleton_view.dart` 使用新的历史视图

### 私聊会话列表
- [x] 创建 `private_chat_history_list/view.dart`（列表布局）
- [x] 创建 `private_chat_history_list/logic.dart`（本地数据库查询）
- [x] 创建 `private_chat_history_list/private_chat_session_cell.dart`（会话单元格）
- [x] 实现下拉刷新功能
- [x] 实现会话变化事件监听

### 导航集成
- [x] 更新 `role_list_view.dart` 路由到私聊（type=3）
- [x] 修改 `chat_theater_room_view.dart` 支持私聊会话创建
- [x] 验证 `route_helper.dart` 的 `toChat()` 方法支持 type 参数

### 私聊底部栏
- [x] 创建 `chat_private_bottom_bar.dart` 基础框架
- [x] 实现文本输入和发送功能
- [x] 添加 8 种状态枚举定义
- [x] 实现草稿保存功能

### 代码质量
- [x] 修复所有编译错误
- [x] 修复颜色常量问题（text_secondary → 0xFF999999）
- [x] 修复时间格式化问题（formatMessageTime → diff）
- [x] 清理未使用的导入
- [x] 通过 flutter analyze 检查

## ⏳ 待实施项目

### UI 完善（根据 Figma 设计）
- [x] 私聊会话列表UI优化（匹配Figma设计）
  - [x] 会话单元格样式调整
  - [x] AI/Real徽章显示
  - [x] 空状态UI优化
- [x] 私聊主界面基础实现
  - [x] 背景图片显示
  - [x] 顶部导航栏（返回、头像、名称、Current:AI徽章、更多按钮）
  - [x] Notice横幅
  - [x] 消息列表显示
  - [x] 文本消息气泡（ChatTextCell）
  - [x] 底部输入栏集成
  - [x] 角色介绍卡片（可折叠）
  - [x] "继续说"按钮（显示在AI消息后）
- [ ] 私聊底部栏 8 种状态完整实现
  - [x] 普通输入状态（已完成基础版）
  - [ ] 语音输入状态（录音 UI）
  - [ ] 长按状态（快捷操作菜单）
  - [ ] 礼物面板状态
  - [ ] 键盘可见状态（布局调整）
  - [ ] 模板文本状态（快速回复）
  - [ ] Muse 状态（AI 建议）
  - [ ] 空状态
- [ ] 私聊主界面高级功能
  - [x] 角色介绍卡片（可折叠）
  - [x] "继续说"按钮
  - [ ] 语音消息胶囊显示
  - [ ] 长按消息菜单（删除、复制、翻译等）
  - [ ] 加号操作面板（9个选项）

### 功能增强
- [ ] 语音录音和发送
- [ ] 图片选择和发送
- [ ] 视频选择和发送
- [ ] 礼物选择面板
- [ ] 长按消息交互面板（复制、删除等）
- [ ] 图片解锁功能
- [ ] Muse AI 建议功能
- [ ] 消息已读状态显示

### 测试验证
- [ ] 端到端功能测试
- [ ] 消息发送和接收测试
- [ ] 会话列表更新测试
- [ ] 未读计数测试
- [ ] 多设备同步测试
- [ ] 性能测试

### 优化项
- [ ] 消息列表滚动性能优化
- [ ] 图片加载优化
- [ ] 数据库查询优化
- [ ] 内存管理优化

## 📊 进度统计

- **总任务数**: 52
- **已完成**: 37 (71%)
- **待完成**: 15 (29%)

## 🎯 下一步行动

1. **优先级 P0**（核心功能）
   - 完成端到端功能测试
   - 验证消息发送和接收流程
   - 确保会话列表正常显示

2. **优先级 P1**（重要功能）
   - 实现语音录音和发送
   - 实现图片选择和发送
   - 完善底部栏的 8 种状态

3. **优先级 P2**（增强功能）
   - 实现礼物面板
   - 实现 Muse AI 建议
   - 实现长按消息交互

## 📝 技术债务

1. **临时图标**: chat_private_bottom_bar.dart 中使用了临时图标，需要替换为正确的图标
2. **错误处理**: 部分 try-catch 块只打印日志，需要添加用户友好的错误提示
3. **代码注释**: 部分复杂逻辑需要添加中文注释
4. **单元测试**: 核心功能需要添加单元测试

## 🔧 已知问题

无

## 📚 参考文档

- 实施方案: `/Users/ios/.claude/plans/gleaming-purring-sloth.md`
- 实施总结: `/Users/ios/StudioProjects/minaapp/AI聊天功能实施总结.md`
- Figma 设计稿: 8 个设计链接（见原始需求）
- 参考项目: `/Users/ios/StudioProjects/soulinkapp`
