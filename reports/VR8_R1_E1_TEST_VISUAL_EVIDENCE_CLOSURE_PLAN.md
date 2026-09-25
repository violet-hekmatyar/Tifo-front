# VR8-R1-E1 几何测试与同 APK 视觉证据补正计划

状态：**已按计划停止，严格测试失败；复核后转入 VR8-R2，不进入 VR9**  
依据：`reports/VR8_R1_REVIEW_2026-09-23.md`  
目标：不改生产代码和 APK，只补齐严格几何断言、搜索空态实机图、登录态只读验证及四张等比例原型对照。E1 已正确停止，但复核发现绝对 Y 坐标混用了系统安全区；详见 `reports/VR8_R1_E1_REVIEW_2026-09-23.md`。后续唯一入口为 `reports/VR8_R2_GEOMETRY_AND_EVIDENCE_FINAL_PLAN.md`。

## 1. 范围冻结

允许修改：

- `apps/mobile/test/features/search/vr8_search_visual_test.dart`
- `apps/mobile/test/features/onboarding/vr8_search_onboarding_visual_test.dart`
- `reports/VR8_R1_SEARCH_ONBOARDING_VISUAL_PARITY_EVIDENCE/**`
- `reports/VR8_R1_EXECUTION_RECORD.md`

禁止修改：

- 所有 `apps/mobile/lib/**` 生产代码、主题、路由和依赖
- 后端、数据库、SQL、Seed、Validator、Rollback、API 和当前数据
- APK 重建、重新提交 preferences、新建用户或修改既有用户偏好
- 用户中心、登录视觉、消息及 VR1～VR7 页面

必须沿用已安装且哈希为 `E6F1A87A6FBC7559F38CED0077637F87A19403EF591131A5C4D77EB686FA98FD` 的 APK。

## 2. 顺序执行模块

### E1-A：把几何测试收紧到真实原型容差

1. 先从四张 750×1624 原型记录目标像素，并换算为 360dp/当前测试视口的比例表，写入测试注释或执行记录；不得根据当前实现反推目标值。
2. 搜索测试对输入框顶部、输入框高度、插画宽度和空态组中心 Y 同时设置上下界或 `closeTo`；每项容差不得超过对应原型目标的 8%。
3. Onboarding 测试至少对绿色头部底边/视口高度、结果标题左边界、首卡顶部、卡片高度、相邻卡片间距、底部操作区高度设置双向范围；三张原型若目标不同，分别断言。
4. 状态保持测试必须实际执行“球队页输入查询并滚动/选择 → 前进球员页 → 返回球队页”，断言球队查询文本、已选状态和 ScrollPosition 均保持；不得继续用返回主队页代替。
5. 保留 360dp、140% 字体、无图标按钮和空结果状态测试。
6. 若冻结生产代码无法通过从原型换算出的严格阈值，立即停止 E1，报告目标值、实际值和超差比例；不得放宽阈值或修改生产布局。

完成门槛：断言具有明确目标、上下界和 ≤8% 容差，且冻结生产代码全部通过。

### E1-B：补最终 APK 搜索空态与登录态只读验证

1. 不提交当前未完成账号的 preferences。退出或清除本地会话后，使用一个已有且 onboarding 已完成的账号登录同一 APK；不得把账号密码或 Token 写入报告。
2. 按正常客户端路由进入全局搜索，输入唯一无结果关键词并等待真实 `HTTP 200 + code=0 + records=[]`，采集 `00_search_empty.png`。禁止 fake、离线 fixture、图片后处理或旧 APK 截图。
3. 使用同一登录态只读验证 `GET /api/app/onboarding/options` 和 `GET /api/auth/me` 均为 `HTTP 200 + code=0`；只记录用户 ID、完成状态和 options 数量，不记录凭据。
4. 不创建账号、不发布内容、不关注/取消关注、不调用 preferences；登录和只读查询之外不得改变服务端业务数据。

完成门槛：搜索空态来自目标哈希 APK 与真实 API，登录态 options/auth-me 回读成立且没有偏好写入。

### E1-C：生成四张严格等比例对照

1. 沿用现有 `01_main_team.png`、`02_follow_teams.png`、`03_follow_players.png`，加上 E1-B 的 `00_search_empty.png`；四张实机图必须来自同一目标哈希 APK。
2. 生成：
   - `comparison_01_search_empty.png`
   - `comparison_02_main_team.png`
   - `comparison_03_follow_teams.png`
   - `comparison_04_follow_players.png`
3. 每张对照先按应用内容区域归一到相同宽高，再并排展示；不得只把两张不同尺寸图片贴到同一大画布，也不得拉伸改变宽高比。
4. `VISUAL_COMPARISON.md` 逐张记录输入框/头部、空态锚点、标题、首卡、卡片高度/间距、按钮、系统栏的原型目标与实机值及误差百分比。
5. 任一关键项目误差超过 8%，或肉眼仍存在结构/层级明显差异，停止并提交差异，不得宣称通过。

完成门槛：四张 comparison 可直接进行同尺度人工复验，文字记录与图片实际一致。

### E1-D：最小验证与提交复验

1. 运行 VR8 冻结 68 项测试；不得删除旧测试抵消新增断言。
2. 运行 `flutter analyze` 和两仓 `git diff --check`。
3. 重新计算本地 APK SHA-256，必须仍为目标哈希；不重建 APK。
4. 核对证据目录包含四张标准图、两张响应式图、四张 comparison、APK/设备记录、执行记录和视觉记录。
5. 设备恢复为 1080×2400、density 420、font scale 1.0。

完成门槛：生产代码、SQL、数据库和 APK 零修改；严格测试、真实搜索图、登录态只读 smoke、四张对照及文件清单全部闭合。

## 3. 交给执行模型的精简提示词

任务：执行 `D:\Football-APP-Front\reports\VR8_R1_E1_TEST_VISUAL_EVIDENCE_CLOSURE_PLAN.md`，只补 VR8-R1 的严格几何测试和同 APK 证据。

范围：仅改两个 VR8 测试文件、R1 证据和执行记录；冻结所有生产代码、后端、SQL、数据库和 APK。不得新建账号、提交 preferences 或进入 VR9。

要求：按 750×1624 原型换算目标，搜索与三步选择页的关键几何使用双向范围且容差 ≤8%；真实执行“球队→球员→球队”验证查询/选择/滚动保持。使用已有 onboarding 已完成账号登录目标哈希 APK，正常进入搜索并以真实空结果采集截图，同时只读验证 options/auth-me。生成四张同尺度 comparison；若冻结代码超差，停止并报告，不得放宽断言或改样式。

完成标准：68 项冻结测试、analyze、两仓 diff 通过；APK 哈希不变；四张标准图、四张对照、360dp/140% 和登录态只读记录齐全，设备参数恢复。完成后只提交 Plan 最终复验。
