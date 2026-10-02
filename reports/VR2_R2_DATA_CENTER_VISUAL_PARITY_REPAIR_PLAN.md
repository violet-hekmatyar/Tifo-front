# VR2-R2 数据中心控制栏单项补修计划

状态：**已执行并通过 Plan 复验（2026-09-18）**

依据：

- `reports/VR2_R1_DATA_CENTER_VISUAL_PARITY_ACCEPTANCE_2026-09-18.md`
- `reports/VR2_R1_DATA_CENTER_VISUAL_PARITY_REPAIR_PLAN.md`
- `C:\Users\hekmatyar\Desktop\足球APP\数据-西甲-赛程.png`
- `C:\Users\hekmatyar\Desktop\足球APP\数据-西甲-积分榜.png`
- `C:\Users\hekmatyar\Desktop\足球APP\数据-西甲-球队榜.png`
- `C:\Users\hekmatyar\Desktop\足球APP\数据-西甲-球员榜.png`

## 1. 唯一目标

只关闭 `VR2-B02-R`：把数据中心联赛页的主控制行严格收敛为“赛季入口＋赛程/积分榜/球员榜/球队榜”，将阶段选择移入赛季/筛选底部层。不得进入旗舰比赛详情或顺带调整其他页面。

## 2. 允许范围

- `apps/mobile/lib/features/football/presentation/widgets/football_rankings_widgets.dart`；
- 必要时小范围调整 `football_data_page.dart`；
- 直接相关的 Widget/Controller 测试；
- VR2 证据截图、执行记录和视觉对照记录。

不得修改后端、数据库、seed、API 契约、P1 数据、赛事顶部导航、榜单表格、头像、首页、详情页或淘汰树业务。

## 3. 必须完成

### R2-1 主控制行

- 移除主控制行中独立常驻的 `ranking_filter_stage` 按钮；
- 默认进入联赛页时，控制行从左至右完整起始于赛季入口，随后依次为赛程、积分榜、球员榜、球队榜；
- Pixel 8 常规宽度下不得以被截断的按钮作为左边界，且当前赛季必须直接可见；
- 360dp 和 140% 字体可保留横向滚动，但初始偏移必须为 0，不能自动停留在“阶段”或半个按钮位置。

### R2-2 阶段能力保留

- 点击赛季入口打开一个紧凑底部层，在同一处完成赛季选择和可选阶段选择；
- 阶段为空时显示“全部阶段”，有阶段时可选择并继续调用现有 Controller；
- 切换赛季后刷新可用阶段，已失效阶段不得残留；
- 切换赛程/三个榜单时继续保持同一联赛、赛季和阶段，不改变现有 API 契约。

### R2-3 定向测试

新增或更新测试，至少覆盖：

- 主控制行不存在独立阶段按钮，赛季入口和四个栏目按钮存在且顺序正确；
- 点击赛季入口后，同一底部层可选择赛季和阶段；
- 赛季变化会清理不再可用的阶段，栏目切换保持有效上下文；
- 412dp、360dp、140% 字体下无 overflow，初始左边界显示完整赛季入口；
- B01、B03～B06 的现有关键测试继续通过。

完成后统一运行 VR2 既有 7 个定向测试文件、`flutter analyze` 和 `git diff --check`。

## 4. 证据与验收

执行状态：**已执行并通过 Plan 复验；证据见 `VR2_R2_DATA_CENTER_VISUAL_PARITY_ACCEPTANCE_2026-09-18.md`**。

- 构建新的当前源码 APK，记录完整 SHA-256；
- 使用同一 APK 和真实 API 重新采集 VR2 的 10 张 Android 截图，不混用 R1 旧图；
- 重新生成 `comparison_01.png`～`comparison_05.png`；
- 联赛相关截图必须清楚显示“赛季＋四栏目”控制层级，不得通过裁切隐藏阶段按钮；
- 执行模型只能报告“已提交 Plan 模型复验”，不得自行宣布 VR2 通过。

## 5. 交给执行模型的精简任务

任务：
执行 `D:\Football-APP-Front\reports\VR2_R2_DATA_CENTER_VISUAL_PARITY_REPAIR_PLAN.md`，只关闭 `VR2-B02-R`。

范围：
- 数据中心联赛页的赛季/阶段与四栏目控制行、直接相关测试和 VR2 证据。
- 后端、数据库、seed、API、其他页面和淘汰树业务全部不动。

要求：
- 主控制行只显示“赛季＋赛程/积分榜/球员榜/球队榜”；阶段选择并入赛季底部层。
- 保持联赛、赛季、阶段跨栏目状态同步；360dp/140% 无溢出且初始偏移为 0。
- 保护现有工作区，不做无关重构。

完成标准：
- 相关新测试及 VR2 既有 7 个定向测试、`flutter analyze`、`git diff --check` 通过。
- 同一新 APK 生成 10 张实机图和 5 张真实对照图，并记录完整 SHA-256。

执行：
直接修改代码。只读取本任务必要文件，不做全仓扫描。完成后统一验证。

最终仅汇报：
- 修改文件
- 控制栏与阶段选择完成结果
- 测试和 APK 结果
- 新证据路径
- 阻塞/剩余问题
