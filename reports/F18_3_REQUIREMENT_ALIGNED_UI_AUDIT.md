# F18.3 需求对齐 UI 与真实链路验收报告

## 结论

本轮已完成真实 Backend V1、Python 推荐服务与 Pixel 8 模拟器的联合验收，并产出 17 张截图和 1 段录屏。A～D、F 模块完成了实际链路验证；E、G 完成了可执行部分，但当前源码无法重新安装到设备，因而通知中心、最新返回顶部实现及最新 140% 字体表现不能签署最终通过。

当前结论：**业务主链路基本成立，但不具备发布就绪条件**。发布前必须解决当前源码构建阻塞、返回顶部方向、点赞分页契约与过期“直播中”数据问题，再用同一提交重新安装并复验。

## 验收基线

| 项目 | 实际基线 |
|---|---|
| Flutter 仓库 | `D:\Football-APP-Front`，提交 `031f587`，工作区开始验收时干净 |
| 后端 | 本地 Spring Boot，`http://127.0.0.1:8080` |
| 推荐服务 | `http://127.0.0.1:8100`，最终 `UP / modelReady=true` |
| 推荐模型 | `CF_V1_b2da84652c`，108 用户、152 内容、2174 条近 30 日训练行为 |
| 设备 | Pixel 8，Android 16 / API 36，1080×2400 |
| 字体 | 默认 100% 与 140% |
| UI 安装物 | 近期既有 `app-debug.apk`；当前源码因 Gradle loopback 错误未能重新生成和安装 |
| 数据原则 | 未清库、未改 schema、未运行旧阶段脚本、未新增 seed；只新增 1 条真实 EXPOSE 审计行为并验证幂等 |

## 模块覆盖

| 模块 | 实际执行内容 | 结果 | 证据 |
|---|---|---|---|
| A. 登录/偏好/持久化 | 使用已完成 onboarding 的真实登录用户；覆盖安装应用后仍保持登录态、主队和关注队伍；后端 onboarding options 可用 | 部分通过；未重新走一次全新注册 UI | [用户中心](f18-visual/screenshots/21-user-center.png)、[首页关注球队](f18-visual/screenshots/00-current-state.png) |
| B. Feed | 真实 recommend/news/following/team；分页；Top30 六类卡片；内容瀑布流；搜索入口；滚动/刷新；返回顶部源码审计 | 主链路通过；返回顶部方向不符合最终要求，发布入口在设备安装物中未跳转 | [首页](f18-visual/screenshots/00-current-state.png)、[滚动后](f18-visual/screenshots/01-feed-scrolled-back-to-top.png)、[录屏](f18-visual/recordings/feed-refresh-and-scroll.mp4) |
| C. 搜索/内容/评论 | 搜索 Manchester，真实返回球队、比赛、内容并进入内容详情；打开评论输入区 | 通过；比赛副标题仍直接展示 ISO 字符串 | [搜索](f18-visual/screenshots/30-search-results.png)、[内容详情](f18-visual/screenshots/31-content-detail-comments.png)、[评论区](f18-visual/screenshots/32-comments-thread.png) |
| D. 足球数据与详情 | 赛程、积分榜、球队概览、球员概览、比赛概览、阵容、当前排名；另对 team/player/match 全部详情接口做轻量真实请求 | 通过；`CURRENT_STANDING` 显示为当前排名 | [赛程](f18-visual/screenshots/10-data-home.png)、[积分榜](f18-visual/screenshots/11-current-standings.png)、[球队](f18-visual/screenshots/12-team-detail-overview.png)、[球员](f18-visual/screenshots/13-player-detail-overview.png)、[比赛](f18-visual/screenshots/14-match-detail-overview.png)、[阵容](f18-visual/screenshots/15-match-lineup.png)、[当前排名](f18-visual/screenshots/16-match-current-ranking.png) |
| E. 用户中心/通知 | 用户中心真实打开；likes 与 notifications 真实请求；通知定向 widget 测试 | 用户中心通过；设备安装物仍显示旧通知占位，当前源码通知页无法设备复验 | [用户中心](f18-visual/screenshots/21-user-center.png)、[设备通知页](f18-visual/screenshots/20-notifications.png) |
| F. 推荐 | A/B 用户筛选、两种主队偏好、Top10/20/30、类型与理由、重复稳定性、行为归因/幂等、Python 停服降级与恢复 | 通过，详见推荐专项报告 | [推荐专项报告](F18_3_RECOMMENDATION_EFFECT_REPORT.md) |
| G. 视觉与字体 | Pixel 8 默认字号、多核心页截图；140% 首页截图 | 既有安装物无明显 RenderFlex 溢出；当前源码未能重新安装，结论不能覆盖最新改动 | [140% 首页](f18-visual/screenshots/40-feed-font-140.png) |

## 真实接口与数据闭环

| 能力 | 真实结果 |
|---|---|
| Feed 四个入口 | recommend 20/93、news 20/100、following 20/88、team 20/35，均 `code=0` |
| Feed 类型 | Top30 同时出现 CONTENT 18、MATCH 6、DISCUSSION 1、HOT_COMMENT 1、RANKING 3、PLAYER_RATING 1 |
| 搜索 | Manchester 混合搜索返回 4 条：球队 1、比赛 2、内容 1 |
| 球队详情 | Manchester City 的 overview/players/stats/honors/matches/contents 均 `code=0`；players 1、honors 2、matches 2、contents 1 |
| 球员详情 | Erling Haaland 的 overview/stats/teams/career/matches/contents 均 `code=0`；比赛与内容均非空 |
| 比赛详情 | match 50004 的 overview/lineups/stats/ratings 均 `code=0`；统计为空但页面可安全处理 |
| 通知 | list 与 unread-count 均 `code=0`，当前 demo 用户通知总数 0 |
| 我的点赞 | 接口 `code=0`，但返回 25 条 records、`total=0/pages=0`，违反分页契约 |

## 视觉观察

| 场景 | 观察 |
|---|---|
| 默认字号瀑布流 | 双列结构稳定，CONTENT 为主；缺图时占位可用，标题按卡片宽度截断 |
| 140% 字号 | 首页无肉眼可见黄黑溢出条或重叠；比赛球队名换行为两行，内容卡信息明显更拥挤但仍可读 |
| 比赛详情 | 赛事、比分、事件、阵容、当前排名语义清楚 |
| 搜索 | 分类入口完整；比赛时间副标题显示 `2026-07-08T20:30`，不够面向普通用户 |
| Feed 实时性 | 当前日期下仍展示日期为 07-13 的“进行中”比赛，说明比赛状态或演示数据生命周期未及时更新 |

## 问题清单

共 8 项：P0 0、P1 5、P2 3。

| ID | 级别 | 范围 | 事实与影响 | 建议验收条件 |
|---|---|---|---|---|
| F18.3-01 | P1 | 构建/交付 | 当前源码执行 `flutter run --no-resident` 在 Gradle 9.1 daemon 连接阶段失败：`java.io.IOException: Unable to establish loopback connection`。JBR 21、Temurin 17、IPv4/plain socket 最小对照均复现；PowerShell TCP loopback 正常，问题位于宿主 Java NIO/Gradle 层。 | 修复宿主构建环境，用提交 `031f587` 重新安装并完成同版本复验。 |
| F18.3-02 | P1 | Feed | 当前源码在 `ScrollDirection.forward`（向顶部移动）显示返回顶部，在 `reverse`（向下浏览）隐藏，与最终确认的交互方向相反。 | 向下浏览超过阈值渐显，向上滑渐隐；真机录屏通过。 |
| F18.3-03 | P1 | 用户中心 | `/api/app/users/me/likes?pageSize=20` 实际返回 25 条，但 `total=0/pages=0`。页面分页与到底判断会失真。 | records 不超过 pageSize，total/pages 与真实记录一致。 |
| F18.3-04 | P1 | Feed/数据 | 当前日期下仍有 07-13 的比赛以 LIVE/“进行中”进入首页推荐，实时性结论不成立。 | 清理或推进比赛状态，确认过期比赛不再作为 LIVE 加权。 |
| F18.3-05 | P1 | 通知/交付物 | 设备上的既有调试产物仍显示“消息能力暂不可用”，而 Backend V1 与当前源码已有通知能力；说明安装物不代表当前源码。 | 同一提交的新调试包展示真实通知页、空态及红点。 |
| F18.3-06 | P2 | 发布入口 | 设备安装物对首页“发布”按钮多次真实点击均未发生页面跳转；当前源码存在 `/publish` 路由，但未能设备复核。 | 新构建中验证按钮进入发布页并可返回保留 Feed。 |
| F18.3-07 | P2 | 搜索 | 比赛搜索结果将 ISO 时间中的 `T` 直接展示给用户。 | 使用本地化日期时间格式。 |
| F18.3-08 | P2 | 推荐效果 | 对 B 用户成功写入带完整 attribution 的 EXPOSE 后，下一次 Top10 未发生变化；不能仅凭一次行为证明近期曝光抑制在前排产生可见效果。 | 用同用户连续真实曝光并记录 Top10 变化曲线，明确抑制阈值。 |

## 验证记录

| 检查 | 结果 |
|---|---|
| `flutter analyze` | 通过，No issues found |
| F18.2 Feed + Notification 定向测试 | 3/3 通过 |
| Pixel 8 实际页面导航 | 首页、搜索、内容、评论、数据、球队、球员、比赛、用户中心已执行 |
| Backend 轻量请求 | Feed/Search/Team/Player/Match/User/Notification 均完成；异常项已列入问题 |
| 推荐停服/恢复 | B 桶 `CF_V1 → RULE_V2 → CF_V1`，服务已恢复为 `UP/modelReady=true` |
| 数据变更 | 无 seed、无 schema 变更；行为接口增加 1 条审计 EXPOSE，重复请求未重复入库 |

## 证据清单

- 截图：`reports/f18-visual/screenshots/`，共 17 张。
- 录屏：`reports/f18-visual/recordings/feed-refresh-and-scroll.mp4`，共 1 段。
- 推荐明细：`reports/F18_3_RECOMMENDATION_EFFECT_REPORT.md`。

## 发布准备度

**暂不建议发布。** 主业务与推荐链路具备继续收口的基础，但当前源码无法生成同版本设备证据，同时存在返回顶部方向、点赞分页和过期直播状态三个明确契约/业务问题。修复后应只重跑受影响的 Feed、用户中心、通知、140% 字体和推荐曝光场景。

