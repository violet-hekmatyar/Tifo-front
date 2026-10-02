# VR8-R1 视觉证据索引

原型基准均为 `C:\Users\hekmatyar\Desktop\足球APP\` 下的四张 750×1624 PNG：

- `搜索结果空.png`
- `选择主队.png`
- `选择球队.png`
- `选择球员.png`

本轮最终 APK 证据：

| 状态 | 实机证据 | 复核重点 |
| --- | --- | --- |
| 主队 | `01_main_team.png` | 绿色头部、搜索框、左对齐结果标题、首卡、单一“下一步”、白色系统导航区 |
| 关注球队 | `02_follow_teams.png` | 三行文案、双按钮、真实队徽、无按钮图标、卡片节奏 |
| 关注球员 | `03_follow_players.png` | 球员头像、搜索球员、双按钮、末步仍为“下一步” |
| 360dp | `04_360dp_players.png` | 360dp 下的头部、卡片和双按钮可达性 |
| 140% 字体 | `05_140_percent_players.png` | 140% 字体下无按钮换行、无溢出或遮挡 |

四张原型对应的几何断言位于：

- `apps/mobile/test/features/search/vr8_search_visual_test.dart`
- `apps/mobile/test/features/onboarding/vr8_search_onboarding_visual_test.dart`

断言使用 `tester.getRect` 检查输入框高度/边界、空态插画尺寸和锚点、绿色头部与白色面板接缝、结果标题左边界、首卡位置、卡片高度、操作区以及按钮无图标；不只检查 Widget 存在性。

本目录中的正式图片均来自同一 SHA-256 APK，图片哈希与设备参数见 `APK_HASH.txt`、`DEVICE_PARAMETERS.txt`。搜索空态本轮未重复进行会改变验收账号状态的真实 preferences 提交，因此未伪造一张“当前 APK 实机搜索图”。

## VR8-R1-E1 处理结果

E1 按原型目标 ±8% 的严格断言已先于登录态采证失败，故本轮没有生成 `comparison_*.png`，也没有把旧 APK 搜索图或非等比例画布伪装成最终对照。失败测量记录见 `D:\Football-APP-Front\reports\VR8_R1_E1_EXECUTION_RECORD.md`。
