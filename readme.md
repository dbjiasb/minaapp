# Miora · 弥语

AI 角色聊天、情感陪伴和互动剧场应用，基于 Flutter 构建。

品牌名称：Miora；中文名：弥语。品牌文案：每一次对话，都有故事发生。

- `biz`：共享业务与界面。
- `debug`：调试入口。
- `dis`：发布入口。
- `design/branding/miora-v2`：品牌设计源文件与生成提示词。

界面品牌常量位于 `biz/lib/shared/app_brand.dart`。原生品牌资源可在项目根目录通过 `python3 toolchain/branding/prepare_brand_assets.py` 重新输出。

原有包名、Bundle ID、签名、Firebase 配置、接口/CDN 路径、数据库名称及加密口令保留，以兼容现有安装、数据和后端服务。仓库目录仍为 `minaapp`。
