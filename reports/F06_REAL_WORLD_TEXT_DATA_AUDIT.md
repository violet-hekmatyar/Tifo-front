# F06 现实世界文字数据核验报告

## 1. 核验日期

- 核验日期：2026-07-18（Asia/Shanghai）。
- 公开页面按页面声明的本地时区解读；比赛存储建议统一为带偏移的 ISO 8601 或 UTC，并另存赛事官方时区。

## 2. 核验环境

- 前端：`D:\Football-APP-Front`，Flutter F06 页面与 `FootballApi`/`FootballRepository`。
- 本机后端：`http://localhost:8080`，健康检查、数据库和 Redis 均为 `UP`。
- 后端仅通过公开应用接口只读查询；未修改后端仓库、数据库或 seed。

## 3. 当前后端数据来源

本轮通过现有应用接口读取 `/api/app/football/leagues`、`/api/app/football/matches`、`/api/app/football/matches/:id`、`/api/app/football/teams/:id` 与 `/api/app/football/players/:id`。运行页面仍只使用这些后端 API；联网结果没有进入 Dart 生产代码。

## 4. 核验范围

| 类型 | 实际核验数 | 范围 |
| --- | ---: | --- |
| 联赛/赛事 | 3 | 当前接口返回的全部赛事 |
| 球队 | 6 | 六场比赛涉及且详情接口可读的球队 |
| 球员 | 7 | 当前七条比赛事件引用且详情接口可读的球员 |
| 比赛 | 6 | 当前比赛列表全部记录及详情 |
| 比赛事件 | 7 | 六场比赛详情中的全部事件 |

核验字段包含页面实际展示的名称、国家/地区、赛季、赛事类型、城市、主场、成立年份、教练、估值文字、球员球队/位置/号码/国籍/年龄/退役状态、比赛双方/时间/状态/比分/轮次/场地，以及事件分钟、类型、球员、描述和比分变化。

## 5. 未核验范围

- 当前接口未返回或 F06 未展示的全量世界足球实体。
- 球员出生日期：后端只返回年龄，F06 模型没有出生日期字段。
- 未被当前事件引用的球员。
- 粉丝数与关注状态等应用业务数据。
- 所有视觉、媒体和其地址；本轮没有下载、复制、替换或提交此类资源。

## 6. 来源优先级与方法

优先打开赛事官方赛程、俱乐部官方阵容/公告，再以页面发布日期和生效日期判断时效。搜索摘要只用于定位，最终依据均为已打开的原始官方页面。主要来源：

- [Premier League 2026/27 官方完整赛程](https://www.premierleague.com/en/news/4675097/all-380-fixtures-for-202627-premier-league-season/)
- [UEFA Champions League 2026/27 官方日期与赛制](https://www.uefa.com/uefachampionsleague/news/02a6-20d57cfcd03e-407c22a7f465-1000--2026-27-champions-league-teams-dates-draws-format-final/)
- [LALIGA 2026/27 官方首轮时间](https://www.laliga.com/noticias/horarios-de-la-primera-jornada-de-laliga-ea-sports-2026-27)
- [FC Barcelona 官方赛程](https://www.fcbarcelona.com/en/football/first-team/schedule)
- 各俱乐部官方教练、球员和公告页面，具体链接随机器清单逐条记录。

## 7. 联赛差异

三项赛事的正式名称、国家/地区和类型可继续使用；`season` 均写成了 `2026`，官方统一使用跨年标识 `2026/27`。共 3 个高置信度修正项。

## 8. 球队差异

- 六支球队的 `coachName` 都是 `Demo Coach A` 至 `Demo Coach F`。五支球队已有当日可确认的官方教练值；Arsenal 项因当前可访问官方页面不足以确认 2026-07-18 的任职值，建议先置空并人工确认。
- Barcelona 的主场当前正式名称为 `Spotify Camp Nou`，本地为 `Camp Nou`。
- 六支球队的 `marketValue` 都是 `demo`。俱乐部官方页面不提供可比较的当日估值，建议置空，并在后端另行确定获批的数据提供方、币种和估值日期。
- 名称、国家、城市、成立年份未发现足以提出字段级修正的高置信度差异；正式全称与短展示名属于数据规范选择，不在本轮擅自改写。

## 9. 球员差异

- 球员 40001 Robert Lewandowski：FC Barcelona 官方确认其在 2025/26 赛季结束离队，本地仍关联 Barcelona 和 9 号。新俱乐部尚未由本轮权威来源确认，建议先解除旧关联并人工补录新值。
- 球员 40009 Mohamed Salah：Liverpool 官方将其列为 2017–2026 的历史球员并确认 2025/26 后告别，本地仍关联 Liverpool 和 11 号。建议先解除旧关联并人工补录新值。
- Pedri、Jude Bellingham、Vinicius Junior、Harry Kane 与 Bukayo Saka 的当前显示字段没有形成需写入清单的高置信度差异；其中年龄属于随日期变化的派生值，应由出生日期计算而非长期固化。

## 10. 比赛差异

6 场比赛全部与官方竞赛日历冲突：

| 本地 ID | 本地记录摘要 | 官方冲突 |
| --- | --- | --- |
| 50001 | 07-10 Barcelona 2–1 Bayern，UCL Group A | UEFA 联赛阶段 9 月开始，7 月为资格赛 |
| 50002 | 07-12 Manchester City–Arsenal，Premier League | Premier League 8 月 21 日开始 |
| 50003 | 07-13 Real Madrid 1–1 Barcelona，La Liga LIVE | LALIGA 8 月开始，官方首回合国家德比为 10 月 25 日 |
| 50004 | 07-08 Liverpool 0–2 Manchester City，Premier League | Premier League 尚未开赛 |
| 50005 | 07-18 Barcelona–Real Madrid，La Liga | 官方 Barcelona–Real Madrid 为 10 月 25 日 |
| 50006 | 07-06 Arsenal 3–2 Bayern，UCL Group B | 早于 UCL 资格赛开始，且联赛阶段尚未抽签/开赛 |

这些记录不能通过仅改一两个字段成为权威比赛，建议后端整体删除、标记演示数据或用获批数据源重新导入。

## 11. 比赛事件差异

7 条事件全部依附于上述无官方依据的比赛，且描述都以 `Demo` 开头。分钟、类型、球员和比分变化均无法由赛事或俱乐部官方比赛记录佐证，因此 7 条均建议整体清理或重新导入，不能只删除描述文字后保留事实。

## 12. 时区差异

本地 `matchTime` 形如 `2026-07-10T20:00:00`，没有 `Z` 或偏移，也没有来源时区字段。官方 Premier League 页面使用 UK time，LALIGA/Barcelona 页面使用西班牙半岛时间，UEFA 页面仅列比赛日。后端修正任务应保存明确偏移或 UTC，并保留 `sourceTimeZone`；在比赛记录真实性解决前，不建议推断具体 UTC 值。

## 13. 状态枚举差异

`FINISHED`、`LIVE`、`SCHEDULED` 枚举本身与前端映射兼容；问题是记录事实失真：50002 在核验日已早于当前日期却仍为 `SCHEDULED`，50003 已过去五天却仍为 `LIVE`。不建议在前端修补状态，必须由后端数据任务处理。

## 14. 名称翻译差异

当前接口主要返回英文名称，前端原样展示。`Premier League`、`UEFA Champions League`、`La Liga` 和六支球队的常用英文名可读。正式全称、商业冠名与本地化短名需要单独的数据字典策略；除 `Spotify Camp Nou` 外，本轮不把风格差异当作事实错误。

## 15. 高置信度修正项

共 24 项：3 个赛季、5 个已确认教练、1 个主场名称、2 个球员旧球队关联、6 个比赛记录、7 个事件记录。详见 `reports/data-audit/F06_TEXT_DATA_CORRECTIONS.json`。

## 16. 中低置信度待确认项

共 7 项，均为中置信度：Arsenal 当前教练值需后端人工确认；六支球队估值需先确定合规提供方、币种、口径和日期。没有低置信度项目写入自动建议。

## 17. 网络来源冲突

未发现同一核验时点的权威来源直接冲突。个别俱乐部阵容页存在旧缓存版本，报告以日期更晚、明确宣布生效的官方公告为准；这属于时效版本差异而不是同时有效的事实冲突。若后端实施时页面状态变化，应重新核验。

## 18. 后端需要修改的字段

`league.season`、`team.coachName`、`team.stadiumName`、`team.marketValue`、`player.team`（连带号码）、六场比赛整条记录及其七条事件。所有建议都标记 `requiresBackendChange: true`，本轮没有执行。

## 19. 前端无需修改的字段

球队/球员/赛事名称、比分、时间、事件和状态继续原样来自 API；前端的状态中文映射、位置显示和时间格式化可保留。不得用 Flutter 常量覆盖错误后端事实。

## 20. 视觉资源明确不在本轮范围

本轮只处理文字字段。未读取、下载、复制、替换、生成或提交任何视觉/媒体资源，也未把相关地址写入修正 JSON。

## 21. 是否建议创建后端数据修正任务

建议。任务应先确认这些记录是否原本被定义为演示数据，然后以事务方式清理或重新导入；同时补充来源、抓取/录入日期、时区、赛季格式和估值口径。需要用户单独授权后端工作。

## 22. 风险

- 公开阵容、教练和号码会随转会窗口变化，本报告仅代表 2026-07-18。
- 官方赛程可能调整，但不会使已列出的 7 月国内联赛记录成立；UEFA 资格赛参赛球队也可能变化。
- 直接把 `null` 当作最终业务值可能影响消费者，后端任务需先审查约束和兼容性。
- 当前年龄字段会自然过期；长期应保存出生日期并在展示层按日期计算。

## 统计结论

- 核验实体：3 联赛、6 球队、7 球员、6 比赛、7 事件。
- 修正建议：31 项；高置信度 24 项；待人工确认 7 项。
- 生产运行数据改动：0。
- 后端、数据库、seed 改动：0。
