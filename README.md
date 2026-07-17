# 南看台前端 / Tifo Frontend

南看台前端包含面向普通用户的 Flutter 原生移动 App，以及仅供内部管理员使用的 Vue 3 + TypeScript 管理后台。当前不建设面向用户的 H5、PWA 或小程序。

- 当前阶段：F03.1（Flutter 客户端视觉基线与认证流程视觉治理）
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

## F03 本地后端与客户端预览

```powershell
powershell -NoProfile -ExecutionPolicy Bypass -File .\scripts\windows\status-local-backend-f03.ps1
cd apps\mobile
flutter run -d Pixel_8_API_36 `
  --dart-define=APP_ENV=development `
  --dart-define=API_BASE_URL=http://10.0.2.2:8080
```

F03 已为 Flutter 接入本机真实后端的注册、登录、Access Token 安全存储、冷启动恢复、Bearer 注入、首次偏好选择和本地退出。Vue 管理后台登录尚未开始，留待 F08；当前完成页不是正式首页。

F03.1 在不改变认证、会话、路由和 Onboarding 业务契约的前提下，新增统一 Design Token、共享组件、稳定图片占位，并将首次设置整理为三步视觉流程。视觉规则见 [docs/13_CLIENT_UI_VISUAL_BASELINE.md](docs/13_CLIENT_UI_VISUAL_BASELINE.md)。F04 主框架与首页尚未开始。

后端状态管理入口为 `ensure-local-backend-f03.ps1`、`status-local-backend-f03.ps1` 和 `stop-local-backend-f03.ps1`。完整验收运行 `scripts/windows/check-f03.ps1`。
