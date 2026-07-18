# 南看台前端鉴权、路由与安全

## F05 写操作

`/contents/:id` 与 `/publish/post` 受认证守卫保护；40101/40102 沿用会话规则，403/网络失败不清 Token。发布不提交 authorId、官方状态或统计，仅当前用户匹配作者时显示删除。

> 版本：v0.2
> 当前阶段：F03
> 文档定位：会话、路由守卫和前端安全边界的唯一权威文档。
> 不负责：后端 BCrypt/JWT/Redis 内部实现或完整接口说明。

## F03 Token 边界

Flutter Access Token 使用 `flutter_secure_storage`，存储 key 集中定义；不保存密码、完整响应、JWT Secret 或 Refresh Token。后端当前没有 Refresh Token。Bearer 由统一请求头 provider 注入，Feature 不拼接 Authorization。

后续 App 启动时恢复 Token、调用权威会话接口并根据 `onboardingCompleted` 选择路由的设计仍保留，但不是 F02 实现范围。

## 路由守卫与错误副作用

业务 `40101` / `40102` 在会话恢复时清除本地 Token 并回登录；网络临时失败与 `40301` 保留 Token 并显示重试/权限错误。退出登录仅清除本地状态，不伪造服务端 logout。

路由状态为 bootstrapping、unauthenticated、authenticatedNeedsOnboarding、authenticatedReady、recoverable failure。公开路由仅 login/register；认证用户按 onboardingCompleted 进入 onboarding 或临时完成页，避免启动时闪烁和 redirect 循环。

后续 Flutter 守卫以认证状态与 onboarding 状态为输入并保证跳转幂等。管理后台除登录/错误页外默认需要认证且只允许 `ADMIN`。退出登录、并发 401 去重和安全路由栈替换都应由后续会话层实现。

## 安全边界

- 不打印完整 Token、密码、密钥或敏感响应；
- 环境变量模板只含本地占位值，真实 `.env` 与密钥不进入前端仓库；
- 前端不存在数据库凭据，不尝试还原服务端 JWT 或权限逻辑；
- 文件上传前校验类型和大小以改善体验，后端仍是最终校验方；
- 隐藏按钮不是权限控制，所有权限以后端判定为准；
- 外部 URL、富文本、文件名和错误消息按使用场景转义/校验，不执行服务端返回脚本。
# F04 主框架路由

`authenticatedReady` 的默认目标为 `/app/home`，`/app/home|data|messages|profile` 由有状态壳管理；`/search`、`/publish`、`/content/:id`、`/match/:id` 也是仅登录用户可达的占位路由。旧 `/authenticated` 仅保留重定向兼容，不再作为主入口。Onboarding 未完成仍只允许进入 `/onboarding`，未登录用户仍回到 `/login`，避免重定向环。

我的页调用既有 `AuthController.logout` 清理本地 Access Token，路由监听状态后返回登录。40101/40102 与 F03 相同触发会话失效处理，403 只显示无权访问而不清 Token。Feed 日志只记录未知 cardType，不输出 Token、请求体或完整 JSON。
