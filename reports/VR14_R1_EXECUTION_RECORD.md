# VR14-R1 执行记录

日期：2026-09-30  
状态：R1 执行结果已提交 Plan 模型复验；执行模型不自行关闭 VR14，也不进入后续阶段。

## 1. 执行范围

本轮仅处理 VR14-R1 规定的首页首屏、数据根页正常态证据和 M1/M2 数据脚本可逆性。`我的`、`消息`只做同 APK 回归采证，未扩大业务范围。

## 2. M0 基线恢复

- `FeedController.pageSize` 已恢复为 `10`，客户端不再请求 `30` 条。
- `feed.auxiliary-cards.min-gap` 已恢复为 `3`，未保留 `1` 的全局间距 workaround。
- 未修改 Feed API 契约、推荐排序、候选上限或全局混排算法。
- 当前真实 API 请求：`/api/app/feed?tab=recommend&pageNum=1&pageSize=10`。
- 真实返回首批顺序：`CONTENT, CONTENT, CONTENT, DISCUSSION, CONTENT, CONTENT, CONTENT, HOT_COMMENT, CONTENT, MATCH`。
- Flutter 通过 `vr14_home_recommend_page1.json` 固化了该真实 API 记录，并断言 pageSize、位置及主要卡型，而不是手工伪造返回列表。

## 3. M1/M2 SQL 可逆性闭环

涉及脚本：

- `D:\Football-APP\scripts\sql\VR14_M1_ROOT_MEDIA_NOTIFICATION_SEED.sql`
- `D:\Football-APP\scripts\sql\VR14_M1_ROOT_MEDIA_NOTIFICATION_VALIDATOR.sql`
- `D:\Football-APP\scripts\sql\VR14_M1_ROOT_MEDIA_NOTIFICATION_ROLLBACK.sql`
- `D:\Football-APP\scripts\sql\VR14_M2_HOME_FEED_SEED.sql`
- `D:\Football-APP\scripts\sql\VR14_M2_HOME_FEED_VALIDATOR.sql`
- `D:\Football-APP\scripts\sql\VR14_M2_HOME_FEED_ROLLBACK.sql`
- `D:\Football-APP\scripts\sql\VR14_R1_ROLLBACK_VALIDATOR.sql`

已完成并记录：

1. M1 Seed → Validator；
2. M1 Seed 第二次 → Validator，结果保持一致；
3. M2 Seed → Validator；
4. M2 Seed 第二次 → Validator，目标有效记录保持 `144`；
5. M2 Rollback → M1 Rollback → `VR14_R1_ROLLBACK_VALIDATOR.sql`；
6. Rollback 后重新执行 M1/M2 Seed 两次并再次运行 Validator。

结果：各 Validator 的 `invalid_count=0`；M1 通知为 `8` 条，其中未读 `5`、已读 `3`；M2 有效目标为 `144` 条（`116 + 10 + 12 + 6`），4 条已删除记录受保护。Rollback 已覆盖本轮修改的 `content_media`、`content_block`、内容封面、球员头像、用户头像和 hot score，并使用“字段仍等于 VR14 写入值”条件，不覆盖后续合法修改。

## 4. Android APK

- APK：`D:\Football-APP-Front\apps\mobile\build\app\outputs\flutter-apk\app-debug.apk`
- 构建时间：2026-09-30 14:13:04
- 大小：`213,482,995` bytes
- SHA-256：`7D36742F6713F7EDC65AFAFAE160B9514AF58718028EC4237D837AFC6DBC3820`
- 已安装设备：`emulator-5554`
- 从设备回拉 `base.apk` 后哈希与本地 APK 完全一致。

设备已恢复：`1080×2400 / density 420 / font scale 1.0`。

## 5. 同 APK 证据

证据目录：[VR14_R1_HOME_DATA_SQL_EVIDENCE](VR14_R1_HOME_DATA_SQL_EVIDENCE)

当前 APK 原始截图：

- `final_r1_home.png`：首页推荐标准态，`1080×2400`；
- `final_r1_data_important.png`：数据页“重要”选中且已加载，`1080×2400`；
- `final_r1_messages.png`：消息首页；
- `final_r1_interactions.png`：互动消息列表，8 条通知可见；
- `final_r1_profile.png`：我的首页，真实用户、球队和球员图片可见；
- `360_r1_home.png`、`360_r1_data.png`：`945×2400`，均为加载完成态；
- `140_r1_home.png`、`140_r1_data.png`：`945×2400`，均为加载完成态。

直接双栏对照：

- `comparison_r1_home.png`：`首页.png` + 当前 APK 首页原始截图，`1500×2614`；
- `comparison_r1_data.png`：`数据-比赛-重要.png` + 当前 APK 数据页“重要”原始截图，`1500×1667`。

两张对照均由原型原图和当前 APK 原始截图直接组成，无旧 comparison、人工绿色边框或加载态替代。数据页左右两栏均为“重要”状态。

最终采证序列的 logcat 检查结果：`DECODE_FAILURE_LINES=0`。

## 6. 定向验证

- Flutter VR14 根页面、Feed、数据、我的、消息定向测试：`104` 项通过；
- 后端 Feed、首页混排、榜单、评分、讨论、热门评论、通知和认证定向测试：`25` 项通过；
- `flutter analyze --no-pub`：`No issues found!`；
- 前端、后端 `git diff --check`：通过，仅保留既有 LF/CRLF 转换警告。

## 7. 待 Plan 模型复验的事实

M0、M1、M3、M4 的代码、数据、响应式和回归证据已准备完成。但当前真实 API 在恢复 `pageSize=10`、`min-gap=3` 后，首批实际顺序仍是三张内容卡起始，比赛位于第 `9` 位，排名/评分辅助卡不在首批 10 条内；这与首页原型要求的“比赛、转会、评分、积分/排名、讨论”首屏节奏仍存在可见差异。

该问题不能通过伪造 fixture、扩大 pageSize、收紧全局 min-gap 或修改推荐算法规避。本记录如实提交该残余差异，等待 Plan 模型判断是否需要新的、明确授权的首页范围修复。
