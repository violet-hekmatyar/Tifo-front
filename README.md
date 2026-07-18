# 南看台前端 / Tifo Frontend

南看台前端包含面向普通用户的 Flutter 原生移动 App，以及仅供内部管理员使用的 Vue 3 + TypeScript 管理后台。当前不建设面向用户的 H5、PWA 或小程序。

- 当前阶段：F04（Flutter 正式主框架与首页真实卡片流）
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

F03 已为 Flutter 接入本机真实后端的注册、登录、Access Token 安全存储、冷启动恢复、Bearer 注入、首次偏好选择和本地退出。F04 已将认证完成入口替换为正式四栏主框架，并通过真实 Feed 接口提供首页混合卡片流。Vue 管理后台登录尚未开始，留待 F08。

F03.1 建立的 Design Token、共享组件和稳定图片占位继续作为首页视觉基础。F04 支持推荐/资讯/关注、关注球队、下拉刷新、分页、内容卡片、比赛卡片和未知卡片降级；搜索、发布、内容详情、比赛详情及数据/消息/我的完整业务仍是明确占位，不伪造业务数据。

后端状态管理入口为 `ensure-local-backend-f03.ps1`、`status-local-backend-f03.ps1` 和 `stop-local-backend-f03.ps1`。F04 移动端检查、真实 Feed smoke 与完整验收分别运行 `check-mobile-f04.ps1`、`smoke-mobile-feed-f04.ps1` 和 `check-f04.ps1`。
