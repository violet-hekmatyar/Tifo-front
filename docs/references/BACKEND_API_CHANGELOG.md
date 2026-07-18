# 后端 API 变更登记

F00 只建立模板，不伪造变更记录。后续每次同步后按实际差异填写。

| 变更日期 | 后端文档/接口 | 变更内容 | 影响的 Flutter 页面 | 影响的 Vue 页面 | 前端处理状态 | 验证结果 | 备注 |
|---|---|---|---|---|---|---|---|
| 2026-07-17 | auth / onboarding | 文档与实现核验无字段冲突；实现确认注册不返回 Token、鉴权错误使用 HTTP 200 业务包络、主队自动加入关注球队且球员可空 | 登录、注册、首次设置 | 无 | 已适配 | 真实 smoke 通过 | 后端 HEAD `98ca87f`，未修改后端 |
| 2026-07-17 | `GET /api/app/feed`、`GET /api/app/users/me/stand` | 顶层旧文档样例使用 `CONTENT_CARD`/`MATCH_CARD`，当前 VO 实现和真实响应为 `CONTENT`/`MATCH`；当前 Feed 参数为 `tab/leagueId/teamId/pageNum/pageSize/cursor`，用户站位返回 `mainTeam/followTeams` | 正式首页 | 无 | DTO 以真实值为主并兼容旧别名；球队筛选集中在 data 层 | F04 真实 Feed smoke 通过 | 图片 URL 可为相对路径或空；业务错误仍为 HTTP 200 包络，后端 HEAD `98ca87f`，未修改后端 |
| 2026-07-18 | content / interaction / file | F05 提示包含 blocks/source/official 与 LEAGUE/HOT_EVENT，但当前详情 VO 无这些字段，发布关系只支持 TEAM/PLAYER/MATCH；内容 toggle 不返回计数 | 内容详情、发布、评论 | 无 | ARTICLE 用 body+mediaList 降级；toggle 后重读；发布 relationList 为空 | F05 真实 lifecycle smoke 通过 | 标题255、正文2000、媒体9、评论1000、单图10MB；后端未修改 |
| 2026-07-18 | football | 旧规划提及 standings、roster、player statistics/matches、lineup/ranking/statistics；当前 Java 只实现 leagues、match lists/details/events/report、team detail + 3 recent/3 upcoming、player basic detail | F06 数据与详情 | 无 | 仅消费真实接口；缺失能力使用正式空状态，不推算 | F06 Repository smoke：3 leagues、6 important matches、3 events | following-teams 需认证；业务错误仍 HTTP 200；后端未修改 |
