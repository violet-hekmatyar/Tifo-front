# VR3-M6 收口执行记录

状态：历史 M6 记录；最新 R2 证据与哈希以 `VR3_R2_EXECUTION_RECORD.md` 为准

固定比赛：`15000000000000060`

## 已完成模块

- M0：比赛关联内容、评分目标 ID、阵容坐标和 `PLAYER_RATING` 评论契约。
- M1：沉浸式比赛头部、五项同屏 Tab 和真实球队入口。
- M2：最新资讯、比赛关联封面、简要统计和事件区块。
- M3：真实 `fieldX/fieldY` 上下半场球场、球员入口、教练/替补和图例。
- M4：统计分组、当前排名和淘汰树入口；不伪造淘汰树数据。
- M5：评分列表、真实头像、评分详情、单场关键统计、评分输入、评分评论和回复入口。

## 验证结果

- `flutter analyze`：通过。
- Flutter 比赛详情、评分、评论定向测试：38 项通过。
- 后端 `mvn -DskipTests compile`：通过。
- 后端 Comment/Match Controller/Rating 相关定向测试：通过。
- 两个仓库 `git diff --check`：通过。
- 真实 API：比赛详情、overview、lineups、stats、player-stats、contents、ratings 均 `HTTP 200 + code=0`。
- 真实数据核对：两队首发各 11 人，坐标存在，评分 28 条，评分目标 ID 和球员头像存在，比赛关联内容 6 条。
- APK：`D:\Football-APP-Front\apps\mobile\build\app\outputs\flutter-apk\app-debug.apk`
- APK SHA-256（M6 历史构建）：`F4CE70E3B3C39CC36E7F5F640742ABF21A917187E03DEAC7E315CDAC1AF895D8`

## Android 视觉证据

- ADB：`C:\Users\hekmatyar\AppData\Local\Android\Sdk\platform-tools\adb.exe`。
- 设备：`emulator-5554`，Pixel 8 模拟器，`1080x2400`、density `420`。
- 证据目录：[VR3_MATCH_DETAIL_VISUAL_PARITY_EVIDENCE](VR3_MATCH_DETAIL_VISUAL_PARITY_EVIDENCE)。
- 本轮仅在比赛详情模块补齐评分详情中的“单场关键统计”卡片；随后使用同一最终 APK、真实 API 重采 12 张正式截图，并重新生成 7 张原型对照。
- 12 张正式截图包含总览、统计/事件、球场阵容、教练/替补/图例、统计、排名入口、淘汰树占位返回、评分列表、评分详情、评分输入、360dp 和 140% 字体。
- 7 张原型对照及逐图差异：[VISUAL_COMPARISON.md](VR3_MATCH_DETAIL_VISUAL_PARITY_EVIDENCE/VISUAL_COMPARISON.md)。
- 360dp 证据按 density 420 计算为 `945px` 宽，采集后已恢复原始 size/density/font scale。
- 不能以本记录自行宣布 VR3 视觉通过；本记录仅提交 Plan 模型复验。

R2 补修后的最新构建、截图和复验状态见：[VR3-R2 执行记录](VR3_R2_EXECUTION_RECORD.md)。

后端脱离启动脚本：`D:\Football-APP\scripts\windows\start-backend-detached.ps1`。当前后端通过交互式计划任务运行，以规避 Codex 进程的 Windows Java NIO loopback 限制。
