# 南看台 Vue 管理后台

仅供内部管理员使用，不是面向普通用户的 H5。使用 Node 24.17.0、npm 11.13.0、Vue 3.5.40、TypeScript 6.0.3 和 Vite 8.1.5；包管理器固定为 npm。

F02 已在 F01 骨架上接入 Axios 1.18.1、`VITE_APP_ENV` / `VITE_API_BASE_URL`、统一响应/分页解析、拦截器与错误归一化。复制 `.env.example` 的字段到本机未跟踪环境文件后可配置开发地址；仓库不包含真实 `.env`。当前不实现管理员登录、Token、401/403 跳转或任何管理业务。

```powershell
npm ci
npm run dev
npm run lint
npm run type-check
npm run test:unit -- --run
npm run build
npm run preview
```

`npm run dev` 输出的实际本地 URL 用于浏览器预览，按 `Ctrl+C` 停止。

F02 自动测试使用 `axios-mock-adapter`，不依赖后端在线。完整验收：

```powershell
powershell -NoProfile -ExecutionPolicy Bypass -File ..\..\scripts\windows\check-admin-f02.ps1
```
