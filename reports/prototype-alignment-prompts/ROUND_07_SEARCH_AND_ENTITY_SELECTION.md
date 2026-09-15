# 第 07 轮执行 Prompt：全局搜索与实体选择完整对齐

## 任务

在 `D:\Football-APP-Front` 完成搜索与实体选择业务域：对齐全局搜索、搜索历史、分类结果、分页与详情返回状态；完善文章关联选择；把首次引导中的主队、关注球队、关注球员选择界面复用为统一的绿色搜索选择体验。持续执行至 SEA-01～SEA-13 全部通过；除非存在有证据且范围内无法解决的真实阻塞，否则不得提前停止。

## 持续执行规则

1. 直接实现，按全局搜索、选择模式、首次引导复用、测试四阶段连续推进，不输出计划后停止。
2. 编译错误、测试失败、竞态、fake 不足、布局溢出和实现复杂都不是阻塞，必须定位并修复。
3. 不得删除或弱化已有 F10 搜索断言，不得跳过测试、硬塞演示结果、用任意延时掩盖 debounce/竞态，也不得以“后续补测试”结束。
4. 仅当必要契约不存在、必须越权修改禁止范围、或环境持续不可用且替代方案也失败时才能停止，并提供命令、错误和尝试证据。
5. 当前仍以现有 Repository 边界和本地 fake/mock 验证界面；不得为还原截图修改后端或在 Widget 中硬编码球队、球员、比赛、内容数据。

## 原型参考

- `C:\Users\hekmatyar\Desktop\足球APP\搜索结果空.png`
- `C:\Users\hekmatyar\Desktop\足球APP\选择主队.png`
- `C:\Users\hekmatyar\Desktop\足球APP\选择球队.png`
- `C:\Users\hekmatyar\Desktop\足球APP\选择球员.png`

`暂无关注球队.png` 仅作为后续空态视觉参考，本轮不要把首次引导页错误地当作常规关注管理页，也不要修改 Feed 关注频道业务。

## 允许范围

- `features/search` 的 domain 复用、presentation controller/page/widget 和必要 data 边界适配
- `/search`、`/relations/select` 及必要的选择模式路由参数
- `features/onboarding` 的选择页/局部组件/controller 状态保持，不修改保存契约
- search/onboarding/content relation 的定向测试与测试 fake
- 无新增依赖的会话级搜索历史 store/provider

禁止修改后端、数据库、Search API 契约、onboarding preferences 请求结构、Feed、发布主体、内容详情、球队/球员/比赛详情、登录方式、关注上限规则和全局依赖。不得重新引入“最多 4/5 支球队”硬限制。

## 阶段一：全局搜索页面与状态

1. 对齐原型的白色页面、返回标题、浅灰圆角搜索框和绿色状态；复用 Design Token、实体头像/队徽与 `SearchResultTile`，禁止页面散落新颜色。
2. 搜索支持键盘 search、显式提交和短 debounce 输入搜索；同一标准化关键词不重复请求，空白关键词不请求并回到 idle/history。
3. 支持全部、TEAM、PLAYER、MATCH、CONTENT 五种筛选。切换分类保留输入关键词但清空旧结果/页码/错误；慢旧请求不得覆盖新关键词或新分类。
4. 覆盖 idle、loading、empty、failure/retry、ready、loadingMore、append failure/retry、到底；空态按原型居中，不显示误导性的“重试”按钮。
5. 分页按 `stableKey` 去重，防重复触发；追加失败保留已有结果。unknown/缺失 id 安全展示但不可误跳。
6. 四类有效结果跳现有球队、球员、比赛、内容详情。返回后保留关键词、分类、已加载页、结果、错误恢复状态和滚动位置，不重新请求第一页。

## 阶段二：会话级搜索历史

1. 不新增依赖，建立 search presentation 范围内的会话级历史 store/provider；历史只记录标准化后的非空、已实际提交搜索词，去重后最近优先，数量设一个明确小上限。
2. idle 状态显示最近搜索，可点击重新搜索、删除单项和清空全部；无历史时保持简洁引导。
3. 失败搜索是否记录遵循一致规则，推荐只在已发起有效请求时记录；不得记录空白、连续重复或分类标签。
4. 历史在搜索页 push 到详情并返回时保持；退出并重新进入搜索页时在当前 App 会话内仍存在。不得使用 token storage 保存普通搜索词。

## 阶段三：文章关联选择模式

1. `/relations/select` 继续复用全局搜索模型，只允许 TEAM/PLAYER/MATCH；CONTENT 和 unknown 不可选择，也不能因混合页先返回不可选项而错误显示“无结果”。
2. 初始已选项进入页面后保持；切换关键词、分类、分页和失败重试不会丢失选择。按 `stableKey` 去重，最多 10 项。
3. 结果行清楚显示选中/未选中；再次点击取消。完成返回稳定顺序的选择列表；系统返回/取消不修改文章原选择。
4. 空关键词不发请求；选择页可使用历史关键词辅助搜索，但历史本身不能被当作选择结果。
5. 从 ArticleEditor 打开、选中、取消、完成、返回后 chip 展示与删除形成真实 Widget 流程；不得只单测 `setRelations()`。

## 阶段四：首次引导选择界面复用

1. 保留现有三步 onboarding controller 与 preferences 保存契约，只重构选择表现和必要的本地过滤状态。
2. 对齐绿色沉浸头部、说明文字、圆角搜索框、白色圆角结果区和底部上一步/下一步按钮；适配状态栏、SafeArea、键盘和长列表。
3. 主队步骤只能选择一支，选择主队自动包含在关注球队中；未选主队不能进入下一步，并提供明确提示。
4. 关注球队和关注球员支持在当前已加载 options 中本地搜索、空态、选择/取消和返回保持；不得发无契约的全局搜索请求，也不得新增 4/5 支上限。
5. 队徽、头像、联赛/国家、球队/位置字段 nullable 安全；长名称和图片失败使用现有 fallback。
6. 上一步/下一步来回后，主队、球队、球员选择与各步搜索词保持；最终提交期间禁用重复操作，失败保留全部选择并可重试。

## 强制行为级测试

使用可控制延迟、分页、异常和调用记录的 fake。每项必须对应具体测试名称和可观察断言。

| 编号 | 强制验收结果 |
| --- | --- |
| SEA-01 | 空白不请求；提交/debounce 同词去重且键盘搜索可用 |
| SEA-02 | 五类筛选重置分页，旧关键词/分类请求不能污染新结果 |
| SEA-03 | idle/loading/empty/error/retry/ready 状态视觉正确 |
| SEA-04 | 分页去重、防重复、追加失败重试、保留旧列表与到底 |
| SEA-05 | TEAM/PLAYER/MATCH/CONTENT 跳转正确，unknown/缺失 id 不误跳 |
| SEA-06 | 详情返回后关键词、分类、结果、页码和滚动位置保持且不重复首刷 |
| SEA-07 | 搜索历史新增、标准化、去重、限长、删除、清空和会话保持 |
| SEA-08 | 关联选择只允许三类，初始选择、跨筛选保持、取消与上限 10 正确 |
| SEA-09 | ArticleEditor 打开关联页、完成返回 chip、取消不改、删除 chip 闭环 |
| SEA-10 | onboarding 主队单选、自动关注、未选阻止下一步 |
| SEA-11 | 球队/球员本地过滤、空态、无硬上限、前后步骤选择保持 |
| SEA-12 | onboarding 提交防重复、失败保持与重试；既有保存参数不变 |
| SEA-13 | 412px、DPR 1、1.4 倍字体、键盘和 SafeArea 无溢出；Round 06 发布关联流程不回归 |

## 最小验证

完成后统一运行：

- `flutter analyze`
- search controller/page/history/selection 定向测试
- onboarding controller/widget 定向测试
- `flutter test test/features/search`
- `flutter test test/features/onboarding`
- `flutter test test/features/content/f11_article_flow_widget_test.dart`
- `flutter test test/features/content/f12_publish_composer_widget_test.dart`
- `git diff --check`

不跑全仓测试，不启动模拟器，不 build APK，不进入数据中心下一轮。

## 最终汇报

仅在全部完成或符合定义的真实阻塞后汇报：

1. 修改文件；
2. 全局搜索、历史、关联选择和 onboarding 完成结果；
3. SEA-01～SEA-13 对照表，每项写具体测试名称与通过/未通过；
4. 各验证命令和实际测试数量；
5. 阻塞；无则写“无”。

全部通过后输出：

`Round 07 Flutter search and entity selection passed`
