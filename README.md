# 南看台前端 / Tifo Frontend

南看台前端包含面向普通用户的 Flutter 原生移动 App，以及仅供内部管理员使用的 Vue 3 + TypeScript 管理后台。当前不建设面向用户的 H5、PWA 或小程序。

- 当前阶段：F02（双端环境与网络基础层）
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

## F02 验收

```powershell
powershell -NoProfile -ExecutionPolicy Bypass -File .\scripts\windows\check-f02.ps1
```

F02 在 F01 骨架上增加双端集中式环境配置、统一响应/分页解析、Dio/Axios 客户端和可替换请求头扩展点。当前仍未实现登录、Token 存储、401/403 跳转、首页或管理业务；自动验收全部使用 Mock，不访问真实后端。Base URL、Token、密码和密钥不得硬编码或提交。
