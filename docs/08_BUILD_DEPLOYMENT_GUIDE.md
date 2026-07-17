# 南看台前端构建与部署指南

> 版本：v0.1
> 当前阶段：F01
> 文档定位：构建、产物、发布和回滚计划。
> 不负责：本机 SDK 安装说明或真实生产参数。

本机环境和界面预览详见 [12_LOCAL_DEVELOPMENT_ENVIRONMENT.md](12_LOCAL_DEVELOPMENT_ENVIRONMENT.md)。F01 只完成本地构建，未完成正式部署，未创建 Dockerfile、Nginx 正式配置或生产环境文件。

## Flutter

```powershell
cd D:\Football-APP-Front\apps\mobile
flutter pub get
flutter run -d <android-device-id>
flutter build apk --debug
```

`flutter run` 将应用安装并运行在 Android 模拟器/真机中，用于界面预览；`flutter build apk --debug` 只生成 APK，不显示界面。Windows 不执行 iOS build。

## Vue 管理后台

```powershell
cd D:\Football-APP-Front\apps\admin
npm ci
npm run dev
npm run build
```

浏览器使用 Vite dev server 预览；构建产物位于 `apps/admin/dist`。正式静态部署、域名、证书和回滚参数留待 F13。
