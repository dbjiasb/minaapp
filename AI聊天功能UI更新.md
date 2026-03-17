# AI聊天功能UI更新

## 更新日期
2026-03-13

## 更新内容

### 1. 私聊会话列表UI优化

根据Figma设计稿 (node-id=0:1959) 更新了私聊会话列表的样式：

#### 1.1 会话单元格样式调整
- **文件**: `biz/lib/business/chat_history/private_chat_history_list/private_chat_session_cell.dart`
- **更改**:
  - 头像尺寸从 48.w 调整为 44.w，圆角从 24.w 调整为 22.w
  - 名称字体大小从 16.sp 调整为 14.sp，字重改为 bold
  - 添加账号类型徽章显示（AI/Real）
    - AI徽章：紫色渐变 (#556AEB → #B635F4)，带边框
    - Real徽章：粉橙渐变 (#EB55DD → #F38D45)，带边框
  - 最后消息文本颜色从 #999999 调整为 #A19C9A
  - 最后消息字体大小从 14.sp 调整为 12.sp
  - 时间文本颜色从 #999999 调整为 #A19C9A
  - 时间字体大小从 12.sp 调整为 10.sp
  - 未读徽章颜色从 #F84652 调整为 #F0443E
  - 未读徽章圆角从 10.w 调整为 7.w
  - 单元格内边距从 12.w 调整为 10.w

#### 1.2 账号类型徽章逻辑
```dart
Widget _buildAccountTypeBadge() {
  if (session.accountType == 1 || session.accountType == 3 || session.accountType == 4) {
    // AI badge (accountType: 1=AI, 3=AI Plus, 4=自定义AI)
    return AI徽章;
  } else if (session.accountType == 0) {
    // Real badge (accountType: 0=真人)
    return Real徽章;
  }
  return const SizedBox.shrink();
}
```

#### 1.3 空状态UI优化
- **文件**: `biz/lib/business/chat_history/private_chat_history_list/view.dart`
- **更改**:
  - 移除文本提示
  - 添加圆形图标容器（120.w × 120.w）
  - 使用半透明白色背景 (opacity: 0.1)
  - 显示收件箱图标 (Icons.inbox_outlined)，尺寸 60.w，透明度 0.3

### 2. Figma设计稿分析

已获取以下设计稿的详细信息：

1. **消息会话列表** (node-id=0:1959)
   - 显示会话列表，包含头像、名称、AI/Real徽章、最后消息、时间、未读数
   - 顶部显示 "Message" 标题
   - 底部导航栏

2. **消息会话空列表** (node-id=0:1946)
   - 显示空状态图标（盒子图标）
   - 居中显示

3. **私聊主界面** (node-id=0:1885)
   - 背景图片 + 深色遮罩
   - 顶部栏：返回按钮、头像、名称、"Current:AI"徽章、更多按钮
   - 提示横幅："Notice: Everything AI says is made up"
   - 可折叠的角色介绍卡片
   - 消息气泡（左侧AI，右侧用户）
   - 语音消息胶囊（显示时长）
   - AI消息后显示"继续说"按钮
   - 底部输入栏：语音按钮、文本输入框、提示按钮、加号按钮

4. **语音输入状态** (node-id=0:1192)
   - 底部显示 "Hold to talk" 按钮
   - 左侧键盘图标，右侧加号按钮

## 技术细节

### 颜色规范
- AI徽章渐变：`LinearGradient(colors: [Color(0xFF556AEB), Color(0xFFB635F4)])`
- AI徽章边框：`Color(0xFFAFB2FF).withOpacity(0.6)`
- Real徽章渐变：`LinearGradient(colors: [Color(0xFFEB55DD), Color(0xFFF38D45)])`
- Real徽章边框：`Color(0xFFFDBAA2).withOpacity(0.6)`
- 次要文本颜色：`Color(0xFFA19C9A)`
- 未读徽章颜色：`Color(0xFFF0443E)`

### 尺寸规范
- 会话头像：44.w × 44.w，圆角 22.w
- 名称字体：14.sp，bold
- 最后消息字体：12.sp
- 时间字体：10.sp
- 徽章字体：12.sp，w600
- 徽章圆角：8.w
- 徽章内边距：horizontal 6.w, vertical 2.w

## 验证状态

- ✅ 代码编译通过（0 errors）
- ✅ 会话列表样式更新完成
- ✅ 账号类型徽章显示逻辑实现
- ✅ 空状态UI优化完成
- ⏳ 待运行应用验证视觉效果

## 下一步工作

1. **私聊主界面实现**（基于 node-id=0:1885）
   - 背景图片处理
   - 顶部导航栏
   - 提示横幅
   - 角色介绍卡片（可折叠）
   - 消息气泡样式
   - 语音消息胶囊
   - "继续说"按钮

2. **底部输入栏完善**（基于 node-id=0:1885 和 0:1192）
   - 普通输入状态
   - 语音输入状态（Hold to talk）
   - 其他6种状态

3. **其他Figma设计稿实现**
   - 语音录音UI (node-id=0:1106)
   - 释放语音UI (node-id=0:1011)
   - 长按消息面板 (node-id=0:1765)
   - 加号操作面板 (node-id=0:1474)
   - 礼物面板 (node-id=0:1274)
   - AI快速回复 (node-id=0:1397)
   - 图片解锁状态 (node-id=0:1610)
   - 删除消息UI (node-id=0:1696)

## 参考资料

- Figma设计稿: https://www.figma.com/design/kH3LOCC3WQTI0aIjPEz0tm/
- 实施清单: `/Users/ios/StudioProjects/minaapp/AI聊天功能实施清单.md`
- 实施总结: `/Users/ios/StudioProjects/minaapp/AI聊天功能实施总结.md`
