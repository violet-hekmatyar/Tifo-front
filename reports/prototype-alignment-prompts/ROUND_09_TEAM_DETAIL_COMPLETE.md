# Round 09：Flutter 球队详情完整原型对齐

## 任务

在当前 Flutter 项目中，将球队详情页面完整对齐现有原型，并使用已经存在的 Backend V1 模型与 repository 能力闭环 `overview / players / stats / honors / matches / contents`。本轮覆盖球队详情头部，以及“总览、动态、球员、数据、赛程”五个 Tab；不修改后端、数据库和 API 契约。

这是一轮完整页面族交付，不是只调整头部或卡片颜色。除非缺少必要契约、权限或外部服务且无法安全降级，否则不要因编译错误、测试失败、布局问题或发现旧缺陷而停止；这些都属于本轮应继续修复并验证的事项。

## 依据与允许读取范围

先查看以下原型：

- `C:\Users\hekmatyar\Desktop\足球APP\球队详情-总览.png`
- `C:\Users\hekmatyar\Desktop\足球APP\球队详情-帖子.png`
- `C:\Users\hekmatyar\Desktop\足球APP\球队详情-球员.png`
- `C:\Users\hekmatyar\Desktop\足球APP\球队详情-数据.png`
- `C:\Users\hekmatyar\Desktop\足球APP\球队详情-数据选择.png`
- `C:\Users\hekmatyar\Desktop\足球APP\球队详情-赛程.png`
- `C:\Users\hekmatyar\Desktop\足球APP\球队详情-榜单查看全部.png`

只读取和修改球队详情直接相关文件及其依赖：

- `apps/mobile/lib/features/football/presentation/pages/team_detail_page.dart`
- `apps/mobile/lib/features/football/presentation/controllers/team_detail_controllers.dart`
- `apps/mobile/lib/features/football/domain/team_detail_models.dart`
- `apps/mobile/lib/features/football/data/team_detail_repository.dart`
- `apps/mobile/lib/features/football/data/team_detail_api.dart`
- 必要的共享 football widget、Feed/Content/Match 组件和 router
- `apps/mobile/test/features/football/f13_team_detail_*`
- 项目 `AGENTS.md`、现有 Design Token 和已安装 Skills

原型只决定视觉结构与信息优先级，当前 API/model 才是数据权威。不得为了还原截图扩展或猜测字段。

## 禁止范围

- 不修改 Spring Boot、数据库、SQL、API 路径、query 参数或响应结构；
- 不新增依赖，不做无关重构，不修改球员详情或比赛详情内部实现；
- 不实现球队身价、动态球队主题色、主队设置、收藏比赛、完整队内榜单接口等当前契约没有的能力；
- 不根据球队名称硬编码巴塞罗那、队徽、球员、比赛、荣誉、排名、颜色或统计；
- 不把测试 fake/mock 放入生产路径；
- 不制造“查看全部”“选择赛季”“加为主队”等无真实行为的按钮；
- 不启动模拟器，不 build APK，不跑全仓测试或 F01–F08 旧阶段脚本。

如果现有契约没有球队身价，只展示真实存在的英文名、城市、联赛、关注数等合适信息；不要显示截图中的虚假身价。如果没有主队设置契约，保留真实关注/取消关注，不把它改名伪装成“加为主队”。如果没有球队可选赛季列表，显示 overview 或 Round 08 上下文中的真实赛季；只有确有可用选项时才提供可操作的选择器。

## 连续执行方式

按 Gate 0～6 顺序推进。每个 Gate 同时完成生产代码和对应测试后再继续。首次测试失败用于定位根因；只要问题仍在本轮范围内，就继续修复并重跑。不得用“后续补测试”“现有逻辑保留”“只做了基础版”宣告完成。

### Gate 0：契约和现状基线

- 核对 `TeamDetail` 与 `TeamOverview/TeamStats/TeamHonor/TeamRosterPlayer/TeamContentSummary` 的 nullable 和 unknown 字段；
- 核对 overview、players、stats、honors、matches、contents 六条调用链及分页参数；
- 核对当前从数据榜、搜索、Feed 进入球队详情，以及从球队详情进入球员、比赛、内容详情的路由；
- 运行现有 `f13_team_detail_*` 作为基线；已有范围内失败必须修复；
- 保持推荐 `DETAIL` 行为只上报一次，不因 Tab 切换或 rebuild 重复上报。

### Gate 1：沉浸式球队头部与 Tab 骨架

- 将普通 AppBar + 分离式头部调整为接近原型的沉浸式头部：返回、队徽、球队名称、可用的辅助信息、关注按钮和五个 Tab 形成一个连续视觉层级；
- 原型酒红色只作为层级参考。使用可维护的语义 Token/既有品牌色，不根据队名猜球队主题色，也不硬编码某支球队颜色；
- 缺队徽、超长中英文球队名、空英文名、空关注数和未知字段自然降级；
- 关注按钮支持关注/取消关注、busy 防重复、成功后状态准确、失败保持原状态并反馈；无效球队 ID 不发操作；
- 五个 Tab 使用稳定 Key，选中态清晰，可在窄屏横向滚动或自适应，不出现五项被压缩污染；
- Tab 切换保留各自滚动位置和已加载分页记录，不因 `IndexedStack` rebuild 重复首屏请求；
- 返回优先 pop，无历史时回到 `/app/data`；保留推荐 attribution/source。

### Gate 2：总览完整模块

按真实字段组合以下模块，字段为空时模块级隐藏或显示明确空态，不留大块空白：

1. 下一场比赛：复用已通过的比赛卡片；仅 `nextMatch` 存在时显示，点击进入比赛详情。
2. 赛事排名：展示 overview 中真实 `standing`（当前排名、场次、胜平负、进失球/净胜球、积分）；语义必须是当前排名，不自行计算。
3. 最近比赛：使用 `recentMatches`，按已有展示排序，数量以响应数据为准；点击进入比赛详情。
4. 最新动态：使用 `recentContents`，复用现有内容视觉语言；点击进入内容详情。存在更多完整内容时，可通过切换“动态”Tab 查看，但不要伪造总数。
5. 队内榜单：分别展示 `topScorers` 与 `topAssists`；名次、头像、球员名、进球/助攻只使用真实字段。没有完整榜单契约时不要提供误导性的独立“查看全部”页；可让有效球员进入球员详情。
6. 基础资料：联赛、赛季、城市、主场、成立年份、description 按真实字段展示。
7. 球队荣誉：按荣誉类型/名称展示冠军次数、年份或最近年份；空年份和 unknown 类型安全，点击不存在的能力不做假跳转。

总览内部子请求必须彼此隔离：荣誉失败不能让 overview 整页消失；重试只刷新失败模块。412px、1.4 倍字体下卡片、榜单和事实字段不溢出。

### Gate 3：动态 Tab

- 将 `contents` 分页结果对齐原型双列错落内容流，优先复用 Round 03 已通过的瀑布流/内容卡片设计原则；若 `TeamContentSummary` 与 Feed DTO 不兼容，建立窄适配组件，不伪造缺失作者或热评字段；
- 展示真实封面、标题、类型、发布时间、点赞数和评论数；无封面卡片自然收起图片区；
- 有效 ID 点击进入内容详情，无效 ID 不误跳；
- 首屏 loading/empty/error/retry、分页 loading、append error 保留旧记录并重试同页、ID 去重、到底状态完整；
- 两列在 360/412px 与 1.4 倍字体下无等高空白和 overflow；必要时在更窄或更大字体下降级单列，但不能裁字或越界；
- 切换离开再返回保持关键词无关的现有列表、分页与滚动位置，不重复请求首屏。

### Gate 4：球员 Tab

- 阵容按后端 `position` 分组，明确处理 GOALKEEPER、DEFENDER、MIDFIELDER、FORWARD、null 和 unknown；分组顺序稳定，不因分页追加错乱；
- 球员卡片对齐原型的强信息层级，展示真实号码、头像、姓名、位置/角色、队长、租借、出场、进球、助攻、评分等存在字段；不显示虚构年龄、国籍、身价；
- 可在足够宽度使用双列卡片，在大字体/长名字下自适应，不允许固定高度裁切内容；
- 有效球员 ID 进入现有球员详情，无效 ID 不误跳；
- loading/empty/error/retry、分页追加/失败重试/去重/到底状态完整；
- 未知 position/squadRole 显示可理解的安全文案，不能把后端原始乱码直接撑破布局。

### Gate 5：数据 Tab

- 使用现有 `stats` 字段重组为原型风格的数据分区，例如排名与赛季概览、进攻、组织/纪律等；仅基于真实字段分类；
- 展示 played、goalsFor、goalsAgainst、goalDifference、assists、shots、shotsOnTarget、shotAccuracy、corners、fouls、yellowCards、redCards、cleanSheets、averageRating、standingRank、points 中实际存在的值；
- 可比较的同组数值可使用进度条，但归一化上限必须来自同一响应中有明确关系的值，不能编造联赛最大值或强弱结论；无法可靠归一化时使用数值行；
- `standingRank` 继续表示当前排名；百分比、评分和负净胜球格式正确；NaN/无穷值安全降级；
- season/stage 只使用进入页面时已有的 Round 08 赛季上下文或 overview 返回值。切换上下文时，overview/players/stats 使用同一请求上下文并防旧响应覆盖；没有真实候选列表时只显示当前赛季标签，不展示假选择弹层；
- 支持 loading/empty/error/retry；部分字段为空时保留有数据分区，全空才显示整页空态；
- 360/412px、1.4 倍字体下分区、数值、进度条和筛选标签不溢出。

### Gate 6：赛程 Tab、统一状态与返回保持

- 使用 `matches` 分页数据，复用 Round 08 的比赛卡片、状态、日期分组和排序逻辑；
- 未开始、进行中、已结束、延期、取消、unknown、缺比分/时间/队徽安全；
- 有效比赛/球队 ID 保持现有路由，无效 ID 不误跳；
- 完成 loading/empty/error/retry、分页去重、busy 防重、append error 保留数据并重试原页、到底状态；
- 页面底部为 SafeArea 留足空间；从子详情返回后恢复球队详情原 Tab、列表和滚动位置；
- overview、honors、stats 的重试互不污染；五 Tab 的空态和错误态文案能区分真实无数据与加载失败。

## 强制验收矩阵

补充/重构 `f13_team_detail_api_test.dart`、`f13_team_detail_controller_test.dart`、`f13_team_detail_widget_test.dart`，必要时增加一个专门的响应式 Widget 测试文件。测试名必须包含对应编号；不能只在最终报告中声称覆盖。

| 编号 | 必须验证的行为 |
| --- | --- |
| TEAM-01 | 沉浸式头部、返回、五 Tab Key 与选中态；长球队名、缺队徽、1.4x 字体无异常 |
| TEAM-02 | 关注/取消关注成功、busy 防重复、失败回滚并提示，无效 ID 不请求 |
| TEAM-03 | 推荐 DETAIL 仅上报一次，Tab 切换和 rebuild 不重复 |
| TEAM-04 | overview 将下一场、当前排名、最近比赛、最近内容、射手/助攻、基础资料按真实字段渲染 |
| TEAM-05 | honors 独立 loading/empty/error/retry/ready；nullable 年份、次数、unknown 类型安全 |
| TEAM-06 | 总览中的有效比赛、球员、内容跳转正确；缺失/无效 ID 不误跳 |
| TEAM-07 | 动态双列/自适应布局、缺封面和长标题安全，内容详情跳转正确 |
| TEAM-08 | contents 首屏与分页状态、ID 去重、busy 防重、append 失败保留数据并重试原页 |
| TEAM-09 | players 按位置稳定分组；null/unknown 位置与角色安全，真实号码/队长/租借/统计显示正确 |
| TEAM-10 | 球员列表分页去重、失败重试、到底与有效/无效球员跳转正确 |
| TEAM-11 | stats 分区覆盖全部真实字段；部分空、全空、负数、百分比/评分及 CURRENT_STANDING 语义正确 |
| TEAM-12 | 赛季/阶段上下文一致并拒绝旧响应；无真实候选时不出现假赛季选择器 |
| TEAM-13 | matches 日期分组、排序、所有状态安全；比赛/球队跳转及无效 ID 防误跳 |
| TEAM-14 | matches 分页 busy、去重、append retry/end，以及首屏 loading/empty/error/retry 完整 |
| TEAM-15 | 360px/412px、DPR 1、1.4x 字体下五 Tab 关键页面无 overflow/debug 污染，SafeArea 正常 |
| TEAM-16 | Tab 切换与子详情返回保留 Tab、已加载分页和滚动位置，不重复首屏请求 |
| TEAM-17 | API/model 对 nullable、空数组、ISO 时间、相对媒体 URL、unknown 字段解析不崩溃 |

Widget 测试必须设置真实逻辑宽度与 DPR；结束时分别恢复 `physicalSize`、`devicePixelRatio` 和文字缩放。使用 `tester.takeException()` 验证布局，不得通过超宽视口、降低字体、skip 或弱化断言规避问题。

## 完成标准

- 六条球队详情数据能力均进入真实生产渲染链路；
- 五个 Tab 与原型的信息结构基本一致，且共享 Round 01–08 已通过的设计语言；
- 关注、推荐行为、分页、重试、空态、错误态、竞态和返回保持闭环；
- nullable、unknown、缺图、长文本、大字体和无效 ID 安全；
- 无“后端未提供”旧占位、生产 mock、硬编码截图数据、死按钮或假选择器；
- TEAM-01～TEAM-17 全部有实现和行为测试证据。

## 执行与最小验证

直接修改代码，只读取本任务必要文件，不做全仓扫描。开发期间只跑必要的单文件测试；完成后统一执行一次：

1. `flutter analyze`
2. `flutter test test/features/football/f13_team_detail_api_test.dart`
3. `flutter test test/features/football/f13_team_detail_controller_test.dart`
4. `flutter test test/features/football/f13_team_detail_widget_test.dart`，以及本轮新增的单个 team detail Widget 测试文件
5. 如改动共享比赛组件，仅补跑直接相关的 Round 08 football Widget 测试文件
6. `git diff --check`

不运行整个 `test/features/football`，不跑全仓测试、模拟器或 APK。

## 最终仅汇报

1. 修改文件；
2. 头部、总览、动态、球员、数据、赛程完成结果；
3. TEAM-01～TEAM-17 对照表：实际测试名称与结果；
4. 最小验证实际命令和测试数量；
5. 阻塞/剩余问题。

只有全部完成标准和验证通过后，才能输出一次：

`Round 09 Flutter team detail completion passed`

如果确有不可解决阻塞，不得输出成功标志；列出对应 TEAM 编号、已完成排查、为何不能安全降级，以及所需外部条件。普通编译、测试和布局失败不属于阻塞，必须继续解决。
