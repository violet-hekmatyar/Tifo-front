# VR8-R1 搜索空态与首次偏好选择视觉收口计划

状态：**R1 实现完成但 Plan 复验未关闭，转入 VR8-R1-E1；不得进入 VR9**  
依据：`reports/VR8_REVIEW_2026-09-22.md`  
目标：保留 VR8 已通过的真实 API、媒体、交互与适配，只修正四张原型的比例、排版、系统栏、验收测试和 Rollback 保护。R1 复验结论见 `reports/VR8_R1_REVIEW_2026-09-23.md`；后续唯一入口为 `reports/VR8_R1_E1_TEST_VISUAL_EVIDENCE_CLOSURE_PLAN.md`。

## 1. 范围冻结

允许修改：

- `apps/mobile/lib/features/search/presentation/pages/global_search_page.dart`
- `apps/mobile/lib/features/onboarding/presentation/pages/onboarding_page.dart`
- 必要时扩展 `AppSelectionCard` 的可选视觉参数，默认行为必须不变
- VR8 直接相关的搜索/Onboarding Widget 与响应式测试
- `scripts/sql/VR8_M1_ONBOARDING_MEDIA_ROLLBACK.sql`
- `scripts/sql/VR8_M1_ONBOARDING_MEDIA_VALIDATOR.sql` 与 Manifest 的准确说明
- VR8-R1 执行记录和新证据目录

禁止修改：

- 后端 Java、schema、API 字段、请求语义和当前数据库数据
- VR8 Seed、12 个 ID、图片映射及已生效的媒体 URL
- 搜索 Repository/Controller 契约、preferences 契约、主队自动关注和球队/球员不限数量语义
- `/relations/select` 视觉、Feed、发布、详情、用户中心、登录、消息及 VR1～VR7 页面
- 手机验证码、一键手机号登录、微信登录、私信、IM、WebSocket、Push 和完整淘汰树

## 2. 顺序模块

### R1-A：搜索空态像素收口

1. 以 `搜索结果空.png` 为唯一视觉基准，按同宽归一化比较，不复用当前 comparison 的不等宽展示结论。
2. 非 selectionMode 搜索框改成原型的浅灰填充、无明显外描边、紧凑高度和圆角；移除右侧提交箭头。键盘搜索与既有防抖请求继续可用。
3. 保持左返回、居中“搜索”和白色页面；不得影响 selectionMode 的完成动作和关联搜索。
4. 将搜索空态插画缩小到与原型宽度比例一致，文字字号/间距同步收紧；不要使用 `Center` 在剩余区域机械居中，按原型把空态组锚定在页面中上部。
5. 给输入框、插画和空态组增加稳定 Key，并用 `tester.getRect` 断言：输入框高度/顶部、插画宽度以及空态组中心相对视口比例均落在从 750×1624 原型换算出的容差内。容差最多为目标尺寸或位置的 8%，不能只断言不越界。
6. 保持真实 empty 与 failure 分离，筛选、历史、分页、详情跳转和竞态行为不得回归。

完成门槛：同宽对照下，标题、输入框和空态组的位置、尺寸、颜色与原型接近；真实空结果仍为 `code=0 / records=0`。

### R1-B：三步选择页视觉收口

1. 以三张原型分别测量绿色头部底边、白色面板起点、结果标题、首卡、卡片高度/间距、按钮和系统安全区，不允许用一张页面的参数替代另外两张。
2. 调整说明文案和排版，使信息量、换行及绿色头部高度接近原型，但不得写入“最多 4/5 个”等与真实不限数量行为冲突的文案。
3. “搜索结果”改为原型的左对齐、常规字重与字号；白色面板圆角、左右留白保持原型比例。
4. 卡片保留真实媒体与红/灰爱心，收敛文字、头像、卡片高度和圆角；按原型增加列表项之间的分隔节奏。不得用缩小字体到不可读或压缩点击区域来规避布局。
5. 所有底部按钮移除方向/完成图标；主队只有“下一步”，球队与球员均为“上一步 + 下一步”。球员页点击“下一步”仍执行现有 submit，不改变请求体。
6. 使用页面级 `AnnotatedRegion<SystemUiOverlayStyle>` 或等价局部方案，使绿色页面为浅色状态栏图标、白色系统导航区和深色导航指示；离开页面后不得污染其他页面系统栏。
7. 保留三套搜索词、选择集合和 ScrollPosition。补充真实测试：在球队页输入查询，前进到球员页再返回，断言球队查询文本和滚动/选择状态仍在。
8. 新增原型几何断言，至少覆盖头部底边比例、结果标题左边界、首卡位置、卡片高度/间距、操作区高度和按钮无图标。标准、360dp、140% 字体分别验证。

完成门槛：三页结构、信息密度、对齐、爱心和操作区与各自原型一致；真实 options、选择规则和提交链路保持不变。

### R1-C：SQL 保护脚本修正

1. 不执行 Seed、Rollback 或任何数据写入。
2. Rollback 为每个球队 ID 分别匹配其专属 VR8 URL：crimson ID 不能接受 cobalt，cobalt ID 不能接受 crimson；球员继续要求当前 URL 精确等于 player target。
3. Validator 明确区分“12 个目标值正确”和“脚本静态范围为 12 个 ID”。不得把只查询目标 ID 的结果命名为“全表非目标泄漏为 0”。
4. 静态复核 Rollback 不包含 DELETE/TRUNCATE、宽泛 ID、名称模糊匹配或非目标表；Manifest 同步记录 R1 未改变当前数据。

完成门槛：回滚只会恢复“精确 ID + 该 ID 专属当前目标 URL”的行，脚本说明与实际验证能力一致。

### R1-D：回归、同 APK 证据与复验提交

1. 运行 VR8 原 63 项测试；新增几何、状态保持和按钮断言后总数不得低于 68 项。
2. 运行 `flutter analyze`、VR7 两个共享回归文件及前后端 `git diff --check`。
3. 真实 API 只读 smoke：唯一搜索空结果、options、12 个媒体 URL、`auth/me`；不新建账号、不重复提交 preferences、不改数据库。
4. 从最终源码重建并安装一个 APK，记录完整 SHA-256。新建 `reports/VR8_R1_SEARCH_ONBOARDING_VISUAL_PARITY_EVIDENCE`，至少包含四张标准正式图、360dp、140% 字体、状态保持图、完成后首页、`APK_HASH.txt`、执行记录和视觉对照。
5. 四张 comparison 必须把 750×1624 原型与实机图归一到相同内容宽度/高度后并排，不能再次用不等比例画布造成误判。逐图记录头部/输入框、空态锚点、卡片密度、结果标题、按钮和系统栏差异。
6. 正式图全部来自同一 APK；采证后恢复 1080×2400、density 420、font scale 1.0。

完成门槛：四张原型逐张人工可比，≥68 项测试、analyze、共享回归、只读 API、脚本静态复核、两仓 diff 和 APK 哈希全部通过。

## 3. 最终关闭条件

以下任一项不满足，VR8 仍不得关闭：

- 搜索框仍是高描边通用输入框、仍有右箭头，或空态插画继续明显过大/下沉；
- “搜索结果”仍居中，列表密度/分隔节奏仍明显不同；
- Onboarding 按钮仍有方向/完成图标，或末步文案不是“下一步”；
- 系统栏颜色与绿色选择页原型明显冲突；
- 新测试仍只验证存在/不越界，没有原型相对几何；
- Rollback 仍允许某球队 ID 匹配另一张 VR8 队徽 URL；
- comparison 未做等比例归一，或四张正式图并非同一最终 APK。

## 4. 交给执行模型的精简提示词

任务：严格执行 `D:\Football-APP-Front\reports\VR8_R1_SEARCH_ONBOARDING_VISUAL_REPAIR_PLAN.md`，只关闭 VR8 复验确认的搜索空态、三步选择页、几何测试和 Rollback 保护问题。

范围：仅改搜索页、Onboarding 页、必要的兼容型 `AppSelectionCard` 参数、直接测试、VR8 Rollback/Validator/Manifest 和 R1 证据；禁止修改后端 Java、API、schema、Seed、当前数据及其他页面。

要求：搜索框改为原型的紧凑浅灰无箭头样式，空态缩小并上移；选择页按各自原型收口头部、左对齐结果标题、卡片密度、无图标“上一步/下一步”和系统栏。保留真实 API、媒体、选择状态与不限数量语义。几何测试必须验证相对尺寸/位置，不得只查存在或不越界。Rollback 必须逐 ID 匹配专属目标 URL，本轮不执行任何数据写入。

完成标准：相关测试不少于 68 项，analyze、VR7 共享回归、只读 API、脚本静态复核和两仓 diff 通过；用同一新 APK 生成四张等比例原型对照、360dp/140% 证据并恢复设备参数。完成后只提交 Plan 模型复验，不进入 VR9。

执行：直接修改代码，只读取本计划涉及文件，不做全仓扫描；开发中只跑必要单文件，完成后统一执行 R1-D。

最终仅汇报：修改文件、四页视觉结果、测试/API/脚本结果、APK 哈希、证据路径及阻塞/剩余问题。
