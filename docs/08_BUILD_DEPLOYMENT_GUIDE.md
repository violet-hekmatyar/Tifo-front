# 南看台前端构建与部署指南

> 版本：v0.1
> 当前阶段：F03
> 文档定位：构建、产物、发布和回滚计划。
> 不负责：本机 SDK 安装说明或真实生产参数。

本机环境和界面预览详见 [12_LOCAL_DEVELOPMENT_ENVIRONMENT.md](12_LOCAL_DEVELOPMENT_ENVIRONMENT.md)。F01 只完成本地构建，未完成正式部署，未创建 Dockerfile、Nginx 正式配置或生产环境文件。

```powershell
powershell -NoProfile -ExecutionPolicy Bypass -File .\scripts\windows\ensure-local-backend-f03.ps1
powershell -NoProfile -ExecutionPolicy Bypass -File .\scripts\windows\status-local-backend-f03.ps1
powershell -NoProfile -ExecutionPolicy Bypass -File .\scripts\windows\stop-local-backend-f03.ps1
```

## Flutter

```powershell
cd D:\Football-APP-Front\apps\mobile
flutter pub get
flutter run -d Pixel_8_API_36 `
  --dart-define=APP_ENV=development `
  --dart-define=API_BASE_URL=http://10.0.2.2:8080
flutter build apk --debug
```

`flutter run` 将应用安装并运行在 Android 模拟器/真机中，用于界面预览；`flutter build apk --debug` 只生成 APK，不显示界面。Windows 不执行 iOS build。本地明文 HTTP 仅由 debug manifest 开放；main/release 未全局开放，正式环境必须使用 HTTPS。

## Vue 管理后台

```powershell
cd D:\Football-APP-Front\apps\admin
npm ci
$env:VITE_APP_ENV='development'
$env:VITE_API_BASE_URL='http://localhost:8080'
npm run dev
npm run build
```

浏览器使用 Vite dev server 预览；构建产物位于 `apps/admin/dist`。环境值仅为本地示例，不写入仓库真实 `.env`。正式静态部署、域名、证书和回滚参数留待 F13。
# F04 本机预览

先在仓库根目录运行 `ensure-local-backend-f03.ps1`，再用 `adb devices` 复用已有模拟器；无设备时冷启动 `Pixel_8_API_36`。在 `apps/mobile` 运行 `flutter run -d <device-id> --dart-define=APP_ENV=development --dart-define=API_BASE_URL=http://10.0.2.2:8080`。`flutter build apk` 只生成产物，不会启动 App；结束调试使用 `q`，模拟器是否关闭由开发者决定。

F04 Debug APK 由 `check-mobile-f04.ps1` 生成到 `apps/mobile/build/app/outputs/flutter-apk/app-debug.apk`。Windows 验收不执行 iOS 构建，也不创建 Web 或桌面平台。
