# 南看台前端 / Tifo Frontend

南看台前端包含面向普通用户的 Flutter 原生移动 App，以及仅供内部管理员使用的 Vue 3 + TypeScript 管理后台。当前不建设面向用户的 H5、PWA 或小程序。

- 当前阶段：F01（双端最小可运行骨架）
- Flutter：`apps/mobile`
- Vue 管理后台：`apps/admin`
- 文档入口：[docs/00_DOCUMENT_MAP.md](docs/00_DOCUMENT_MAP.md)
- 完整结构树：[docs/04_FRONTEND_ARCHITECTURE.md](docs/04_FRONTEND_ARCHITECTURE.md)
- 本机环境与预览：[docs/12_LOCAL_DEVELOPMENT_ENVIRONMENT.md](docs/12_LOCAL_DEVELOPMENT_ENVIRONMENT.md)

## 日常运行

```powershell
cd D:\Football-APP-Front\apps\mobile
flutter devices
flutter run -d <android-device-id>

cd D:\Football-APP-Front\apps\admin
npm ci
npm run dev
```

## F01 验收

```powershell
powershell -ExecutionPolicy Bypass -File .\scripts\windows\check-f01.ps1
```

F01 仅提供基础路由、主题、状态和占位页面，尚未实现登录、首页、管理功能或后端请求。Base URL、Token、密码和密钥不得硬编码或提交；不使用 Web/Windows 桌面端替代 Flutter 移动端验收。
