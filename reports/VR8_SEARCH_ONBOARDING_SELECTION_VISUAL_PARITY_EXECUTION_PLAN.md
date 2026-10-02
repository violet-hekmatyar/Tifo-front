# VR8 搜索空态与首次偏好选择一比一视觉复刻执行计划

状态：**Plan 复验未通过，转入 VR8-R1；未关闭前不得进入 VR9**  
前置条件：VR7 已通过 Plan 最终复验  
唯一目标：完成全局搜索空结果、选择主队、关注球队、关注球员 4 张原型的真实 API、真实媒体、交互与逐图视觉验收。

执行状态：M0、M1、M2、M3、M4、M5 已完成执行与直接验证，但严格视觉、几何测试和 Rollback 保护仍有缺口；详见 `reports/VR8_REVIEW_2026-09-22.md`，后续唯一入口为 `reports/VR8_R1_SEARCH_ONBOARDING_VISUAL_REPAIR_PLAN.md`。

## 1. 原型与范围

本阶段只验收：

- `C:\Users\hekmatyar\Desktop\足球APP\搜索结果空.png`
- `C:\Users\hekmatyar\Desktop\足球APP\选择主队.png`
- `C:\Users\hekmatyar\Desktop\足球APP\选择球队.png`
- `C:\Users\hekmatyar\Desktop\足球APP\选择球员.png`

允许修改：

- `apps/mobile/lib/features/search/**`
- `apps/mobile/lib/features/onboarding/presentation/**`
- 必要时为 `AppSelectionCard` 增加保持默认行为不变的可选视觉参数
- search/onboarding/auth redirect 的直接相关测试
- VR8 专用 SQL 数据脚本、Manifest、执行记录和视觉证据

明确排除：

- `其他空状态图标.png` 的整套全局空态插画体系
- `/relations/select` 和文章关联选择的视觉重做；共享搜索改动只做回归验证
- 用户中心、设置、粉丝/关注、登录与协议弹层、消息通知
- 手机验证码、一键手机号登录、微信登录、私信、IM、WebSocket、Push 和完整淘汰树
- Feed、发布编辑器、内容详情、足球详情页及已通过的 VR1～VR7 页面

不得新增依赖，不得修改后端 Java、接口字段、请求语义、关注数量上限或路由协议。

## 2. 已核对的真实基线与契约

### 2.1 现有接口即权威契约

- `GET /api/app/search/entities`
  - 参数：`keyword`、可选 `entityType`、`pageNum`、`pageSize`
  - 返回 TEAM、PLAYER、MATCH、CONTENT 分页结果
  - 当前真实无结果关键词已验证为 `HTTP 200 + code=0 + records=0`
- `GET /api/app/onboarding/options`
  - 登录态返回 `recommendedTeams / hotTeams / recommendedPlayers / hotPlayers`
- `POST /api/app/onboarding/preferences`
  - 保持 `mainTeamId / followTeamIds / followPlayerIds` 不变
  - 主队单选并自动进入关注球队；球队和球员不新增 4/5 支硬限制

前端必须复用现有 `ApiClient`、Repository、Controller、鉴权、分页、错误和媒体组件。不得发明新接口、字段或本地生产假数据。

### 2.2 当前数据问题

当前 8080 真实 `onboarding/options` 返回 6 支球队和 6 名球员，数量足够；但这些选项的旧 `/uploads/team/*.png`、`/uploads/player/*.png` 当前返回 JSON 业务错误而非图片，不能作为正式视觉证据。

P1 已验证以下素材可匿名返回 `200 + image/png`，VR8 允许复用：

- `/demo/p1-media/team-crest-crimson.png`
- `/demo/p1-media/team-crest-cobalt.png`
- `/demo/p1-media/player-flagship.png`

只修复当前 options 涉及的 6 队、6 人媒体 URL，不修改名称、联赛、国家、位置、关注数、排序或其他记录。

## 3. 顺序执行模块

必须按 M0 → M5 顺序完成。每个模块完成直接验证后才进入下一模块，不得并行扩展页面族。

### VR8-M0：基线、原型测量与目标冻结

1. 记录前后端 `git status`，保护现有未提交工作；不得清理或覆盖 VR1～VR7 产物。
2. 运行第 5 节列出的 10 个现有测试文件，当前静态基线为 **48 项**；记录实际数量与失败基线，不得删除旧断言。
3. 使用当前 APK 保存搜索空结果和 onboarding 三步 before 截图；不得用旧报告截图代替。
4. 按 750×1624 原型记录四页的状态栏、绿色头部高度、白色面板起点、搜索框、列表卡、爱心、底部按钮、安全区和空态中心位置；以宽高比例换算 dp，不把原型 px 直接当 dp。
5. 通过真实 API 冻结当前 options 的 6 个 teamId、6 个 playerId、原媒体 URL 和目标 P1 URL；若实际 ID 或旧值与 Manifest 不一致，先更新 Manifest 并停止覆盖式执行。

完成门槛：四张原型均有状态映射，48 项测试基线、12 个数据目标和 before 截图可追溯。

### VR8-M1：Onboarding 选项媒体数据修复

后端仓库只新增：

- `scripts/sql/VR8_M1_ONBOARDING_MEDIA_SEED.sql`
- `scripts/sql/VR8_M1_ONBOARDING_MEDIA_VALIDATOR.sql`
- `scripts/sql/VR8_M1_ONBOARDING_MEDIA_ROLLBACK.sql`
- `scripts/sql/VR8_M1_ONBOARDING_MEDIA_MANIFEST.md`

规则：

1. 不新增 Migration，不改 schema，不修改后端 Java。
2. Seed 只更新 M0 冻结的 6 个 `football_team.logo_url` 和 6 个 `football_player.avatar_url`；用 P1 三张 PNG 交替复用。
3. 每条更新必须同时匹配精确 ID 与 Manifest 记录的原 URL；遇到缺行、URL 已被其他任务修改或目标冲突时 `SIGNAL` 拒绝，不得覆盖。
4. Seed 幂等；连续执行两次，第二次影响 0 行或保持相同结果。
5. Validator 验证 12 个目标、API options 引用、PNG 可访问、非目标球队/球员媒体泄漏为 0。
6. Rollback 只在精确 ID 且当前 URL 等于 VR8 目标 URL 时恢复 Manifest 原值；不得删除记录、关系或 P1 媒体。本阶段正式证据保留修复结果，不执行最终 Rollback。

完成门槛：真实 options 仍为 6 队、6 人，引用媒体均能由客户端正常显示；至少三个唯一 P1 URL 匿名为 `200 + image/png`，没有非目标数据变化。

### VR8-M2：全局搜索空结果页复刻

1. `/search` 使用白色页面、浅色状态栏、左返回、居中“搜索”和原型比例的浅灰圆角搜索框；提示文案为“输入关键词搜索”。
2. 真实搜索返回空页时，隐藏结果筛选条、历史、分页尾部和重试按钮，只显示居中的绿色/深灰搜索无结果插画与“搜索无结果”。
3. 插画可使用本地专用资产或代码绘制，但只能实现搜索无结果这一种，不顺手改造全局 `AppStateView` 或其他页面；不得把整张原型作为背景。
4. failure 与 empty 严格区分：网络/业务失败继续显示错误与真实重试；空结果不能伪装成错误。
5. 保留 ready 状态的五类筛选、分页、历史、详情跳转、返回状态和竞态保护；视觉修改不得让这些既有能力回归。
6. 使用真实唯一无结果关键词完成 API 与 Android 证据，不在 Widget 中注入假空列表作为正式截图。

完成门槛：`搜索结果空.png` 有真实空结果、结构/几何测试和当前 APK 对照；ready/failure/历史能力不回归。

### VR8-M3：三步首次偏好选择复刻

共享页面骨架：

1. 绿色沉浸头部占首屏约三分之一，使用渐变和轻量代码纹理；不得把原型截图用作背景。
2. 头部只保留当前步骤大标题、说明和半透明圆角搜索框；移除原型没有的“南看台·首次设置”横栏、步骤圆点和白色面板内“步骤 x/3”。
3. 白色大圆角结果面板从绿色头部下方衔接，包含“搜索结果”、可滚动列表和固定 SafeArea 操作区。
4. 结果卡使用真实队徽/头像、名称、副标题、浅边框与右侧爱心；选中为红色实心爱心，未选为浅灰空心爱心。不得用选中绿色整卡替代原型表现。
5. 如扩展 `AppSelectionCard`，新增参数必须可选且默认值保持其他页面现状；不得全局改变旧页面。

三个步骤：

- 主队：标题“我的主队”，球队单选；未选不能继续，选中主队自动加入关注球队；底部只有全宽“下一步”。
- 球队：标题“关注的球队”，可多选/取消，不添加数量上限；底部“上一步 + 下一步”。
- 球员：标题“关注的球员”，可多选/取消；底部“上一步 + 下一步”，最后一次点击执行既有 preferences 提交。

搜索和状态：

- 球队步骤只搜球队名称、联赛、国家；球员步骤只搜球员、球队、位置。
- 三个搜索词、选择集合和列表 ScrollPosition 在前后切换后保持。
- 局部无匹配时在白色面板内显示简洁文字空态，底部按钮仍可达；不调用不存在的服务端搜索。
- loading、整页 empty、failure/retry 和提交失败继续真实可用，但不得伪造 options。
- 长名称、null 副标题、图片失败有稳定降级；正式截图必须使用 M1 的可访问真实媒体，不接受首字母占位作为正常态证据。

完成门槛：三张选择原型各自形成真实 API、真实媒体、正确选择规则和逐图对照；完成提交后真实用户进入首页。

### VR8-M4：交互、响应式与契约回归

1. 使用一个唯一 VR8 验收账号完成注册/登录 → 主队 → 球队 → 球员 → preferences → `/api/auth/me` 回读；不修改或覆盖既有 DEMO 用户。
2. preferences 只提交一次；失败测试使用 fake，不在真实环境重复制造关系。记录验收用户 ID，报告不得记录密码或 Token。
3. 标准 Pixel 8、360dp 和 140% 字体下实际完成搜索空态和三步选择；键盘打开时搜索框、当前列表和底部按钮可达，无 overflow/遮挡。
4. 主队单选/自动关注、球队/球员多选、返回保持、重复提交防护、失败保留和最终路由均有直接测试。
5. `/relations/select`、ArticleEditor 关联返回及 VR7 发布入口只跑定向回归，不修改其视觉。

完成门槛：四张原型相关主链均可真实操作，适配状态可达，现有 API 请求体与路由语义不变。

### VR8-M5：同 APK 视觉证据与提交复验

从最终源码构建并安装一个 APK，记录完整 SHA-256。新建：

`reports/VR8_SEARCH_ONBOARDING_VISUAL_PARITY_EVIDENCE`

至少包含：

- `00_before_search_empty.png`
- `00_before_onboarding.png`
- `01_search_empty.png`
- `02_main_team.png`
- `03_followed_teams.png`
- `04_followed_players.png`
- `05_selection_persisted_after_back.png`
- `06_width_360dp.png`
- `07_font_140.png`
- `08_completed_home.png`
- `comparison_01_search_empty.png`
- `comparison_02_main_team.png`
- `comparison_03_followed_teams.png`
- `comparison_04_followed_players.png`
- `APK_HASH.txt`
- `EXECUTION_RECORD.md`
- `VISUAL_COMPARISON.md`

四张 comparison 必须是“原型 + 当前 APK”的真实并排或叠加图。每张记录结构、几何、字体、颜色、图片比例、剩余差异和结论；不得复制原型冒充对照。所有正式 after 图来自同一 APK，采证后恢复设备参数。

完成门槛：第 4 节全部通过；执行模型只提交 Plan 模型复验，不自行宣布 VR8 通过或进入 VR9。

## 4. 强制验收矩阵

| 编号 | 必须验证 |
| --- | --- |
| VR8-01 | 搜索头部、搜索框、插画、空态文字和中心几何接近原型 |
| VR8-02 | 真实空结果为 code=0/records=0，不显示筛选、历史、分页或误导重试 |
| VR8-03 | 搜索 idle/loading/failure/ready、五类筛选、分页、历史、竞态和详情返回不回归 |
| VR8-04 | 三个选择步骤共享绿色头、白色圆角结果面板和固定底部操作区 |
| VR8-05 | 卡片真实队徽/头像、红色实心/灰色空心爱心、长文本和媒体失败正确 |
| VR8-06 | 主队单选、必选、自动关注；球队/球员多选且无 4/5 支限制 |
| VR8-07 | 三步本地搜索、清空、局部空态、搜索词/选择/滚动位置往返保持 |
| VR8-08 | preferences 防重、失败保留、成功回读 onboardingCompleted/mainTeamId 并进入首页 |
| VR8-09 | loading、整页 empty、error/retry 使用真实状态且不伪造数据 |
| VR8-10 | 标准、360dp、140% 字体和键盘下四页无 overflow、遮挡或不可达按钮 |
| VR8-11 | 12 行媒体修复幂等、可校验、可回滚、非目标泄漏为 0 |
| VR8-12 | `/relations/select`、文章关联和 VR1～VR7 共享组件行为不回归 |

几何测试必须使用 `tester.getRect`、ScrollPosition 或相对位置断言，不得只查找文字或 Widget 是否存在。不得通过放大测试视口、降低字体或正式 fixture 截图绕过问题。

## 5. 最小最终验证

先运行并保留以下现有 48 项基线，完成后加上 VR8 新增几何/交互测试，总数不得低于 **52 项**：

- `test/features/search/search_entity_dto_test.dart`
- `test/features/search/global_search_controller_test.dart`
- `test/features/search/global_search_page_test.dart`
- `test/features/onboarding/onboarding_controller_test.dart`
- `test/features/onboarding/onboarding_widget_test.dart`
- `test/features/onboarding/f19_onboarding_api_contract_test.dart`
- `test/features/onboarding/f19_onboarding_acceptance_test.dart`
- `test/features/auth/f19a_auth_onboarding_visual_acceptance_test.dart`
- `test/features/auth/f19_auth_onboarding_acceptance_test.dart`
- `test/app/router/auth_redirect_test.dart`

另执行：

1. `flutter analyze`。
2. VR7 共享回归：`f11_article_flow_widget_test.dart` 与 `f12_publish_composer_widget_test.dart`。
3. 真实 API smoke：health、唯一搜索空结果、登录态 options、12 个媒体引用、preferences、`auth/me`；业务响应为 `HTTP 200 + code=0`，媒体为 `200 + image/png`。
4. VR8 Seed/Validator 连续双跑；静态复核 Rollback，正式证据后不执行回滚。
5. 前后端 `git diff --check`；记录最终 APK 完整 SHA-256。
6. 标准尺寸、360dp、140% 字体均使用同一 APK，结束后恢复设备尺寸、density 和 font scale。

不跑全仓测试，不修改后端 Java，不重建整库，不执行全量 `schema.sql`。

## 6. 完成定义

以下任一项不满足，VR8 均不得通过：

- 4 张原型没有逐张真实同 APK 对照；
- 搜索空态使用 fake、错误态或通用 inbox 图标冒充真实空结果；
- 三步选择仍保留原型没有的品牌横栏、步骤圆点或独立步骤块；
- 正常 options 截图仍显示首字母而不是真实队徽/头像；
- preferences 请求、主队自动关注或无关注上限语义被改变；
- 数据脚本覆盖非目标行、不可幂等或无保护式回滚；
- 52 项定向测试、analyze、API、diff、响应式和最终 APK 未全部通过。

## 7. 交给执行模型的精简提示词

任务：严格执行 `D:\Football-APP-Front\reports\VR8_SEARCH_ONBOARDING_SELECTION_VISUAL_PARITY_EXECUTION_PLAN.md`，按 M0→M5 完成搜索空结果、选择主队、关注球队、关注球员 4 张原型的一比一复刻。

范围：仅修改 search、onboarding presentation、必要的兼容型 `AppSelectionCard` 参数、直接测试、VR8 证据，以及后端 12 行媒体 URL 的专用 Seed/Validator/Rollback/Manifest；禁止修改后端 Java、API、schema、Feed、发布、详情、用户中心、登录、消息和其他页面。

要求：沿用现有 search/entities 与 onboarding options/preferences 契约；先安全修复当前 6 队6人的失效媒体 URL，精确匹配旧值、幂等且可回滚。搜索空态必须来自真实 code=0 空结果；三步选择使用真实媒体，保留主队单选/自动关注、球队球员多选无上限、状态保持及一次性提交。不得硬编码页面数据或用原型整图作背景。

完成标准：VR8-01～12 全部有直接验证；相关测试不少于 52 项，analyze、VR7 共享回归、真实 API/PNG、数据双跑、两仓 diff 和最终 APK 通过；最终 APK 生成 8 张 after 正式图、4 张真实对照及完整记录，另保留 2 张 before。完成后仅提交 Plan 复验，不自行宣布 VR8 通过或进入 VR9。

执行：直接修改代码，只读取本计划涉及文件，不做全仓扫描；开发中只跑必要单文件，完成后统一执行第 5 节验证。

最终仅汇报：修改文件、四页完成结果、数据脚本影响、验证数量、APK 哈希、证据路径及阻塞/剩余问题。
