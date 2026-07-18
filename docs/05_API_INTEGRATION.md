# 南看台前端 API 接入规范

## F06 展示排序边界

后端重要/关注/联赛列表的分页结果保持原字段与状态。前端仅为产品展示对已加载且去重后的集合排序：进行中、即将开始、已结束、异常/未知；未开始时间升序，已结束时间降序，进行中和其他组保持后端相对顺序。不得按比分推断状态或回写后端。当前真实枚举为 `LIVE/SCHEDULED/FINISHED`，同时安全兼容同义和异常状态。

## F06 Football 真实契约

- `GET /api/app/football/leagues`：公开联赛列表；
- `GET /api/app/football/matches/important`：重要比赛分页；
- `GET /api/app/football/matches/following-teams`：登录用户关注球队比赛分页；
- `GET /api/app/football/matches`：按 `leagueId/teamId/date/status` 查询分页；
- `GET /api/app/football/matches/{matchId}`、`teams/{teamId}`、`players/{playerId}`：公开详情，可选 Token 决定只读 followed 状态。

比赛分页沿用 `records/total/pageNum/pageSize/pages`。前端映射已知比赛状态，未知值安全展示；比分为空时不显示 0:0。Logo/头像可为相对 URL 或空，由统一 Resolver 处理。业务失败仍为 HTTP 200 包络，`40401` 表示对象不存在；`40101/40102` 清本地会话，403 保留 Token。

当前 Java 实现没有 standings/ranking、球队 roster、球员比赛/赛季统计、match lineup/advanced statistics 接口。详情仅消费基本资料、球队最近/未来比赛、比赛事件和战报，不复制 Entity 或从比赛推算排名。

## F05 契约

详情当前没有 blocks/source/isOfficial；ARTICLE 用 body+mediaList 降级。发帖提交 title/body/mediaFileIds/空 relationList。toggle 只返回布尔值，成功后重读详情取计数。评论使用 contentId/sort/分页、replies、专用点赞和软删除；上传 multipart 为 file + `CONTENT_IMAGE`。

> 版本：v0.2
> 当前阶段：F04
> 文档定位：前端接口接入、解析、错误处理和变更流程的唯一权威文档。
> 不负责：复制后端完整请求/响应示例或重新定义后端契约。

## 权威来源

后端原始契约：`D:\Football-APP\docs\06_API_SPEC.md`；仓库内只读快照：`references/backend/06_API_SPEC.md`。原始文件优先于快照。

## 基础接入

Base URL 必须按环境配置，不得硬编码服务器地址。Flutter 使用 `--dart-define=APP_ENV=...` 和 `--dart-define=API_BASE_URL=...`；Vue 使用 `VITE_APP_ENV` 和 `VITE_API_BASE_URL`。环境只允许 `development`、`test`、`production`。接口前缀包括 `/api/auth/**`、`/api/app/**`、`/api/admin/**`、`/api/public/**`、`/api/file/**`。

F03 从安全存储读取 Access Token，并由统一请求头 provider 发送：

```http
Authorization: Bearer <access_token>
```

统一响应由网络层一次解析为 `code / message / data / traceId`；分页数据统一为 `records / total / pageNum / pageSize / pages`。页面不得自行兼容多套返回格式，也不得根据截图或数据库字段重建契约。

## 错误处理

| code | F02 前端原则 |
|---:|---|
| `40001` | 作为业务错误保留 code、message 与 traceId |
| `40101` / `40102` | 只归一化；若 HTTP 为 401 则作为 HTTP 错误，不清理会话、不跳转 |
| `40301` | 只归一化；若 HTTP 为 403 则作为 HTTP 错误，不执行权限路由 |
| `40401` / `40901` / `50001` | 保留业务错误信息，具体 UI 行为由后续业务任务决定 |

双端统一区分配置、网络断开、超时、取消、HTTP 非成功状态、业务 `code != 0`、解析和未知错误。Flutter Feature 不接触 `DioException`，Vue 调用方不接触 `AxiosError`。日志可记录路径、错误码和 traceId，不得记录完整 Token 或敏感请求体。

## 响应、分页与适配边界

统一成功码暂按后端文档的 `code == 0`；`data` 由调用方提供强类型 decoder，支持对象、空数据、列表和 `PageResult<T>`。二进制文件响应不经过 JSON 包络解析。后端对“业务失败使用 2xx 还是非 2xx”的具体端点策略、无数据时 `data` 是否始终存在，仍以联调为准；当前 HTTP 与业务错误分层集中在适配层，可局部调整而不污染 Feature。

后端返回相对图片 URL 时，后续由 URL resolver 使用当前环境 Base URL 拼接；绝对 URL 需按允许策略直接使用。DTO/VO 在网络边界转换为前端模型，页面不接触后端 Entity 概念。未知枚举或 `cardType` 必须有兼容占位和可观测日志，不能导致整个列表崩溃。

## F03 真实接口

本轮真实使用 `/api/public/health*`、`POST /api/auth/register`、`POST /api/auth/login`、`GET /api/auth/me`、`GET /api/app/onboarding/options`、`POST /api/app/onboarding/preferences`。注册返回用户信息但不返回 Token；登录返回 Access Token、tokenType、expiresIn 与 user。当前后端业务与鉴权失败均使用 HTTP 200 的统一业务包络，因此 40101/40102/40301 从 `BusinessException` 分流。

Windows 集成测试使用 `http://localhost:8080`；Android 模拟器使用 `http://10.0.2.2:8080`。球队 logo 与球员头像的相对 URL 使用当前 Base URL 解析，空值/加载失败显示稳定占位。

## 页面与接口关系

页面只依赖按业务域封装的 API：认证/首次选择、feed、内容互动、足球数据、用户中心、管理用户内容、文件。具体路径和实际已实现范围以最新后端契约的 Current Implementation Notes 为准；计划接口不得当作已可用接口。F02 不调用任何真实业务 API。

## F04 Feed 真实契约

Flutter 使用 `GET /api/app/feed`，参数为 `tab`、`pageNum`、`pageSize`，球队筛选额外传 `teamId`；一级筛选集中映射为 `recommend`、`news`、`following`。关注球队来自 `GET /api/app/users/me/stand` 的 `mainTeam` 与 `followTeams`，按 `teamId` 去重。Feed 继续使用统一分页 `records/total/pageNum/pageSize/pages` 和 HTTP 200 业务包络。

当前实现实际返回 `cardType=CONTENT|MATCH`。内容卡使用 `contentId/contentType/title/summary/coverUrl/author/hotComment/publishTime/likeCount/commentCount`；比赛卡使用 `matchId/leagueName/homeTeam/awayTeam/homeScore/awayScore/matchStatus/matchTime/eventSummary`。字段为空时前端不补造数据。DTO 同时接受旧文档样例中的 `CONTENT_CARD|MATCH_CARD`，其他或单卡畸形类型降级为 `UnknownFeedCard`。相对图片 URL 统一由 F02 resolver 解析。

## 变更流程

后端先更新并确认原始契约 → 运行同步脚本 → 在 `references/BACKEND_API_CHANGELOG.md` 登记影响 → 更新前端 API 层与模型 → 完成单元/联调/smoke → 再修改页面。禁止只改页面临时适配后跳过统一网络层。

## F05 发布后 Feed 核验

发布仍以 `POST /api/app/contents/posts` 返回的真实 contentId 为准，并立即通过详情接口读取。详情返回只重新请求当前 `GET /api/app/feed` 的 tab/teamId 第一页；刷新不清空旧列表，失败保留旧数据。真实 smoke 还逐页查询 recommend/news/following 并记录 contentId 所在页；未返回时前端不伪造可见性。展示分区不改变请求参数、分页元数据或后端推荐结果。

## F06 文字数据审计边界

现实核验从现有 football 接口只读收集当前 F06 可展示记录，联网来源只写入 `reports/F06_REAL_WORLD_TEXT_DATA_AUDIT.md` 和 corrections JSON。Flutter 不请求这些外部页面，也不以硬编码覆盖球队、球员、比分、时间、事件或状态。所有运行事实仍来自后端 API；需修正的现实数据必须另建获授权后端任务。本轮不处理视觉/媒体字段，未修改数据库。
