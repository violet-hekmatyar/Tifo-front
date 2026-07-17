# 南看台本地开发环境与预览

> 版本：v0.1
> 当前阶段：F01
> 文档定位：本机 Flutter、Android、Node、模拟器和双端界面预览方式的唯一权威文档。
> 权威边界：不承担技术选型、业务需求、API 契约或生产部署配置。
> 最后验证日期：2026-07-17

## Windows 与基础工具

- Windows 11 家庭版中文版，版本 10.0.26200（25H2）；
- Git 2.54.0.windows.1；
- Node.js 24.17.0，npm 11.13.0。

## Flutter

- SDK：`D:\Flutter`，不放入项目仓库；
- Flutter 3.44.6 stable，revision `ee80f08bbf`；
- Dart 3.12.2 stable；DevTools 2.57.0；
- 命令解析到 `D:\Flutter\bin\flutter(.bat)` 与 `D:\Flutter\bin\dart(.bat)`。

Codex 不自动安装、升级或切换全局 SDK。若新进程找不到命令，先关闭并重新打开终端，再执行 `where.exe flutter` 与 `where.exe dart` 检查用户 PATH。

## Flutter 下载镜像

```text
PUB_HOSTED_URL=https://pub.flutter-io.cn
FLUTTER_STORAGE_BASE_URL=https://storage.flutter-io.cn
```

这些是本机依赖/资源下载配置，不是项目密钥。PowerShell 查看方式：

```powershell
$env:PUB_HOSTED_URL
$env:FLUTTER_STORAGE_BASE_URL
[Environment]::GetEnvironmentVariable('PUB_HOSTED_URL', 'User')
[Environment]::GetEnvironmentVariable('FLUTTER_STORAGE_BASE_URL', 'User')
```

项目脚本不会永久修改用户环境变量，镜像变化须人工确认。

## Android 工具链

- Android Studio：`C:\Program Files\Android\Android Studio`；
- Android SDK：`C:\Users\hekmatyar\AppData\Local\Android\Sdk`；
- SDK 36.0.0，Platform `android-36.1`，Build-Tools 36.0.0；
- Emulator 36.6.11.0；Platform-Tools 已安装，ADB 1.0.41 / 37.0.0；
- Command-line Tools：`cmdline-tools/latest`；
- JDK：`C:\Program Files\Android\Android Studio\jbr\bin\java`，OpenJDK 21.0.10；
- Android licenses：全部接受。

`flutter doctor -v` 的 Android toolchain 已通过。Chrome 与 Visual Studio 缺失仅影响 Flutter Web/Windows 桌面开发，本项目不开发这些平台，因此不是阻塞项，也不安装 Windows C++ 桌面工作负载。正式平台为 Android/iOS；Windows 负责 Android 开发与构建，不执行 iOS build。

## Android Emulator

本次检测到 AVD `Pixel_8_API_36`，emulator id 同为 `Pixel_8_API_36`，使用 Android 16 / API 36。AVD 已创建但未启动，`flutter devices` 当前未发现 Android connected device；视觉预览待用户启动模拟器后完成。AVD 镜像属于本机配置，不提交 Git。后续优先使用 Pixel 7/8、API 36 稳定 Google APIs 镜像，不使用 API 37 Preview。

## Flutter 界面预览

```powershell
flutter emulators
flutter emulators --launch Pixel_8_API_36
flutter devices
cd D:\Football-APP-Front\apps\mobile
flutter run -d <flutter-devices-显示的实际Android设备ID>
```

运行中：`r` 热重载，`R` 热重启，`q` 退出。真机替代方式为启用开发者选项与 USB 调试、连接设备、在 `flutter devices` 确认 device id 后执行 `flutter run -d <deviceId>`。

`flutter build apk --debug` 仅做构建验证，不显示界面；`flutter run` 才会安装并运行。模拟器适合日常 UI 开发，Android 真机用于最终交互、网络、图片、键盘和性能验证。不得使用 Windows 桌面或 Web 代替移动端视觉验收。人工至少确认“南看台”“Flutter mobile initialized”可见，且无红屏、溢出或启动异常。

## Vue 管理后台预览

```powershell
cd D:\Football-APP-Front\apps\admin
npm ci
npm run dev
```

使用 Vite 终端实际输出的本地 URL 在 Edge/Chrome 打开，按 `Ctrl+C` 停止。人工确认“南看台管理后台”“Vue admin initialized”、Element Plus 状态卡和 404 页面。`npm run build` 只生成 `dist`，不等于视觉验收。

## 常见问题

- Flutter 命令不可用：检查新终端中的用户 PATH 和 `D:\Flutter\bin`；
- pub.dev 无法访问：检查两个镜像变量，不在脚本中永久重写；
- Android SDK 未识别：核对目录，再人工检查 `flutter config --android-sdk`；
- cmdline-tools 缺失：在 Android Studio SDK Manager 安装稳定版本；
- License 未接受：人工执行 `flutter doctor --android-licenses`；
- 没有 Android 设备：先启动 AVD 或连接已开启 USB 调试的真机；
- 模拟器启动失败：检查 BIOS/UEFI 虚拟化、Windows Hypervisor Platform 与资源占用；
- Chrome/Visual Studio 警告：仅对应本项目不支持的 Web/Windows 桌面目标，可忽略；
- 不把删除 `D:\Flutter\bin\cache` 作为常规修复手段。

## 安全与维护

不记录 Token、密码、签名文件或私密配置，不提交 `local.properties`。路径、版本或 AVD 状态变化后更新本文档，且只记录已验证事实。完整依赖版本表见 [03_TECH_STACK.md](03_TECH_STACK.md)，构建与部署见 [08_BUILD_DEPLOYMENT_GUIDE.md](08_BUILD_DEPLOYMENT_GUIDE.md)。
