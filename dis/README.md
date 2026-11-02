# Android 发布

运行 `./build_aab_dis.sh`，或通过 `FLUTTER_BIN` 指定 Flutter 3.38+ 的可执行文件。
发布包位于 `build/app/outputs/bundle/release/app-release.aab`，混淆符号保存在
`sybol_adr_<版本号>`，应与每次发布的包一起留存。

发布仅支持 ARM64，与 `defaultConfig` 原定配置一致。Flutter 3.38 会在 build type
注入 ABI 过滤器，因此也必须在 build type 显式覆盖；仅设置 `defaultConfig`
仍会打入 x86_64。当前腾讯 SDK 的 x86_64 库存在 4 KB LOAD 对齐，不能恢复该架构，
除非先升级并验证对应 SDK。

图片和视频通过系统选择器读取，不声明整个相册的读取权限。应用清单通过
`tools:node="remove"` 防止依赖重新带入媒体及存储权限。

构建脚本会自动运行 `toolchain/verify_android_release.py`，检查最终 AAB 中所有
原生库的 ABI、每个 ELF LOAD 段的 16 KB 对齐，以及最终清单中的媒体/存储权限。
AGP 8.10 与 NDK r28 保持不变；Google Play 生成 APK 时还需要 16 KB ZIP 对齐。

重新发布前，在 16 KB 模式的 Android 设备上回归登录、选择图片/视频、裁剪、
音视频通话及数据库读写。详见 [Android 官方说明](https://developer.android.com/guide/practices/page-sizes)。
