# Round 11：Flutter 比赛详情完整原型对齐

## 任务

在 `D:\Football-APP-Front` 当前主目录完成比赛详情页面族，对齐现有比赛详情原型，并基于当前 Backend V1 的比赛基础详情、overview、lineups、team stats、player stats、ratings 能力闭环“总览、阵容、当前排名、统计、评分”五个 Tab。不修改后端、数据库和 API 契约。

本轮是一次完整的比赛详情交付，不是只更换头部颜色或补少量测试。除非缺少必要契约、权限或外部服务且无法安全降级，否则不得因编译错误、测试失败、布局问题、夹具不足或旧实现缺陷停下；必须继续定位、修复并完成全部 MATCH 编号。普通范围内问题不是阻塞。

## 原型与允许范围

先查看并理解信息结构：

- `C:\Users\hekmatyar\Desktop\足球APP\球比赛详情-总览.png`
- `C:\Users\hekmatyar\Desktop\足球APP\球比赛详情-阵容.png`
- `C:\Users\hekmatyar\Desktop\足球APP\球比赛详情-排名.png`
- `C:\Users\hekmatyar\Desktop\足球APP\球比赛详情-统计.png`
- `C:\Users\hekmatyar\Desktop\足球APP\比赛详情-评分.png`
- `C:\Users\hekmatyar\Desktop\足球APP\比赛详情-评分(1).png`
- `C:\Users\hekmatyar\Desktop\足球APP\比赛详情-评分输入.png`

只读取和修改比赛详情直接相关文件：

- `apps/mobile/lib/features/football/presentation/pages/match_detail_page.dart`
- `apps/mobile/lib/features/football/presentation/controllers/match_detail_controllers.dart`
- `apps/mobile/lib/features/football/domain/match_detail_models.dart`
- `apps/mobile/lib/features/football/data/match_detail_api.dart`
- 必要的 match detail repository、router、共享 football widget
- 仅在确实复用时，小幅使用 R08～R10 已通过的比赛卡片、排行行、分页、错误保留和详情头部能力
- `apps/mobile/test/features/football/f15_match_detail_*`
- 项目 `AGENTS.md`、现有 Design Token 和已安装 Skills

原型决定视觉层级与信息组合，不是数据契约。先核对现有模型真实字段，再决定模块是否展示；截图中的集锦、评论、伤病、教练、阵型坐标、事件图标、淘汰树等若无真实字段，不得伪造。

## 禁止范围

- 不修改 Spring Boot、数据库、SQL、接口地址、请求参数或响应结构；
- 不新增依赖，不扩展通知、私信、视频、评论、推荐行为或实时比分能力；
- 不制造阵型坐标、伤病名单、教练、球员照片、事件、排名、统计、评分或评论；
- 不把原型里的切尔西、莱斯特城、比分、球员、比赛时间或示例数值写进生产路径；
- 不把 `CURRENT_STANDING` 解释为预测排名、淘汰树或历史轮次；
- 不制造无行为的筛选器、球队切换、评分入口或“查看更多”；
- 不启动模拟器，不 build APK，不跑整个 football 目录、全仓测试或旧轮次脚本。

## 连续执行规则

按 Gate 0～7 顺序推进，每个 Gate 同时完成生产代码和对应行为测试。先核对现有入口、模型、状态和两份 F15 基线测试，建立内部清单即可，不输出长计划。测试名称写了编号但没有对应行为断言，视为未完成。

执行过程中：

1. 首次失败用于定位根因，修复后继续重跑，不得把普通失败写成“剩余问题”；
2. 测试夹具缺字段时，应按真实模型补夹具，不得弱化生产要求；
3. 如果发现同一 Gate 的现有代码有明确范围内缺陷，直接最小修复；
4. 只有真实缺少契约、授权或外部服务，且没有安全降级路径时才能停止，并明确对应 MATCH 编号、证据和所需条件；
5. 全部编号、静态分析和指定测试通过前，不得输出成功标志。

### Gate 0：真实契约与基线

- 核对基础 `MatchDetail` 与 `MatchOverviewV1`、`MatchLineups`、`MatchTeamLineup`、`MatchLineupPlayer`、`MatchTeamStatItem`、`MatchPlayerStat`、`MatchRanking`、`MatchStandingSnapshot`、`MatchRatingSummary/Result` 的真实字段、nullable、unknown 和 ID 语义；
- 核对基础详情与 overview 是否为不同真实资源，明确事件、赛况报告、当前排名来自哪条现有调用链，不创建重复数据层；
- 核对 lineups、team stats、player stats、ratings 及评分提交/取消的真实参数和返回值；
- 先运行现有两个 `f15_match_detail_*` 基线测试，范围内失败直接修复；
- 保留推荐 `DETAIL` 只上报一次，不能因 rebuild、刷新或 Tab 切换重复。

### Gate 1：深色比赛头部、导航与页面生命周期

- 按原型建立深色球场氛围头部，但只能使用已有资源和语义 Token；没有合法背景资产时使用深色渐变，不下载或生成球场图；
- 头部展示真实赛事/轮次、开赛时间、状态、主客队徽/名称、比分或 `VS`。未开始、进行中、半场、已结束、延期、取消、unknown、缺比分/时间/队徽都要自然降级；
- 主客队 ID 有效才允许进入球队详情，无效 ID 不响应；长中英文队名、极端比分和 1.4x 字体不重叠；
- 返回优先 `pop`，无历史时回 `/app/data`；无效 matchId 显示错误态且零业务请求；
- 五个 Tab 使用稳定 Key，顺序与原型一致：评分、总览、阵容、当前排名、统计；窄屏允许横向滚动，选中态清晰；
- 保持每个 Tab 已加载内容与真实滚动位置，来回切换不重复首屏请求；子详情返回后仍停留原 Tab 和原偏移。

### Gate 2：总览与事件时间线

- 使用真实 overview/base detail 组织赛况报告和事件；没有报告时模块自然隐藏或显示明确空态，有效 `reportContentId` 才进入现有内容详情；
- 事件按真实比赛时间稳定排序，同分钟保持原始顺序；支持 minute、extraMinute、period、score、team、player、assistPlayer、detail 和 unknown eventType 的安全展示；
- 以主客方向形成清晰时间线，进球、乌龙、点球、黄/红牌、换人等仅在现有枚举/字段可识别时使用图标，unknown 使用中性展示而非猜测；
- 有效球员、助攻球员、球队 ID 才可跳转；缺失或非法 ID 不误跳；
- 不实现原型中的视频集锦和评论区，除非现有生产模型与路由已经提供真实能力；没有能力时不渲染假卡片；
- 总览需具备 loading、empty、error、retry；ready 刷新失败时保留旧内容并提供可见反馈/重试，不把页面清空。

### Gate 3：阵容

- 分清主队与客队，展示真实球队、formation、首发、替补和 bench；重复球员按稳定业务 ID 去重但不得误合并 ID 缺失的不同记录；
- 当前模型没有球场坐标时，不伪造原型中的阵型站位。改为视觉清晰的主客阵容分区、位置/号码分组或可切换名单；只有真实 formation 文本可以展示；
- 球员行使用真实头像、姓名、号码、位置、是否首发、队长、评分和事件摘要中实际存在的字段；缺头像、号码、位置、评分和 unknown 安全；
- 有效球员 ID 进入球员详情，有效球队 ID 进入球队详情，无效 ID 不响应；
- lineups 独立 loading/empty/error/retry，单边阵容缺失时仍展示另一边；刷新失败保留旧阵容；
- 360/412px 与 1.4x 字体下主客区、长名和密集名单无 overflow，不使用固定高度裁切。

### Gate 4：当前排名

- 只使用 `MatchRanking` 和 `MatchStandingSnapshot`；仅 `rankingType == CURRENT_STANDING` 且数据可用时展示“当前排名”；
- 完整展示真实排名、球队、场次、胜/平/负、进失球、净胜球、积分及模型内已有的赛事/赛季/阶段上下文；空字段不伪造为 0；
- unknown rankingType、缺少双方 snapshot 或 unavailable 时显示明确安全空态，不误画淘汰树，不跳球队榜；
- 主客任一 snapshot 存在时都要保留可用一方；有效球队 ID 可跳转，无效 ID 不响应；
- ranking 独立 loading/empty/error/retry，刷新失败保留旧排名；不被其他 Tab 错误污染。

### Gate 5：统计

- 将球队统计和球员统计拆为两个独立可见子模块，分别处理 loading/empty/error/retry；任一失败不得遮蔽另一个成功模块，重试只能请求失败目标；
- 球队统计按真实 category/label/displayValue/unit 分组，主客值清楚对齐。只有两侧可解释、有限的数字且比例有意义时才画对比条；null、文本、负数、NaN、Infinity、百分号和 unknown unit 使用安全文字展示，不生成误导比例；
- 球员统计完整展示模型已有字段，按真实 teamId/position 参数提供筛选时，候选只能来自当前比赛双方和已返回数据；没有候选就不渲染假筛选；
- 球员行有效 ID 可进入球员详情，无效 ID 不响应；缺失数据不渲染大块 `—`；
- player stats 支持首屏、分页 busy 防重、ID 去重、append 失败保留记录并重试原页、到底、刷新失败保留旧数据；切换真实筛选时重置页码并防止旧请求覆盖；
- 360/412px、1.4x 字体下统计标签、数值、对比条与球员行不溢出。

### Gate 6：评分列表与评分输入

- 评分列表按真实主客队关联展示或筛选；如果 API 没有第三种分类，不制造“其他”。球队筛选必须使用真实 teamId，切换后请求/列表不串数据；
- 卡片清楚区分官方评分、用户平均分、评分人数和“我的评分”，处理 null、0、负数、NaN、Infinity、空 distribution 和 unknown；有效球员 ID 才可进入详情；
- 评分输入复用当前后端允许的评分范围和精度，不根据原型擅自改成五星或任意步长；打开时回显 currentUserRating，提交期间 busy 防重复；
- 提交成功以 `MatchRatingResult` 权威值更新对应球员，取消成功清除我的评分并更新汇总；一个球员 busy 不应锁死整个页面，重复点击同一球员不重复请求；
- 网络错误与 BusinessException 均回滚到旧值并给用户可见反馈；未登录、无权限、比赛状态不允许、无效 matchId/playerId 时不得假成功；
- load、球队筛选、刷新需有请求代次保护，旧响应不得覆盖最后选择；load/empty/error/retry 与刷新失败保留旧列表必须可观察；
- 仅实现现有评分业务，不实现原型中的评分评论、回复、点赞、媒体热评或第三方分享。

### Gate 7：状态隔离、响应式与回归

- overview、lineups、ranking、team stats、player stats、ratings 的错误和重试互相隔离；一个资源失败不得造成整个比赛详情白屏；
- 五 Tab 切换、刷新及子详情往返保持选中 Tab、各自滚动偏移、records、筛选和请求次数；
- 页面底部 SafeArea 正常；360px、412px、DPR 1、1.4x 字体下逐个真实切换五 Tab，检查 `tester.takeException()`，无 overflow/debug 条纹；
- 不出现“后端未提供”、生产 mock、原型示例、TODO、死按钮、假数据或 unknown 导致的崩溃；
- 不回归现有球队、球员、内容、数据页和 Feed 的比赛详情跳转。

## 强制验收矩阵

扩充现有 `f15_match_detail_api_test.dart`、`f15_match_detail_widget_test.dart`，并按职责新增 controller/sections/responsive 测试。每个编号必须有实质实现与可定位的行为断言。

| 编号 | 必须验证的行为 |
| --- | --- |
| MATCH-01 | 深色头部真实赛事/时间/状态/球队/比分，缺图、长名、极端比分、全部主要状态和 unknown 安全 |
| MATCH-02 | 五 Tab Key/顺序/选中态、返回回退、无效 matchId 零请求 |
| MATCH-03 | 主客队有效 ID 跳转、无效 ID 不跳；推荐 DETAIL 在 rebuild/Tab 切换中仅一次 |
| MATCH-04 | 总览报告显示/隐藏、有效报告跳转、刷新失败保留与目标重试 |
| MATCH-05 | 事件稳定排序、minute/extra/period/score、主客方向、主要类型与 unknown 安全 |
| MATCH-06 | 事件中的球员/助攻/球队有效 ID 跳转与无效 ID 防误跳；无视频/评论伪入口 |
| MATCH-07 | 阵容主客、formation、首发/替补/bench、单边缺失、重复与 nullable 安全 |
| MATCH-08 | 阵容球员真实字段与有效/无效跳转；无坐标时不伪造阵型站位 |
| MATCH-09 | lineups loading/empty/error/retry/refresh-failure-preserve，错误不污染其他 Tab |
| MATCH-10 | CURRENT_STANDING 全字段与语义正确，单边 snapshot 保留，球队跳转安全 |
| MATCH-11 | unknown/unavailable ranking 安全空态，ranking load/error/retry/refresh 独立 |
| MATCH-12 | team stats 分组、单位、文本/有限数字/负数/NaN/Infinity 与对比条安全 |
| MATCH-13 | player stats 真实字段、有效/无效跳转、真实球队/位置筛选和竞态保护 |
| MATCH-14 | player stats loading/empty/error/retry/refresh/append/end、去重、防重和失败保留 |
| MATCH-15 | team stats 与 player stats 双向独立失败、同时失败及各自重试目标正确 |
| MATCH-16 | ratings 主客筛选/关联、官方/用户/人数/我的评分/distribution nullable 与极值安全 |
| MATCH-17 | 评分打开回显、合法范围/精度、提交与取消权威更新、同球员 busy 防重 |
| MATCH-18 | 评分网络/BusinessException/登录权限失败回滚提示，无效 ID 零请求，旧响应不覆盖新状态 |
| MATCH-19 | 六类 API 资源的 Result/PageResult、空数组、ISO 时间、相对媒体、nullable、unknown 解析安全 |
| MATCH-20 | 五 Tab/子详情返回保持实际滚动偏移、筛选、records 与 repository 调用次数 |
| MATCH-21 | 360/412px、DPR 1、1.4x 下逐 Tab 渲染、SafeArea、长文本和 `tester.takeException()` 无异常 |
| MATCH-22 | overview/lineups/ranking/team stats/player stats/ratings 状态与重试互不污染，现有路由回归 |

不能用一个仅查文字存在的测试承包多个编号。几何项须断言宽度、位置、滚动或没有异常；缓存项须断言实际偏移与 repository 调用次数；状态项须让 fake 真实经历 loading/failure/retry/ready；评分项须断言请求参数、调用次数、回滚和权威返回值。

Widget 测试结束分别恢复 physicalSize、devicePixelRatio 和文字缩放。不得用超宽视口、降低字体、skip、删除断言或仅捕获异常来绕过问题。

## 完成标准

- 比赛头部及总览、阵容、当前排名、统计、评分五 Tab 全部进入真实生产渲染；
- 六条读取资源及评分写操作在 nullable、unknown、空态、错误、刷新、竞态下安全；
- 总览时间线、阵容名单、CURRENT_STANDING、双层统计、评分交互形成完整闭环；
- 跳转、推荐一次性、分页、刷新、重试、错误隔离、Tab/滚动保持正确；
- 无假阵型坐标、淘汰树、视频、评论、评分数据或原型示例；
- MATCH-01～MATCH-22 全部有生产实现和实质测试证据。

## 最小验证

开发中只跑必要单文件测试；完成后统一执行一次：

1. `flutter analyze`
2. 将所有 `test/features/football/f15_match_detail_*` 文件显式列在一条 `flutter test` 命令中运行
3. 若修改 R08～R10 共享 football widget/controller，只显式补跑受影响的对应单文件，不跑整个 football 目录
4. `git diff --check`

## 最终仅汇报

1. 修改文件；
2. 头部、总览、阵容、当前排名、统计、评分完成结果；
3. MATCH-01～MATCH-22 对应的实际测试名称、关键断言和结果；
4. 最小验证实际命令及测试数量；
5. 阻塞/剩余问题。

仅在全部完成标准与验证通过后输出一次：

`Round 11 Flutter match detail completion passed`

若仍有任一 MATCH 编号缺实现或缺实质测试，继续执行，不要提前汇报。只有真实外部阻塞才允许停止，且不得输出成功标志。
