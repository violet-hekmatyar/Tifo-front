# F03 Flutter 认证与首次偏好执行报告

> 日期：2026-07-17  
> 前端仓库：`D:\Football-APP-Front`  
> 后端仓库（只读）：`D:\Football-APP`

## 1. 初始状态与回归

前端 `main` 初始 clean，HEAD `3a3261d feat: add frontend environment and network foundations`；F00/F01/F02 均已有独立提交。后端 `main` 初始 clean，HEAD `98ca87f feat: complete T12 comment hot ranking`。未执行 Git 写操作。

后端文档同步无缺失。F02 完整回归通过，输出 `F02 frontend network foundation check passed`。

## 2. 已读取内容与契约核验

已读取前端 README、00–12 主线文档、F02 报告；后端快照 05/06/07/11/12；并只读核对 Auth/Onboarding Controller、DTO、VO、Service、Security Filter/Config、Result/Exception、User Profile Controller、运行配置、pom 与 smoke-auth/smoke-onboarding。

真实契约：

- register 请求 username/phone/password，返回 UserInfoVO，不返回 Token；
- login 请求 username/password，返回 accessToken/tokenType/expiresIn/user；
- me 返回 id/username/nickname/avatarUrl/roleType/status/onboardingCompleted/mainTeamId；
- options 返回 recommendedTeams/hotTeams/recommendedPlayers/hotPlayers；
- preferences 要求 mainTeamId，球队/球员列表可空；后端自动加入主队并去重；
- 当前业务与鉴权失败使用 HTTP 200 统一包络，40101/40102/40103/40301 是业务 code；
- 只有 Access Token，没有 Refresh Token。

文档与实现未发现字段冲突；实现细节已登记 BACKEND_API_CHANGELOG。

## 3. 本地后端

初始 8080 未监听。F03 使用已有且未过期的 `target/south-stand-server.jar`，未修改源码、未重置数据库、未运行 reset-dev-db。首次启动在未加载本机 MySQL 容器凭据时 DB health 返回 50001，F03 自有进程被安全停止；修正脚本后仅把现有容器凭据加载到子进程内存，未打印或持久化，再次启动成功。

- 是否复用初始后端：否；
- 是否由 F03 启动：是；
- PID：10000；
- health/db/redis：全部 UP；
- metadata：`tmp/runtime/f03-backend/backend-start-metadata.json`；
- stdout/stderr：`tmp/runtime/f03-backend/backend.stdout.log` / `backend.stderr.log`；
- 当前保持常驻：是；
- 停止命令：`powershell -NoProfile -ExecutionPolicy Bypass -File .\scripts\windows\stop-local-backend-f03.ps1`。

ensure 的幂等调用会保留 F03 归属；stop 同时校验 metadata、PID 和 jar 命令行，不按端口杀进程。

## 4. Flutter 实现

新增 `flutter_secure_storage 10.3.1`。TokenStorage 抽象包含 secure 与测试内存实现，key 集中定义；只保存 Access Token，不保存密码、完整响应、JWT Secret 或虚假 Refresh Token。Bearer 由 F02 headers provider 统一注入。

Auth 状态机：bootstrapping → unauthenticated / authenticatedNeedsOnboarding / authenticatedReady / recoverable failure。冷启动有 Token 时调用 me；40101/40102 清 Token，网络失败与 40301 保留 Token。logout 仅清本地会话。

注册成功回填用户名并回登录；登录先保存 Token，再真实调用 me 校验；40103 明确提示且不重试。路由覆盖 bootstrap、login、register、onboarding、authenticated placeholder，并保留 404。

Onboarding 使用真实球队/球员，主队单选，球队/球员多选，ID 去重提交，成功后再次调用 me 复核。图片相对 URL 通过 Base URL 解析，空/失败使用占位。完成页只显示 F03 完成、非敏感用户信息、F04 待开发与退出按钮。

页面 → Controller → Repository → ApiClient；页面不访问 Dio 或 secure storage。Android 明文 HTTP 只在 debug manifest 开放，main/release 未开放。

## 5. 测试与真实联调

默认 Mock/Widget：29 项全部通过，覆盖登录成功/业务/网络/40103、防重复，注册、Token 保存、冷启动无/有效 Token、40101/40102 清 Token、网络/403 保留、路由、退出、options 成功/空/失败、主队必选、去重和提交成功。

真实 smoke 通过前端 AuthRepository/OnboardingRepository/ApiClient 路径：health、唯一用户注册、登录、Token 获取（未打印）、me、无 Token 40101、真实 options、preferences、完成状态复核及一次错误密码 40101。测试用户使用 `f03_` + 微秒时间戳后缀，密码运行时生成且不输出；数据库保留唯一测试用户，不做清理或重置。

## 6. 检查与产物

| 检查 | 结果 |
|---|---|
| `check-repo.ps1` | 通过：`Frontend repository base check passed` |
| `check-f02.ps1` | 通过 |
| `check-mobile-f03.ps1` | 通过：`F03 Flutter auth and onboarding check passed`（首次构建已生成 APK；缓存重跑 29 项测试与构建通过） |
| `smoke-mobile-auth-f03.ps1` | 通过：`F03 local backend auth onboarding smoke passed` |
| `check-f03.ps1` | 通过：`F03 frontend auth onboarding check passed` |

APK：`D:\Football-APP-Front\apps\mobile\build\app\outputs\flutter-apk\app-debug.apk`。iOS 未构建（Windows）。Vue 只做 F02 回归。

## 7. 安全、人工验收与风险

- 后端源码/配置/文档修改：否；
- 数据库重置：否；
- 真实 `.env` / keystore / 密钥文件：未创建；
- 完整 Token/密码输出或保存：否；
- Git add/commit/push/reset/clean：否；
- 模拟器人工视觉验收：未执行，不伪造；
- 未完成项：用户人工视觉验收；
- 风险：本地后端依赖现有 MySQL/Redis 容器；Windows 未验证 iOS；后端没有 Refresh Token，过期后必须重新登录。

最终聚合已通过，建议人工审阅差异后提交：

```text
feat: add mobile authentication and onboarding flow
```

下一步 F04：Flutter 主框架与首页卡片流，不在 F03 提前实现。
