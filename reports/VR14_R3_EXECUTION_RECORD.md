# VR14-R3 执行记录

日期：2026-10-01  
状态：执行完成，待 Plan 模型复验；VR14 保持开启。

## 范围与结果

- 首页专用卡、紧凑混排及转会快讯按显式 `TRANSFER_BRIEF` 显示；R2 推荐组合策略、`pageSize=10`、`min-gap=3` 与翻页顺序保持冻结。
- 数据页加入紧凑赛事导航及可横向滚动的球队文字筛选。
- 关注球员头像在 R2 设备验证中已恢复显示，本轮未改动该部分。
- 后端仅对显式转会快讯类型增加白名单展示字段；R3 DEMO Seed、Validator、Rollback、Manifest 独立保存。M1/M2 及 R2 SQL 未改动。
- 已执行 R3 Seed×2 → Validator×2 → Rollback → 再 Seed → Validator；ID 冲突检查为 0，回滚后自有记录清零，最终保留 1 条演示内容和 3 条关联。关联内容明确标注为演示信息。
- 真实 Feed API 第一页为 10 条、首卡比赛、包含转会快讯且卡片类型顺序与 R2 冻结结果一致；第二页 10 条，与第一页无重复。

## 验证

- Flutter 定向测试：24 项通过，覆盖 P1 媒体回退、真实 API 顺序/卡片组合、瀑布分列稳定性、转会快讯显式标识和数据页紧凑控件。
- `flutter analyze --no-pub`：通过，无问题。
- 后端 `FeedServiceTests`：7 项通过。
- 前后端 `git diff --check`：通过；仅报告既有 LF/CRLF 转换警告。
- Android 证据来自同一当前 APK；Emulator 安装包哈希与本地 APK 一致。

## APK 与设备

- APK：`D:\Football-APP-Front\apps\mobile\build\app\outputs\flutter-apk\app-debug.apk`
- SHA-256：`91F7E84D1CA34CA0DF5B2BBDA5956B90438113A66DCD47917BEB9F1D682D96F7`
- 大小：214,775,199 bytes
- Pixel Emulator：Android 截图分辨率按场景设置为 984×2400（约 375dp）、945×2100（360dp）；140% 场景为 945×2100、font scale 1.4。
- 采证后已恢复设备：1080×2400、density 420、font scale 1.0。

| 证据场景 | 原始截图像素 | density | font scale | 逻辑画布 |
|---|---:|---:|---:|---:|
| 首页/数据标准宽度 | 984×2400 | 420dpi | 1.0 | 374.86×914.29dp（按375dp比较） |
| 首页/数据 360dp | 945×2100 | 420dpi | 1.0 | 360×800dp |
| 首页/数据 360dp 大字 | 945×2100 | 420dpi | 1.4 | 360×800dp |
| 数据原型等高对照 | 原型750×1667；实机984×2189 | 原型DPR2；实机420dpi | 1.0 | 原型375×833.5dp；实机374.86×833.90dp |

首页对照使用相同逻辑画布：原型区域缩放/裁切到 750×1829px，实机截图从 984×2400px 按相同比例缩放。上述为画布换算记录；卡片内部各边距、字号和间距的逐项量测及误差判定尚未在本记录中建立，不将画布一致写成组件几何通过。

## 证据

正式截图、API 页快照及双栏对照位于 [VR14_R3_FINAL_EVIDENCE](D:/Football-APP-Front/reports/VR14_R3_FINAL_EVIDENCE)：

- 首页：`01_home_375dp.png`、`01_home_standard.png`、`04_home_360dp.png`、`06_home_360dp_140pct.png`
- 数据页：`02_data_important_375dp.png`、`03_data_following_375dp.png`、`05_data_following_360dp.png`、`07_data_following_360dp_140pct.png`、`08_*_375dp_reference_height.png`、`09_data_following_team_375dp_reference_height.png`
- 对照：`comparison_home_375dp.png`、`comparison_data_following_375dp.png`
- 根页面回归冒烟：`10_my_avatar_smoke.png`、`11_messages_smoke.png`
- API：`recommend_page1.json`、`recommend_page2.json`

对照图右侧为当前 APK 原始 Android 截图；左侧为此前 VR14/R2 验收对照图中保留的原型像素区域，来源未伪称为独立原型文件。数据页两侧均为“关注”状态，实机侧另选中 Barcelona 球队筛选。

## 待验收事项

本记录不宣告视觉验收通过。首页卡片形态/分列与原型仍需 Plan 模型审阅，数据页控件是否达到视觉目标亦待独立复核。交由 Plan 模型按 VR14-R3 计划检查代码、实机截图、响应式证据和报告；VR14 不关闭，不进入下一阶段。
