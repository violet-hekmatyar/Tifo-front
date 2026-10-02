# VR14-R2 执行记录

日期：2026-09-30  
状态：已提交 Plan 模型复验；执行模型不自行关闭 VR14，也不进入后续阶段。

## 范围与结果

- 首页 recommend 组合只在后端首页组合服务中调整；不改 API、候选上限、分页语义、客户端 `pageSize=10`、`min-gap=3` 或其他 Feed Tab。
- 首页卡片来自真实候选，不按固定实体 ID、标题或 DEMO 分支造卡。未新增演示数据，也未修改或执行 VR14 M1/M2 SQL。
- 数据页修正关注态顶部紧凑布局；本人页球员图像继续使用真实头像 URL，并保留失败降级。
- 对新闻流中的 SVG 封面增加 SVG 渲染路径，未修改媒体 URL、后端或数据库。

## 真实 API 与分页

实测 `GET /api/app/feed?tab=recommend&pageNum=1&pageSize=10`：

- `code=0`，`pageNum=1`，`pageSize=10`，`total=192`，`pages=20`。
- 前 10 条：`MATCH, CONTENT, RANKING, DISCUSSION, PLAYER_RATING, CONTENT, HOT_COMMENT, CONTENT, CONTENT, CONTENT`。
- 首卡为比赛，含排名、评分、讨论、热评和 5 条内容；10 个 `cardKey` 唯一。
- 第 2 页返回 10 条，与第 1 页无重复。
- 本次真实响应快照：[recommend_page1.json](VR14_R2_FINAL_EVIDENCE/recommend_page1.json)。Flutter 定向测试直接通过生产 `FeedPageDto` 解析该响应。

新闻流中的 6 个 SVG 封面资源均以 `HTTP 200 + image/svg+xml` 返回。清空 Android logcat 后浏览首页推荐和资讯，匹配图片解码失败模式的日志数为 `0`。

## APK 与设备证据

- APK：[app-debug.apk](../apps/mobile/build/app/outputs/flutter-apk/app-debug.apk)
- SHA-256：`D9BD29DA1C127B4BC5D3B7501FCF9D8BE1D1BCBA720C920DE41A79580E4E46A5`
- 大小：`214,773,000` bytes；构建时间：`2026-09-30 17:52:23`。
- Android 包内 `base.apk` SHA-256 与本地产物相同。
- 默认设备参数恢复为 `1080×2400 / density 420 / font scale 1.0`。360dp 与 140% 截图均为 `945×2100`，采集完成后已恢复默认值。

证据目录：[VR14_R2_FINAL_EVIDENCE](VR14_R2_FINAL_EVIDENCE)

- 原始实机图：`01_home_recommend.png`、`02_data_following.png`、`03_my_stand.png`、`04_data_following_360dp.png`、`05_data_following_140pct.png`、`06_home_news.png`、`07_home_following.png`、`08_home_team_filter.png`、`09_data_important.png`、`10_messages.png`、`11_interactions.png`。
- 直接双栏图：`comparison_home.png`、`comparison_data_following.png`、`comparison_my_stand.png`。左侧为原型原图，右侧为当前 APK 原始实机截图；数据页两侧均为“关注”状态。
- `12_launchcheck.png`、`13_datacheck.png` 是采集过程诊断图，不作为正式证据。

## 定向验证

- Maven：`HomeFeedCompositionServiceTests,FeedServiceTests`，10 项通过。
- Flutter：VR14 根页面回归 4 项、数据页定向 10 项、SVG URL 判定 1 项，合计 15 项通过。
- `flutter analyze --no-pub`：`No issues found!`。
- 前后端 `git diff --check`：通过；仅有既有 LF/CRLF 转换警告。

## 数据脚本与复验边界

本轮没有 SQL、Seed、Rollback、数据库或演示数据变更；R1 的 M1/M2 Validator 结果继续作为既有数据基线。本机未安装 `mysql`/`mysqlsh`，因此本轮没有重复运行只读 Validator。以上结果提交 Plan 模型复验，不代表 VR14 阶段关闭。
