# 南看台 Vue 管理后台

## F08 管理员登录与主框架

后台使用真实登录和 `/auth/me` 二次校验，只有 `roleType=ADMIN` 才将 Access Token 提交到 `sessionStorage` 并进入后台。刷新会恢复会话；40101/40102 清会话回登录，40301 保留 Token 并进入无权限页，网络失败保留 Token 且可重试。后端没有 refresh/logout，退出仅清本地会话。

正式路由为 `/login`、`/admin/dashboard|users|content|football|files`、`/403` 和 404。除工作台外均为 F08 范围说明，不展示假业务数据。完整验收运行 `scripts/windows/check-f08.ps1`，不会执行 Flutter 或旧阶段聚合脚本。

仅供内部管理员使用，不是面向普通用户的 H5。使用 Node 24.17.0、npm 11.13.0、Vue 3.5.40、TypeScript 6.0.3 和 Vite 8.1.5；包管理器固定为 npm。

F02 已在 F01 骨架上接入 Axios 1.18.1、`VITE_APP_ENV` / `VITE_API_BASE_URL`、统一响应/分页解析、拦截器与错误归一化。复制 `.env.example` 的字段到本机未跟踪环境文件后可配置开发地址；仓库不包含真实 `.env`。F08 在该单一 Axios 实例上完成认证副作用，不新增客户端。

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
