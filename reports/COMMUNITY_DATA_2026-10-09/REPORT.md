# 演示内容替换：真实感社区数据（2026-10-09）

## 目标

把 App 里的「测试痕迹」清掉，换成模拟真实用户产生的社区数据，让客户打开 App 看到的是完整产品，而不是冷启动或演示数据集。通过 football-data.org 同步的真实足球数据（联赛/球队/球员/比赛/积分榜）不做改动。

## 改动范围

后端仓库 `D:\Football-APP`：

| 文件 | 说明 |
| --- | --- |
| `scripts/data/community/content_pack/*.json` | 新社区数据包：40 账号、96 篇帖子、186 条评论、1 张转会简报卡 |
| `scripts/data/community/build_media.py` | 下载头像池（DiceBear）与封面（Unsplash 免费图） |
| `scripts/data/community/build_community_seed.py` | 生成 `scripts/sql/community_seed.sql` |
| `scripts/sql/community_media.sql` | 108 个媒体文件记录（48 头像池 + 60 封面） |
| `scripts/sql/retire-demo-football-remnants.sql` | 退役残留的演示阵容/荣誉/演示字段 |
| `scripts/windows/restart-backend-community.ps1` | 重新打包并重启本地后端 |
| `src/main/java/.../FeedService.java` | 信息流不再返回「作者已删除/禁用」的内容 |
| `src/main/java/.../DiscussionCardService.java` | 同上，覆盖话题讨论卡 |

删除：`src/main/resources/static/demo/**`（67 个写着「南看台 Demo」的占位 SVG）。

前端仓库 `D:\Football-APP-Front`：`apps/mobile` 兜底头像资源 `user-demo.png` → `user-placeholder.png`（含 pubspec 与 4 处引用）。

## 数据结果

- 账号：原 `demo_user_01..36` 复活并重写为可信球迷账号（昵称、简介、头像、主队）；新增 4 个；测试账号（`test_user_<ts>`、`football_user_<ts>`、`storage_user_<ts>`、`aaa*`、`probe*`、`kz*`、`vr*` 等）硬删除。存活账号 253（含 2 个保留的本地测试账号）。
- 内容：96 篇原创中文帖子（75 POST / 15 ARTICLE / 6 NEWS）+ 1 张转会简报卡；关联真实球队/球员/比赛；封面为自持图片；发布时间铺满近 75 天。
- 互动：评论 186、点赞 2256、收藏 529、关注 688、通知 24、浏览行为 50。
- 退役：演示内容 42 条、冒烟测试内容约 65 条、演示球员 108 名、演示荣誉 60 条、演示字段（market_value/头像/球场/事件描述）清空。
- 展示账号：`kantailaolin` / `Kantai2026`（昵称「看台老林」）。

## 验证

1. 痕迹扫描（`sweep3.sql`，199 个文本列 × 15 个关键词）：内容、评论、通知、媒体、文件、发布选题、昵称等全部为 0；仅剩 `match_event.description` 上已退役演示比赛的描述（不可见）与两个保留测试账号的 `username`（App 不展示 username）。
2. 接口：`/api/app/feed` 1~3 页无兜底作者名、无 demo/演示 字样；内容详情、评论树、关联球队/球员、个人主页、通知、收藏、点赞、评论全部正常。
3. 后端日志确认过滤生效：`... AND author_id IN (SELECT id FROM sys_user WHERE is_deleted = 0 AND status = 'ACTIVE')`。
4. 全局搜索 `阿森纳` 返回真实球员；此前会返回「阿森纳演示中场03」，退役后为 0。
5. 模拟器实机（Pixel 8，`--dart-define=API_BASE_URL=http://10.0.2.2:8080` 的 debug APK）：登录展示账号后首页、我的、消息均正常，见本目录截图。

## 未做

- 后端测试套件未运行：`src/test` 中存在与主干不同步的编译错误（`FootballQueryServiceTests` 的构造参数少 2 个 mapper），为既有问题；且测试会读写 `south_stand`，会破坏本次数据，故本轮以 `-Dmaven.test.skip=true` 打包。
- 部署服务器（公网环境）未同步，本轮只处理本机开发库；上线前需在目标环境重跑 `community_media.sql` + `community_seed.sql` + 媒体文件同步。
- 图片为 Unsplash 免费图，如正式商用建议复核授权并沉淀为自有图库。
