# F08 Vue 管理员认证与后台框架执行报告

> 日期：2026-07-19。人工浏览器验收未执行，不伪造结论。

## 契约与实现

- 登录：`POST /api/auth/login` 返回 accessToken、Bearer tokenType、expiresIn 和 user；随后 `GET /api/auth/me` 二次确认。
- 角色：真实字段 `roleType`，严格映射 ADMIN/USER；只有 ADMIN 持久化 Token。`/api/admin/**` 后端使用 hasRole(ADMIN)。
- Token：集中 sessionStorage；候选 Token 在 me 通过前仅在内存，不保存密码、完整响应或 Token 日志。后端无 refresh/logout。
- bootstrap：无 Token 回登录；ADMIN 恢复后台；USER 清 Token 进 403；401 清会话；网络错误保留 Token并提供重试。
- Axios：复用 F02 唯一实例；非空 Token 才注入 Bearer。401 并发单次处理；403 保留会话。
- Router：`/admin/**` meta 守卫、安全站内 redirect、子路由刷新、403、session error 与 404。
- 页面：正式登录页、可折叠 AdminLayout、Sidebar、Topbar、管理员菜单、退出、Dashboard 和四个统一模块占位；无假统计。

## 验证与边界

- F08 定向 Vitest：10 项通过。
- 最终 lint/type-check 通过；全量 Vitest 5 个文件、29 项全部通过；production build 成功并生成 `apps/admin/dist/index.html`。
- 真实 smoke 通过：管理员 login 与 `/auth/me` 均确认 ADMIN，无副作用 `/api/admin/health` 成功；普通 USER 调用同一管理员接口返回 40301，无 Token `/auth/me` 返回 40101。
- `check-f08.ps1` 最终输出 `F08 Vue admin authentication shell check passed`。
- 过程偏差：第一次最终链的 lint/type-check 与 29 项测试通过，但 production build 因 SessionErrorView 双语句模板表达式解析失败而停止；移入脚本函数后重跑通过。因此全量测试执行 2 次，production build 尝试 2 次（1 次失败、1 次成功）；真实管理员 smoke 只执行 1 次。
- 未运行 Flutter；未运行 F01–F07 聚合脚本；未修改后端；未重置数据库；未执行 Git 写操作。
- 前端无硬编码管理员凭据。真实 smoke 仅点引用后端现有 auth smoke 的 seed 管理员机制，并验证管理员 me、admin health 和 USER 403。

## 未完成与风险

- 未实现 F09 用户/内容管理、F10 足球维护、F11 文件管理；无真实 Dashboard 统计、Refresh Token、服务端 logout、SSO 或二次认证。
- 后端既有 smoke 机制自身包含 seed 管理员默认参数；前端没有复制凭据，但本机 seed 被改变时需要由后端 smoke 参数或安全环境重新配置。
- 浏览器刷新、响应式布局、控制台敏感信息与真实错误密码仍需人工复验。
- 建议提交信息：`feat: add Vue admin authentication and shell`。
