# VR14-R4-E1 语义断言与未开始卡证据闭环计划

状态：待执行模型执行
前置报告：`reports/VR14_R4_REVIEW_2026-10-02.md`
目标：闭环 R4 遗留的两小项——恢复球队芯片动作语义使 feed 全目录测试转绿，补未开始比赛卡日期显示的同 APK 实机截图。完成后 VR14 终验。

## 1. 范围与冻结项

允许修改：`followed_team_bar.dart`（仅 `_TeamChip` 的 Semantics 标签）。

冻结：其余全部生产代码与测试代码；R2 组合策略与分页；R3/R4 全部 SQL 与后端契约；既定排除项。不得修改 `f06_team_entry_widget_test.dart`——目标是让 2026-09-09 的原断言不加修改即通过。不提交、不推送 Git。

## 2. M0：恢复 `_TeamChip` 动作语义标签

1. 在 `apps/mobile/lib/features/feed/presentation/widgets/followed_team_bar.dart` 的 `_TeamChip`（约 66-69 行的 `Semantics`）恢复与 R3 之前一致的动作语义：有效球队为 `筛选 {teamName} 内容`；无效 id（teamId ≤ 0）为 `{teamName} 暂不可用`。视觉结构、已移除的 maxWidth 不变，只动 Semantics 标签。
2. 运行 `flutter test --no-pub test/features/feed/f06_team_entry_widget_test.dart`：两项用例必须全绿，且未改动测试文件。
3. 运行 `flutter test --no-pub test/features/feed/`：全目录必须全绿。
4. 运行 `flutter analyze --no-pub` 通过。

## 3. M1：同 APK 未开始比赛卡实机截图

1. 在普通 Windows Terminal / PowerShell 重新构建 APK（禁止在 Codex 进程内构建），安装至模拟器，核对本地/设备完整 SHA-256 一致并记录（语义改动改变了代码，必须重出包，不得复用 `68b13f3b…` 充当最终证据包）。
2. 设备设为标准 984×2400（约 375dp）、420dpi、font scale 1.0。
3. 首页滚动至任意未开始比赛卡，截取"日期标签（今天/明天/MM-dd）+ 时分"完整显示的实机截图一张，存入 `reports/VR14_R4_FINAL_EVIDENCE/`（建议命名 `home_scheduled_card_date.png`）。若当前账号首页连续 5 页确无未开始比赛卡，如实记录翻页 JSON 证据，并新注册一个一次性账号重试一次；仍无则报告未完成，不得用测试截图或旧 APK 截图冒充。
4. 恢复设备 1080×2400 / 420dpi / font scale 1.0。
5. 更新执行记录（测试清单与结果、新 APK 哈希、截图清单）并将偏差表首页"深青绿比赛卡"行的证据引用刷新到新 APK。

## 4. 给执行模型的指令

本计划只有两项：恢复 `_TeamChip` 动作语义（不改测试文件、不动视觉），以及重出 APK 后补一张未开始比赛卡实机截图。完成后提交执行记录、新 APK 完整哈希、feed 全目录测试通过输出和截图，等待 Plan 模型终验。VR14 保持开启，不得自行宣称通过。
