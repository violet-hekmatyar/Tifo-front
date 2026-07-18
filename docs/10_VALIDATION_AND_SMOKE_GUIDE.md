# 南看台前端验证与 Smoke 指南

## F06 人工阻塞回归

新增真实 `createAppRouter` Widget 回归，覆盖数据页卡片进入 root MatchDetailPage、详情逐层球队/球员跳转、非法 ID 不回首页；排序纯函数覆盖分组、升降序、稳定性、空时间和不按比分推断；多页 Widget 覆盖滚动加载、失败 Footer、点击重试、去重与到底。真实 smoke 从列表提取 matchId/teamId，并在事件含 playerId 时查询该球员。

## F06 检查链

- `check-mobile-f06.ps1`：核对 football 分层、真实路由与占位移除，执行 pub get、format、analyze、默认 Mock/Widget 全量测试和 Android Debug APK；成功输出 `F06 Flutter football data and detail check passed`。
- `smoke-mobile-football-f06.ps1`：ensure/status 后执行独立 Flutter Repository/ApiClient 真实联赛、比赛、球队、球队赛程、球员、事件与图片 URL 测试；只创建唯一登录用户，不写 football 数据、不重置数据库；成功输出 `F06 local backend football data smoke passed`。
- `check-f06.ps1`：执行 repo、F05 全量回归、ensure、移动端 F06、真实 smoke、最终 status 与文档检查；成功输出 `F06 Flutter football data details check passed`。

自动检查不代表 Pixel 8、140% 字体、图片失败和 Android 返回键的人工视觉验收完成。

## F05 检查链

`check-mobile-f05.ps1` 验证格式/analyze/测试/APK；`smoke-mobile-content-f05.ps1` 跑真实详情、上传、发布、互动与评论生命周期；`check-f05.ps1` 先回归 F04。后端无用户帖子删除接口，smoke 保留唯一帖子及绑定媒体，不重置数据库。

> 版本：v0.1
> 当前阶段：F03.1
> 文档定位：验证命令与 smoke 计划的唯一权威文档。
> 不负责：任务路线或本机安装教程。

## F01 自动验收

| 脚本 | 覆盖范围 | 成功输出 |
|---|---|---|
| `check-repo.ps1` | 阶段无关的目录、文档、Git 与敏感产物检查 | `Frontend repository base check passed` |
| `check-mobile-f01.ps1` | Flutter 环境、Android toolchain、格式、analyze、test、APK | `F01 Flutter mobile check passed` |
| `check-admin-f01.ps1` | Node engine、npm ci、lint、类型、测试、build | `F01 Vue admin check passed` |
| `check-f01.ps1` | 按顺序聚合以上检查 | `F01 frontend skeleton check passed` |

```powershell
powershell -ExecutionPolicy Bypass -File .\scripts\windows\check-f01.ps1
```

Windows 不执行 iOS build。APK 构建成功不等于视觉预览完成；Android 模拟器/真机和 Vue 浏览器视觉观察不放入自动脚本，操作见 [12_LOCAL_DEVELOPMENT_ENVIRONMENT.md](12_LOCAL_DEVELOPMENT_ENVIRONMENT.md)。F01 不调用后端，也不进行登录、首页或管理业务 smoke。

`flutter doctor` 中 Chrome 与 Visual Studio 缺失分别只影响 Flutter Web 和 Windows 桌面端，对本项目 Android/iOS 范围非阻塞。GitHub Network resources 偶发超时属于网络诊断提示；只要 Android toolchain、依赖解析、测试和 APK 构建成功，不应误判为 Android 构建失败。

## F02 自动验收

| 脚本 | 覆盖范围 | 成功输出 |
|---|---|---|
| `check-mobile-f02.ps1` | Dio 文件/依赖、格式、analyze、Mock 测试、Android Debug APK | `F02 Flutter network foundation check passed` |
| `check-admin-f02.ps1` | Axios/配置/`.env.example`、真实 `.env` 跟踪检查、lint、类型、Mock 测试、build | `F02 Vue network foundation check passed` |
| `check-f02.ps1` | 依次运行 `check-repo`、完整 F01 回归和双端 F02 检查 | `F02 frontend network foundation check passed` |

```powershell
powershell -NoProfile -ExecutionPolicy Bypass -File .\scripts\windows\check-f02.ps1
```

F02 单元测试全部使用 mock adapter，不访问真实后端，也不启动 dev server 或模拟器。F01 必须在聚合脚本中完整回归；失败项存在时不得标记 F02 完成。

## F03 验收

- `check-mobile-f03.ps1`：格式、analyze、29 项默认 Mock/Widget 测试与带本地 Debug Base URL 的 APK；
- `smoke-mobile-auth-f03.ps1`：ensure 后端并运行独立 `test_local_backend` 真实注册/登录/onboarding；
- `check-f03.ps1`：完整 F02 回归、后端健康、F03 客户端、真实 smoke 与最终状态。

```powershell
powershell -NoProfile -ExecutionPolicy Bypass -File .\scripts\windows\check-f03.ps1
```

真实 smoke 创建唯一命名用户但不重置数据库。ensure 仅在 8080 空闲时启动，stop 只停止 runtime 元数据确认由 F03 启动且命令行匹配 jar 的 PID。人工视觉验收需检查登录/注册、真实选项、选择提交、退出、冷启动恢复、键盘 overflow 与断网重试；自动检查不得替代人工观察。

## F03.1 视觉基线验收

- `check-mobile-f03-1.ps1`：检查视觉文档、Token/共享组件、可疑图片/外链、格式、analyze、Widget 测试和 Android Debug APK；
- `check-f03-1.ps1`：依次运行仓库检查、完整 F03 回归、移动端 F03.1 检查和文档/报告检查；
- 人工视觉验收：在 Pixel 8 模拟器或 Android 真机检查登录/注册一致性、三步流程、稳定占位、选中态、键盘、长列表、返回键、错误重试、文字放大及临时完成页。

```powershell
powershell -NoProfile -ExecutionPolicy Bypass -File .\scripts\windows\check-f03-1.ps1
```

成功输出为 `F03.1 client visual baseline check passed`。自动测试与 APK 构建不代表人工视觉验收完成。
# F04 检查链

- `check-mobile-f04.ps1`：文件/分层/假数据静态检查、pub get、格式、analyze、默认 Mock/Widget 测试与 Android Debug APK。
- `smoke-mobile-feed-f04.ps1`：确保并核对 health/db/redis 后，只运行独立真实 Flutter Feed 集成测试。
- `check-f04.ps1`：依次执行仓库策略、F03.1 全量回归、后端确保、F04 移动端检查、真实 Feed smoke、最终状态和文档报告检查。

默认 `flutter test` 不要求后端；真实测试必须显式设置 `RUN_LOCAL_BACKEND_INTEGRATION=true`，使用 localhost 且不打印密码/Token、不重置数据库。自动检查不能替代 Pixel 8、文字放大、刷新分页和导航返回行为的人工视觉验收。

## F05 发布返回与首页分区

`check-mobile-f05.ps1` 静态核对 pushReplacement、详情返回兜底、刷新协调器和 `FeedDisplaySections`，随后运行全量 Flutter 检查。`smoke-mobile-content-f05.ps1` 发布唯一真实帖子，验证详情，再逐页查询 recommend/news/following 并输出仅含 contentId、tab 和页码的安全摘要；测试不重置数据库、不删除非测试数据、不输出 Token 或密码。

## F06 最终收口与文字审计

- `check-mobile-f06.ps1` 额外静态确认球队卡不含独立箭头、整卡安全跳转和语义标记，并运行全量 Flutter 检查与 APK。
- `check-f06-text-data-audit.ps1` 解析 corrections JSON，拒绝视觉/媒体字段及其资源地址、敏感字段和非 HTTPS 来源，确认后端 Git 干净，再运行 format、analyze、全量测试和 APK。
- `check-f06.ps1` 聚合上述检查、F05/F04/F03.1 回归、真实 football smoke，最终仍输出 `F06 Flutter football data details check passed`；审计脚本单独输出 `F06 real-world text data audit check passed`。

自动检查覆盖 Pixel 8 尺寸和 140% 字体 Widget 用例，但球队卡按压、真实设备观感、返回后的滚动位置仍需用户人工复验。审计数据以 2026-07-18 为时点，后续使用前应重新核验。
