# 南看台前端构建与部署指南

## F06 修正验收

`check-f06.ps1` 同时检查认证详情白名单、root Navigator、集中排序、分页 Footer、真实路由测试和增强 football smoke，再复跑 F05、全量测试与 Debug APK。真实数据少不影响分页自动测试，生产运行不增加 fixture。

## F06 构建与预览

运行 `scripts/windows/check-f06.ps1` 完成 F05 全量回归、Flutter format/analyze/test、真实 football smoke 和 Android Debug APK。模拟器仍使用 `API_BASE_URL=http://10.0.2.2:8080`；`flutter run` 中 `r` 热重载、`R` 热重启、`d` 断开并保留 App、`q` 结束。检查脚本不启动模拟器、不长期运行 App、不执行 iOS build。

F05 沿用 Android `10.0.2.2` 配置；相册选择需要系统照片权限。iOS 已声明 `NSPhotoLibraryUsageDescription`，Windows 验收不执行 iOS build。

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

## F05 修复验收

运行 `scripts/windows/check-f05.ps1` 会覆盖 F04/F03.1 回归、发布返回路由、Feed 刷新协调、集中分区、全量测试、静态分析、真实发布与三 tab Feed 核验，以及 Android Debug APK 构建。最终成功标记保持 `F05 Flutter content publish interaction check passed`。

## F06 最终收口构建

`check-f06.ps1` 聚合历史回归、F06 移动端验证、文字审计验证、真实 football smoke 和后端状态；`check-f06-text-data-audit.ps1` 可独立检查报告/JSON、球队整卡入口、全量测试、analyze 与 Debug APK。APK 仍输出到 `apps/mobile/build/app/outputs/flutter-apk/app-debug.apk`。联网核验不参与构建产物运行时，也不包含视觉/媒体资源。
