# Miora · 弥语 亮色品牌 v2

以圆润的 m 和对话尾巴组成品牌符号，使用暖黄色与深炭色；启动页使用暖白底色，与亮色 UI 保持一致。

## 设计源文件

- `logo-master.png`：1254 × 1254，无透明通道，完整方形画布；供商店与桌面图标适配。
- `splash-art.png`：970 × 1622，完整启动图视觉稿。
- `launch-lockup.png`：1150 × 1368，透明底图标与 Miora 字标组合；供原生启动页按固定逻辑尺寸居中显示。
- `prompts.json`：完整生成提示词。三个源文件均使用内置 image_gen 生成，平台尺寸用 sips 缩放。

原生启动页使用透明组合标志和 #F8F7F3 背景；完整视觉稿中的淡黄色底部氛围光保留在设计源文件中。使用居中组合标志，可以适配不同屏幕比例而不拉伸 Logo。

## 已接入

- `debug`、`dis` 的 Android 五档密度桌面图标。
- Android 12 以前的居中原生启动页；Android 12 及以上使用系统图标启动样式。
- 两个 iOS 入口的 1024 图标及 1x、2x、3x 启动资源。
- Flutter 登录入口、关于页面使用本地 `biz/assets/brand/miora-logo-v2.png`，不再从 CDN 加载旧 Logo。

原图标和旧启动图片保留在原路径，新配置指向 v2 文件。品牌更新同时应用于亮色、深色构建。

品牌更名使用内置 image_gen 替换启动视觉稿和透明启动组合图中的字标，沿用原有 m 对话符号和配色。更名提示词记录于 `prompts.json` 的 `rename` 字段。

Flutter 登录页与官方角色署名显示 Miora，关于页显示 Miora · 弥语；Android 默认应用名为 Miora，中文系统显示 Miora · 弥语；iOS 应用名为 Miora。团队和客服名称已同步到所有支持的语言。隐私政策及服务条款的本地 HTML 文件已更新，线上页面需要随发布同步上传。

包名、Bundle ID、签名、Firebase 配置、接口及远程资源路径、数据库名称、旧偏好设置键和解密口令沿用现有值；`Security.security_mina` 仅供旧数据与资源解密使用，界面使用 `AppBrand`。

## 重新输出平台资源

在项目根目录运行（macOS，需 sips）：

```sh
python3 toolchain/branding/prepare_brand_assets.py
```

该脚本从已确认的设计源文件输出尺寸，并更新 iOS 图标清单。设计内容变更请先更新源文件。

## 已做验证

Android aapt2 资源编译、两个 iOS LaunchScreen 的 ibtool 编译通过。iOS 商店图标为 1024 正方形且无 alpha；启动组合图保留透明通道。仍需在设备上检查冷启动和系统桌面图标，替换图标后可能需要重新安装以刷新系统缓存。
