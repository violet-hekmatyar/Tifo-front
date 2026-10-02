# VR14 四根页面最终集成执行记录

日期：2026-09-30  
状态：执行完成，已提交 Plan 模型复验；执行模型不自行关闭 VR14。

## 1. 范围与结果

本轮只处理首页、数据、我的、消息四个根模块，以及直接相关的 DEMO 媒体、通知数据和定向测试。未修改后端 API 契约、未新增私信/IM/Push、未处理其他详情页。

- M0：补充了真实失败保护，确认首页首批请求过小会遗漏积分榜/评分卡；未对未稳定复现的路由问题做盲改。
- M1：恢复 DEMO 队徽、球员头像、用户头像、内容封面和 VR11 通知媒体；不同球队使用不同可解码 PNG。
- M2：首页首批请求调整为 30 条，复用现有生产渲染器承载比赛、讨论、积分榜、球员评分和内容卡；未修改 Feed 算法、候选排序或 API 契约。
- M3：数据页使用真实且彼此区分的球队队徽，保留赛事、赛程、积分榜、球队榜、球员榜和淘汰树占位入口。
- M4：本人页恢复真实用户头像、主队/关注球队队徽和关注球员头像；消息首页与互动列表恢复 `10002` 的 8 条真实互动通知。
- M5：使用同一 APK、同一数据库基线和同一 DEMO 账号完成四根页面联调采证。

## 2. 代码与数据变更

前端主要变更：

- `apps/mobile/lib/features/feed/presentation/controllers/feed_controller.dart`
- `apps/mobile/test/features/vr14_root_pages_regression_test.dart`
- `apps/mobile/test/features/user_center/f07_router_test.dart`

后端主要变更：

- `D:\Football-APP\src\main\resources\application-dev.yml`：仅收紧首页辅助卡片间距配置。
- `D:\Football-APP\scripts\sql\VR14_M1_ROOT_MEDIA_NOTIFICATION_SEED.sql`
- `D:\Football-APP\scripts\sql\VR14_M1_ROOT_MEDIA_NOTIFICATION_VALIDATOR.sql`
- `D:\Football-APP\scripts\sql\VR14_M1_ROOT_MEDIA_NOTIFICATION_ROLLBACK.sql`
- `D:\Football-APP\scripts\sql\VR14_M1_ROOT_MEDIA_NOTIFICATION_MANIFEST.md`
- `D:\Football-APP\scripts\sql\VR14_M2_HOME_FEED_SEED.sql`
- `D:\Football-APP\scripts\sql\VR14_M2_HOME_FEED_VALIDATOR.sql`
- `D:\Football-APP\scripts\sql\VR14_M2_HOME_FEED_ROLLBACK.sql`
- `D:\Football-APP\scripts\sql\VR14_M2_HOME_FEED_MANIFEST.md`

Seed 连续执行两次，Validator 连续执行两次，均无非法媒体路径、重复球队身份、通知数量异常或非 DEMO 泄漏。首页权重脚本只调整固定 DEMO 内容，回滚脚本保留原始分值。

## 3. 验证结果

- Flutter 定向测试：103 项通过。
- 后端定向测试：25 项通过。
- `flutter analyze --no-pub`：通过，`No issues found!`。
- 前端、后端 `git diff --check`：通过；仅有既有换行符转换警告。
- VR14 M1 媒体/通知 Validator：两次通过，所有 `invalid_count=0`。
- VR11 通知 Validator：通过；账号 `10002` 为 8 条通知、5 条未读、3 条已读。
- 代表性 API：Feed、通知、用户中心和图片访问均完成真实联调；目标图片为 `HTTP 200 + image/*`。
- 四根页面连续浏览期间未记录目标媒体 `Failed to decode image`；最终采证序列 `DECODE_FAILURE_LINES=0`。

## 4. 最终 APK

- 路径：`D:\Football-APP-Front\apps\mobile\build\app\outputs\flutter-apk\app-debug.apk`
- 构建时间：`2026-09-30 13:03:53`
- 大小：`213,482,937` bytes
- SHA-256：`F321B29E25E9F3674EED49B0E044CE430FEFEC4397B526CBEEC59A8BFA0D3368`
- 已安装到 `emulator-5554` 并用于全部最终截图。

## 5. Android 证据

证据目录：`D:\Football-APP-Front\reports\VR14_FINAL_INTEGRATION_ROOT_PAGES_EVIDENCE`

同一最终 APK 的标准截图：

- `final_apk_home_tuned.png`
- `final_apk_data.png`
- `final_apk_profile.png`
- `final_apk_messages.png`
- `final_apk_interactions.png`

其中首页包含内容、讨论、热门评论、积分榜、球员评分和比赛等真实混排；数据页显示不同球队的不同队徽；我的页显示真实用户、球队和球员图片；互动消息页显示 8 条真实通知。

直接双栏对照：

- `comparison_01_home.png`
- `comparison_02_data.png`
- `comparison_03_profile.png`
- `comparison_04_messages.png`
- `comparison_05_interactions.png`

对照图由原型原图与当前 APK 原始截图等比例合成，未复制原型代替实机，也未添加人工绿色边框。

响应式证据：

- 360dp：`360_home.png`、`360_data.png`、`360_messages.png`、`360_interactions.png`、`360_profile.png`
- 140% 字体：首页使用最终重试图 `140_home_retry.png`；其余为 `140_data.png`、`140_messages_retry.png`、`140_profile.png`。

140% 消息页已在等待真实数据加载完成后重新采集，画面显示“互动消息”和未读数 5。采证结束后设备已恢复 `1080×2400 / density 420 / font scale 1.0`。

## 6. 当前交付状态

VR14 的代码、数据、定向测试和同 APK 证据已准备完毕，现交由 Plan 模型独立复验。执行模型不据此自行宣布 VR14 通过，也不进入后续阶段；若复验发现视觉或集成问题，仅按复验报告制定下一次限定修复计划。
