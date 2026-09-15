# Round 10：Flutter 球员详情完整原型对齐

## 任务

在 `D:\Football-APP-Front` 当前主目录完成球员详情页面族，对齐现有原型，并基于现有 Backend V1 的 `overview / stats / teams / career / matches / contents` 能力闭环“总览、动态、数据、比赛、生涯”五个 Tab。不修改后端、数据库和 API 契约。

本轮是完整球员详情交付，不是只换头部样式。除非缺少必要契约、权限或外部服务且无法安全降级，否则不要因编译错误、测试失败、布局问题或旧代码缺陷停止；持续修复并完成全部验收编号。

## 原型与代码范围

先查看：

- `C:\Users\hekmatyar\Desktop\足球APP\球员详情-总览.png`
- `C:\Users\hekmatyar\Desktop\足球APP\球员详情-帖子.png`
- `C:\Users\hekmatyar\Desktop\足球APP\球员详情-帖子(1).png`
- `C:\Users\hekmatyar\Desktop\足球APP\球员详情-数据.png`
- `C:\Users\hekmatyar\Desktop\足球APP\球员详情-生涯.png`
- `C:\Users\hekmatyar\Desktop\足球APP\球员详情-生涯-赛季.png`

只读取并修改球员详情直接相关文件：

- `apps/mobile/lib/features/football/presentation/pages/player_detail_page.dart`
- `apps/mobile/lib/features/football/presentation/controllers/player_detail_controllers.dart`
- `apps/mobile/lib/features/football/domain/player_detail_models.dart`
- `apps/mobile/lib/features/football/data/player_detail_api.dart`
- 必要的 player repository、router 和共享 football widget
- R09 已通过的球队详情分页/刷新/自然高度布局能力，仅在确有复用价值时抽取极小共享组件
- `apps/mobile/test/features/football/f14_player_detail_*`
- 项目 `AGENTS.md`、现有 Design Token 和已安装 Skills

原型决定信息结构，不是数据契约。当前模型没有转会费、能力雷达、球员荣誉、市场身价或完整赛季候选列表，禁止从其他字段推导或硬编码这些内容。

## 禁止范围

- 不修改 Spring Boot、数据库、SQL、API 地址、参数或响应结构；
- 不新增依赖，不实现比赛详情增强、球员评分提交、通知、推荐埋点扩展；
- 不伪造转会记录、能力值雷达、荣誉奖杯、年龄、国籍、国家队、赛季或比赛；
- 不将原型中的武磊、巴塞罗那或示例数字写入生产路径；
- 不制造无行为的“赛季选择”“总计/场均”“查看全部”按钮；
- 不启动模拟器，不 build APK，不跑全仓测试、整个 football 目录或旧轮次脚本。

## 连续执行要求

按 Gate 0～6 顺序推进，每个 Gate 同时完成生产实现和行为测试。测试名称包含编号不等于完成，断言必须覆盖编号中的所有关键行为。首次失败后定位根因并继续修复，不能以“部分编号尚未补齐”结束。

### Gate 0：契约与基线

- 核对 `PlayerDetail` 与 `PlayerOverview/PlayerSeasonStats/PlayerTeamLink/PlayerTeamHistory/PlayerCareer/PlayerCareerGroup` 的真实字段、nullable 和 unknown；
- 核对六条 repository/API 调用链及分页参数，不创建第二套重复数据层；
- 核对从搜索、榜单、球队、比赛进入球员详情，以及返回球队/比赛/内容的现有路由；
- 先运行现有 `f14_player_detail_*` 基线，范围内失败直接修复；
- 推荐 `DETAIL` 事件仍只上报一次，不因 rebuild 或 Tab 切换重复。

### Gate 1：沉浸式头部、关注与五 Tab

- 复用 R09 的详情头部和 Tab 设计语言：返回、头像、球员名、位置/状态、真实当前俱乐部摘要、关注按钮和五 Tab 形成连续层级；
- 不从球员/球队名称推导主题色；使用现有语义 Token；
- 头部安全处理缺头像、超长中英文名、unknown 位置、空俱乐部、空关注数、现役和退役；
- 增加真实球员关注/取消关注，复用现有 `toggleEntity('PLAYER', id)`：成功更新、busy 防重复、网络/业务失败保持旧状态并提示、无效 ID 不请求；
- 五个 Tab 增加稳定 Key，窄屏可横向滚动，选中态清楚；切换保持已加载数据和滚动位置，不重复首屏请求；
- 返回优先 pop，无历史回 `/app/data`。

### Gate 2：总览

按真实字段组织以下内容，空字段模块级隐藏或明确空态，不留截图式假内容：

1. 个人资料：位置、国籍、生日/年龄、身高、体重、惯用脚、号码、队长、现役/退役状态。
2. 当前俱乐部：仅 `club` 存在时显示；队徽、号码、类型使用真实字段，有效 ID 进入球队详情。
3. 国家队：`nationalTeam` nullable；为空时显示自然的“暂无国家队信息”，不得根据国籍伪造。
4. 当前赛季数据摘要：使用 `seasonStats` 中真实记录，展示赛事/赛季/球队及关键指标；没有数据就隐藏该模块。
5. 最近比赛：使用 `recentMatches`，复用 R09/R08 的排序、状态和卡片；有效 ID 进入比赛详情。
6. 最近动态：使用 `recentContents`，使用与动态 Tab 一致的安全内容卡片；有效 ID 进入内容详情。

退役球员按真实 `retired/rawStatus` 展示；没有当前俱乐部、国家队、近期比赛或动态时不强行补数据。总览各模块的 nullable、unknown、无效 ID 和长文本均需安全。

### Gate 3：动态与比赛分页 Tab

动态：

- 复用 R09A 已通过的自然高度双列策略：412px 常规字体双列独立高度，奇数最后半列；360px 或 1.4x 字体安全降级单列；
- 展示真实封面、标题、摘要、类型、发布时间、点赞和评论；无封面完全收起图片区；
- unknown contentType 安全显示，有效 ID 跳内容详情，无效 ID 不误跳。

比赛：

- 为 player matches controller 接入稳定 `match_display_sort`；按日期分组，连续无日期比赛只出现一次“日期待定”；
- 未开始、进行中、结束、延期、取消、unknown、缺时间/比分/队徽安全；
- 如响应已有 `eventSummary/hasReport/reportContentId`，按现有契约解析并交给共享比赛卡片，不新增字段；
- 有效比赛/球队 ID 跳现有详情，无效 ID 不误跳。

两者共同要求：首屏 loading/empty/error/retry、下拉刷新、ready 刷新失败保留旧内容并提供原位重试、分页 busy 防重、按 ID 去重、append 失败保留记录并重试原页、到底状态、SafeArea、Tab 返回保持滚动与请求次数。

### Gate 4：数据 Tab

- 将 `PlayerSeasonStats` 按真实赛事/赛季/球队形成清晰卡片或分区；没有真实候选列表时只展示响应中的上下文，不提供假选择弹层；
- 完整展示 appearances、starts、minutes、goals、assists、yellowCards、redCards、shots、shotsOnTarget、shotAccuracy、rating、saves 中实际存在字段；
- 只在分子分母有明确关系时显示进度条或比率；不得自行生成能力雷达、联赛百分位或强弱结论；
- 数值格式处理 0、null、负值、NaN、Infinity、整数/小数百分比和评分；不可解释值显示 `—`；
- 多条统计记录不能互相覆盖，快速上下文变化时旧响应不得覆盖最后请求；
- 支持 loading/empty/error/retry；某张统计部分为空时保留有值字段，全部空记录不得渲染成一大片 `—`；
- 360/412px、1.4x 字体下标题和指标自适应，无固定高度裁切。

### Gate 5：生涯 Tab

- 使用 `PlayerCareer` 的总计字段完整展示出场、首发、分钟、进球、助攻、黄/红牌、射门、射正、扑救、平均评分、球队数、赛季数中的真实值；
- 修正 `PlayerCareer.hasData`，所有总计字段以及 `bySeason/byTeam` 任一有值都应视为有数据；
- 实现原型中的“球队 / 赛季”真实切换：球队视图使用 `byTeam`，赛季视图使用 `bySeason`；切换只影响本地已返回分组，不发明新请求；
- 同时使用 `teams` 展示历史效力时间线：队徽、球队名、赛季、开始/结束日期、号码、位置、出场/进球/助攻、current、loan；有效球队 ID 可跳转；
- career 和 teams 两个子资源独立 loading/error/empty/retry。一个失败时另一个成功模块仍可展示，不能任一错误导致整页消失；
- unknown/空日期/空赛季、当前效力、租借、退役球员和重复历史记录安全；不要从 history 推导转会费或不存在的起止信息。

### Gate 6：状态保持与响应式收口

- 五个 Tab 分别验证 loading/empty/error/retry/ready；动态和比赛另有 refresh/append/end；
- 从球队、比赛、内容子详情返回后保留球员详情原 Tab、滚动位置、已加载页和筛选上下文；
- overview/stats/career/teams 的失败与重试互不污染；
- 页面底部 SafeArea 正常；360px、412px、DPR 1、1.4x 字体下逐个切换并渲染五个 Tab，无 overflow/debug 条纹；
- 不出现“后端未提供”、生产 mock、TODO、死按钮或伪能力。

## 强制验收矩阵

在现有三个 `f14_player_detail_*` 文件基础上补充 controller/widget 测试，必要时新增一个 sections/responsive 测试文件。测试名必须包含编号，断言必须与编号内容对应。

| 编号 | 必须验证的行为 |
| --- | --- |
| PLAYER-01 | 沉浸式头部、五 Tab Key/选中态、返回；长名、缺头像、unknown 位置、现役/退役安全 |
| PLAYER-02 | 关注/取消成功、busy 防重、网络与 BusinessException 失败保持、无效 ID 零请求 |
| PLAYER-03 | 推荐 DETAIL 在 rebuild/Tab 切换中仅上报一次 |
| PLAYER-04 | 总览真实资料、俱乐部、nullable 国家队、队长与退役状态正确，不推导缺失数据 |
| PLAYER-05 | 总览 seasonStats、recentMatches、recentContents 模块及有效/无效实体跳转 |
| PLAYER-06 | 动态 412px 自然高度双列、奇数半列、无封面收起，360px/1.4x 单列降级 |
| PLAYER-07 | contents loading/empty/error/retry/refresh/append/end、去重、防重和失败保留 |
| PLAYER-08 | 比赛排序、日期/日期待定分组、多状态与摘要字段安全，实体跳转正确 |
| PLAYER-09 | matches loading/empty/error/retry/refresh/append/end、去重、防重和失败保留 |
| PLAYER-10 | Stats 所有真实指标、部分空/全空、0/负数/NaN/Infinity 和格式安全 |
| PLAYER-11 | Stats 上下文和竞态正确；无候选时没有假赛季选择器 |
| PLAYER-12 | Career 全部 totals 和 `hasData` 语义正确，空/部分数据安全 |
| PLAYER-13 | 生涯“球队/赛季”切换分别使用 byTeam/bySeason，不新增请求或混用数据 |
| PLAYER-14 | teams 历史时间线、current/loan/日期/统计/unknown 展示及球队跳转 |
| PLAYER-15 | career 与 teams 独立 loading/empty/error/retry/ready，一个失败不遮蔽另一个 |
| PLAYER-16 | API 对六资源的 nullable、空数组、ISO 时间、相对媒体、unknown 字段解析安全，并解析现有比赛摘要字段 |
| PLAYER-17 | 五 Tab 切换与子详情返回保留实际滚动偏移、records 和请求次数 |
| PLAYER-18 | 360/412px、DPR 1、1.4x 下逐个渲染五 Tab并检查 `tester.takeException()` 与 SafeArea |

不要用一个只查文字存在的测试承包多个编号。几何要求须测宽度、列位置、自然高度或单列降级；缓存要求须测滚动前后位置和 repository 调用次数；状态要求须真实切换 fake 返回结果并执行重试。

Widget 测试结束分别恢复 physicalSize、devicePixelRatio 和文字缩放。不得用超宽视口、降低字体、skip 或删除断言绕过问题。

## 完成标准

- 六条球员详情资源进入真实生产渲染；
- 五 Tab 在原型信息结构、交互和状态上形成完整闭环；
- 关注、推荐、分页、刷新、重试、竞态、跳转和返回保持正确；
- 国家队 nullable、退役、unknown、缺图、长文本、极值和无效 ID 安全；
- 生涯球队/赛季切换真实可用，子资源错误隔离；
- 无能力雷达、转会费、荣誉、赛季选择等伪造功能；
- PLAYER-01～PLAYER-18 全部有生产实现和实质测试证据。

## 最小验证

开发过程中只跑必要单文件测试；完成后统一执行一次：

1. `flutter analyze`
2. 运行所有 `test/features/football/f14_player_detail_*` 文件，可在一条 `flutter test` 命令中显式列出
3. 如果抽取/修改 R09 共享分页或内容布局组件，补跑 5 个 `f13_team_detail_*`，确保球队详情不回归
4. `git diff --check`

不要运行整个 football 目录或全仓测试。

## 最终仅汇报

1. 修改文件；
2. 头部、总览、动态、数据、比赛、生涯完成结果；
3. PLAYER-01～PLAYER-18：实际测试名称、关键断言、结果；
4. 最小验证实际命令和测试数量；
5. 阻塞/剩余问题。

仅在全部完成标准和验证通过后输出一次：

`Round 10 Flutter player detail completion passed`

普通编译、测试、夹具和布局失败不是阻塞，必须继续修复。真实外部阻塞出现时不得输出成功标志，并列出对应 PLAYER 编号和所需外部条件。
