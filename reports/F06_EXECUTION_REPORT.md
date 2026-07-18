# F06 足球数据中心与详情执行报告

> 补充：人工发现正式复数详情路径被认证 redirect 误判并回到首页，后续已按 `F06_ROUTING_SORTING_FIX_REPORT.md` 修正；排序、入口和分页 Footer 同步补齐，最终结果以修正后的聚合检查为准。

> 日期：2026-07-18。自动结果以最终 `check-f06.ps1` 为准；人工视觉验收未执行，不伪造结论。

## 基线与核验

| 项目 | 结果 |
|---|---|
| 前端初始 Git | `main`，HEAD `e5f2036 feat: add Flutter content publishing and interaction flow`，开始时 clean |
| 后端初始 Git | `main`，HEAD `98ca87f feat: complete T12 comment hot ranking`，只读且 clean |
| 后端文档同步 | `sync-backend-docs.ps1` 通过；产品 PDF 未变化 |
| F05 回归 | `F05 Flutter content publish interaction check passed`，88 项测试及真实 smoke/APK 通过 |
| 后端状态 | health/db/redis 均 UP，F03 所有 PID 10000 |
| 已读资料 | 前端 README、00–13、F04/F05 报告/checklist、产品 PDF 第 10–38 页；后端 football Controller/VO/Service/Entity/Security/smoke 与 API/验证/计划文档 |

## 真实后端能力

| 领域 | 接口与结果 |
|---|---|
| 赛事 | `GET /api/app/football/leagues`，真实 smoke 返回 3 个 |
| 比赛列表 | important、following-teams、通用 matches（leagueId/teamId/date/status）统一分页；真实 important 返回 6 场 |
| 比赛详情 | `GET /matches/{id}`，含基础字段、主客队、事件与可选战报；真实 smoke 详情含 3 个事件 |
| 球队 | `GET /teams/{id}`，含基础字段、followed、最近 3 场和未来 3 场；通用 matches 支持球队赛程 |
| 球员 | `GET /players/{id}`，含基础资料、当前球队与 followed；真实 smoke 使用后端自身 smoke 的稳定种子 ID 40001 |
| 排名/统计 | 无 standings/ranking、球队统计、球员赛季统计或比赛统计接口 |
| 阵容 | 无球队 roster 或比赛 lineup 接口 |
| 鉴权 | leagues/matches/team/player 公开 GET；following-teams 需认证；业务错误仍使用 HTTP 200 包络 |
| 契约差异 | 已登记 `docs/references/BACKEND_API_CHANGELOG.md`；当前 Java 实现优先于旧规划 |

## 实现结果

1. 数据 Tab 已替换占位，支持重要/关注/真实联赛来源、日期分组、刷新、分页、防重复、去重与旧请求隔离。
2. 比赛卡显示真实状态、时间和可选比分；无比分不显示 0:0；未知状态兼容。
3. 球队详情包含品牌头、真实基础资料、关注只读状态、近期比赛和分页球队赛程；阵容/数据缺口为空状态。
4. 球员详情包含头像、基础资料、现役/退役、关注只读状态和可跳转当前球队；统计/比赛缺口为空状态。
5. 比赛详情包含赛事、时间、状态、主客队、比分、轮次/场地、事件时间线和可选战报；阵容/排名/统计缺口为空状态。
6. 路由统一为 `/teams/:teamId`、`/players/:playerId`、`/matches/:matchId`，旧 `/match/:matchId` 兼容重定向。首页 MATCH、内容 TEAM/PLAYER/MATCH 关系及详情实体均接通。
7. 数据页由主壳 indexed stack 与 PageStorage 保持来源/滚动；详情用 IndexedStack 保持当前 Tab；无历史栈返回 `/app/data`。
8. 图片继续复用 `AppTeamLogo`、`AppPlayerAvatar`、`AppEntityAvatar` 和 URL Resolver，空值/错误稳定回退。
9. `40101/40102` 统一删除 Token 并通知 AuthController；403 不触发会话失效。
10. 未新增依赖，未引入图表库、第二套状态管理或生产假 football 数据。

## 修改范围

- Flutter：`features/football` data/domain/presentation、真实路由、首页 MATCH 跳转、内容关系跳转、会话失效信号。
- 测试：football controller/widget、ApiClient 401/403、副作用、独立真实后端 football 测试。
- 脚本：`check-mobile-f06.ps1`、`smoke-mobile-football-f06.ps1`、`check-f06.ps1`。
- 文档：README、移动端 README、00/02/04/05/06/07/08/10/11/12/13、API changelog、本报告与人工 checklist。
- 新增依赖：无。

## 验证

| 检查 | 结果 |
|---|---|
| F06 专项 Mock/Widget + ApiClient | 路由/排序/多页修正后默认全量 112 项通过，analyze 零问题 |
| 真实 football smoke | `F06 local backend football data smoke passed`；3 leagues、6 matches、状态 FINISHED/LIVE/SCHEDULED；所选详情 2 events/2 event players；following 新用户为空 |
| check-repo | `Frontend repository base check passed` |
| check-f05 | 最终聚合中再次通过，含 F01–F04、Vue、真实 F03/F04/F05 smoke |
| check-mobile-f06 | `F06 Flutter football data and detail check passed` |
| check-f06 | `F06 Flutter football data details check passed` |
| APK | `apps/mobile/build/app/outputs/flutter-apk/app-debug.apk`，已构建复核 |

## 安全、数据与边界

- 修改后端：否；后端全程只读。
- 重置/修改数据库或 football seed：否。真实 smoke 仅按既有模式创建一个唯一登录用户，不写 football 数据。
- 生产假数据：无；测试 fixture 只存在 `test`。
- 敏感信息：未发现；脚本/测试不输出密码、Token、正文或完整响应。
- Git 写操作：未执行 add/commit/push/reset/clean。
- 人工视觉验收：未执行，见 `F06_UI_REVIEW_CHECKLIST.md`。

## 未完成项、风险与后续

- 后端真实缺口：积分榜、球队阵容、球员统计/比赛、比赛阵容/统计；F06 不自行推导。
- 未实现：实时比分推送、自动轮询、评分、视频、淘汰赛树与高级统计。
- 风险：真实进行中比赛与远端图片失败的长时间体验仍需人工设备观察；详情 FutureProvider 离开页面后释放，不长期缓存比赛状态。
- 建议：最终聚合与人工 checklist 通过后提交。
- 建议提交信息：`feat: add Flutter football data and detail flows`
- 下一步：F07 我的页面、关注与消息基础。

## F06 人工阻塞修正结果

认证 redirect 漏掉复数 football 详情路径的根因已修复，详情使用 root Navigator；集中排序、可发现球队/球员入口和分页 Footer 已补齐。修正后全量 112 项测试、真实 football smoke、F05 历史回归、Debug APK 和最终聚合均通过。人工复验仍待用户执行，详见 `F06_ROUTING_SORTING_FIX_REPORT.md`。

## F06 最终球队入口与文字审计

首页关注球队卡已移除独立箭头：真实球队整卡直接进入 `/teams/:teamId`，不会先改 Feed 筛选；“全部”仍恢复全部 Feed。新增 Widget 用例覆盖唯一点击区、语义、非法 ID、Pixel 8/140%、push/pop 后筛选和滚动状态保持。

2026-07-18 从本机接口只读核验 3 联赛、6 球队、7 球员、6 比赛、7 事件；形成 31 条后端修正建议，其中高置信度 24 条、待确认 7 条。联网结果只在 `F06_REAL_WORLD_TEXT_DATA_AUDIT.md` 和 corrections JSON，运行 API、后端、数据库均未修改，本轮未处理视觉/媒体资源。
