# F01-F07 后端能力矩阵

> 审计时点：2026-07-19。后端仓库：`D:\Football-APP`，`main@98ca87f`。结论以当前 Java Controller -> Service -> Mapper/查询闭环为准；`docs/06_API_SPEC.md` 中只有规划、但源码不存在的端点均不算支持。

## 结论摘要

后端已支持认证与首次设置、两类 Feed、帖子/媒体/内容关系、评论回复与点赞收藏、基础联赛/赛程/球队/球员/比赛详情、比赛事件与战报、用户中心和用户关注、基础后台查询及状态维护。当前不支持积分榜、球员榜、球队榜、球队完整阵容、球队/球员赛季统计、球员生涯、比赛阵容/排名/统计、球员/裁判评分、消息通知或私信。

`docs/06_API_SPEC.md` 和 `docs/12_CODEX_TASK_PLAN.md` 仍列出 `/standings`、`/player-ranks`、`/team-ranks`、球队/球员/比赛扩展端点及部分后台写接口；当前 Controller 端点扫描没有这些映射。这是“规划文档超前于实现”，不是可调用能力。

## 通用能力

| 模块 | 当前真实接口 | 关键返回/行为 | 结论 |
|---|---|---|---|
| 认证 | `POST /api/auth/register`、`POST /api/auth/login`、`GET /api/auth/me` | Access Token、用户、角色、onboarding 状态 | 支持用户名密码；不支持手机号/微信登录、Refresh Token |
| 首次设置 | `GET /api/app/onboarding/options`、`POST /api/app/onboarding/preferences` | 球队/球员选项、mainTeamId、关注计数 | 支持；主队自动关注；没有球队关注上限 |
| 关注 | `POST /api/app/follows/toggle` | USER/TEAM/PLAYER、followed、计数 | 支持切换；球队最多五支规则不支持 |
| 首页 Feed | `GET /api/app/feed`、`GET /api/app/feed/hot-leagues` | `CONTENT`/`MATCH`、热评、关系、规则分数 | 支持 recommend/news/following/match/mixed；无榜单/评分/转会/讨论卡 |
| 内容 | `GET /api/app/contents/{id}`、`POST /api/app/contents/posts` | POST/ARTICLE 等读取、媒体、关系、作者、互动状态 | 支持帖子发布与现有文章读取；无文章 blocks 编辑/发布闭环 |
| 互动 | comments、replies、comment-like、like、favorite | root/reply、hot/latest、toggle | 支持；热评公式与 PDF 一致 |
| 文件 | upload/public-read/delete/avatar-bind/media-bind | fileId、public URL、类型/大小校验 | 支持图片；无视频上传 |
| 用户中心 | `/users/me/summary|stand|contents|favorites|comments|profile` | 个人资料、统计、分页列表 | 支持；缺“我的点赞”列表 |
| 用户社交 | `/users/{id}/profile|contents|followings|followers`、follow POST/DELETE | relationStatus、关注/粉丝、公开发布 | 支持；他人收藏/评论保持私有 |
| 消息 | 无 | 无通知、未读、会话或聊天表/接口 | 不支持 |
| 后台 | dashboard summary、users list/status、contents list/status、health | ADMIN 限权、分页、状态更新 | 基础支持；无内容发布/编辑、football CRUD Controller |

## 足球数据能力矩阵

说明：“新表”是按当前 `schema.sql` 缺口判断；具体表型仍需后端设计。“外部源”表示现有本地表和样例数据不足以持续提供真实数据。“版权/费用”只给风险类别，不替代法务或采购结论。

| # | 能力 | 后端支持 | 真实接口与真实字段 | 前端使用/能否直接补 | 新表 | 外部赛事源 | 版权/费用 | 推荐阶段 |
|---:|---|---|---|---|---:|---:|---|---|
| 1 | 联赛列表 | 是 | `GET /api/app/football/leagues`；leagueId/name/nameEn/country/logoUrl/season/leagueType | 已使用；无需补 | 否 | 正式运营建议 | Logo/赛事商标需授权策略 | 已完成 |
| 2 | 赛季列表 | 否（仅联赛当前 season 字段） | 无独立端点；`LeagueVO.season` | 不能完成跨赛季选择 | 建议赛季/赛事关联表 | 是 | 数据供应费用风险 | F09B |
| 3 | 赛事赛程 | 是 | `GET /api/app/football/matches`；matchId/league、双方、比分、status/time/eventSummary/report | 已使用 | 否 | 正式运营建议 | 赛事数据许可 | 已完成基础版 |
| 4 | 重要比赛 | 是 | `GET /matches/important`；同 MatchListVO，按 important_level | 已使用 | 否 | 人工维护可运行；自动化需 | 低至中 | 已完成基础版 |
| 5 | 关注球队赛程 | 是 | `GET /matches/following-teams?teamId=`；同 MatchListVO | 已使用 | 否 | 同赛程 | 同赛程 | 已完成 |
| 6 | 联赛积分榜 | 否 | 无真实端点；文档中的 `/standings` 未实现 | 不能直接补 | 是（standing/round） | 是 | 实时数据通常收费/许可 | F09B |
| 7 | 杯赛阶段榜/淘汰赛 | 否 | 无端点、表或 Service | 不能直接补 | 是（stage/tie） | 是 | 数据许可；交互规则待确认 | P3/F09B 后续 |
| 8 | 球员榜：射手/助攻/黄红牌/射门/射正/评分/扑救 | 否 | 无 `/player-ranks` Controller；无统计字段 | 不能直接补 | 是（player_competition_stat） | 是 | 高实时性源可能收费 | F09B |
| 9 | 球队榜：进失球/助攻/牌/射门/射正/角球/犯规 | 否 | 无 `/team-ranks` Controller；无统计表 | 不能直接补 | 是（team_competition_stat） | 是 | 同上 | F09B |
| 10 | 球队阵容/球员名单 | 否（底层关系存在但无查询闭环） | `team_player` 表存在；没有 team roster Controller/Service 返回 | 不能直接补；先加接口 | 不一定，现表可做基础名单 | 真实名单更新需要 | 球员头像/资料许可 | F09C |
| 11 | 球队赛季数据 | 否 | 无端点、统计模型 | 不能直接补 | 是 | 是 | 可能收费 | F09C |
| 12 | 球队荣誉 | 否 | 无端点/表 | 不能直接补 | 是 | 可人工录入或外部源 | 历史事实低风险，Logo 另计 | F09C |
| 13 | 球员赛季统计 | 否 | 无端点/表；PlayerDetailVO 只有基础字段 | 不能直接补 | 是 | 是 | 可能收费 | F09C |
| 14 | 球员生涯 | 否 | 无端点/表 | 不能直接补 | 是 | 是 | 可能收费 | P2/F09C 后续 |
| 15 | 比赛事件 | 是 | `GET /matches/{id}` 内 eventList：类型、分钟、球队、球员、助攻、scoreAfter、description、hasDebate | 已使用 | 否 | 正式运营需要 | 事件数据许可 | 已完成基础版 |
| 16 | 比赛阵容 | 否 | 无端点/表 | 不能直接补 | 是（lineup/player appearance） | 是 | 可能收费 | F09D |
| 17 | 比赛排名 | 否 | 无端点；依赖 standings | 不能直接补 | 依赖积分榜 | 是 | 同积分榜 | F09D |
| 18 | 比赛详细统计 | 否 | 无控球、射门、传球等端点/表 | 不能直接补 | 是 | 是 | 通常需要详细数据套餐 | F09D |
| 19 | 球员评分 | 否 | 无 rating Controller/Service/聚合表；comment 的 `userRatingScore` 未形成闭环 | 不能直接补 | 是（vote/aggregate） | 媒体评分需外部源；用户评分不必 | 媒体评分许可；用户评分风控 | F09D |
| 20 | 裁判评分 | 否 | 无裁判实体、比赛裁判关系或评分接口 | 不能直接补 | 是 | 裁判资料需外部源 | 数据许可与社区风控 | P3 |
| 21 | 比赛视频/集锦 | 否 | 无 video 字段、表或接口 | 不能直接补 | 是（video relation） | 是/合作嵌入 | 高版权与平台条款风险 | P3 |

## 关键源码证据

- 路由事实：`D:\Football-APP\src\main\java\com\southstand\**\*Controller.java` 的全部映射扫描。
- 足球查询：`football/schedule/service/FootballQueryService.java` 仅覆盖 leagues、important/following/general matches、team/player/match basic detail、events、report。
- 返回字段：`LeagueVO`、`MatchListVO`、`MatchDetailVO`、`TeamDetailVO`、`PlayerDetailVO`、`MatchEventVO`。
- 持久化事实：`scripts/sql/schema.sql` 只有 league/team/player/team_player/match_info/match_event/match_report；没有 standing/rank/stat/lineup/rating/message/notification/conversation 表。
- 文档冲突：`docs/06_API_SPEC.md` 的 standings/ranks/overview/stats 等规划端点，以及 `docs/12_CODEX_TASK_PLAN.md` 的 T06/T08“必须实现”清单，部分没有落到当前 Controller。

## 明确回答

- 球员榜：当前不能实现；必须先增加后端统计模型、接口与真实赛事数据源。
- 球队榜：当前不能实现；必须先增加后端统计模型、接口与真实赛事数据源。
- 联赛积分榜：当前不能实现；必须先增加 standings 数据模型、接口与数据源。
- 球队完整球员列表：当前不能直接由前端补齐；`team_player` 可复用，但后端必须新增 roster 查询闭环。
- 球员赛季统计/生涯：当前不能实现；需要新表、接口和外部数据源。
- 比赛阵容/排名/统计：当前不能实现；分别依赖阵容、积分榜和比赛统计数据模型。
- 球员/裁判评分：当前不能实现；需要评分业务模型、聚合规则、风控和接口。
- 消息/私信：当前不能实现；消息通知需新增表和 API，完整私信还需会话、消息、风控及实时/轮询协议。
