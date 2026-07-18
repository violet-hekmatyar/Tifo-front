# F04 主框架与首页真实卡片流执行报告

> 日期：2026-07-17。自动化结果以本轮最终检查为准；人工视觉验收留给用户执行，不在报告中伪造通过。

| # | 项目 | 结果 |
|---:|---|---|
| 1 | 前端初始 Git 状态 | `main`，HEAD `121af3c feat: establish mobile client visual baseline`，开始时干净 |
| 2 | 后端初始 Git 状态 | `main`，HEAD `98ca87f feat: complete T12 comment hot ranking`，只读检查且干净 |
| 3 | F03.1 回归 | `F03.1 client visual baseline check passed` |
| 4 | 已读取资料 | 前端 00–13、F03/F03.1 报告、产品 PDF 第 1–5 页、后端 API/安全/验证/计划及 Feed/Profile 实现 |
| 5 | Feed 契约 | `GET /api/app/feed`；`tab/leagueId/teamId/pageNum/pageSize/cursor`；统一分页 |
| 6 | 契约差异 | 旧样例 cardType 为 `CONTENT_CARD/MATCH_CARD`，当前实现与真实响应为 `CONTENT/MATCH` |
| 7 | 后端健康/PID | health/db/redis 均 UP；F03 所有 PID `10000` |
| 8 | 主框架 | `StatefulShellRoute.indexedStack`，四分支状态保持 |
| 9 | 四入口 | 首页、数据、消息、我的；后三者不含假业务数据 |
| 10 | 首页 Header | 品牌、搜索、发布入口完成 |
| 11 | 首页筛选 | 推荐/资讯/关注集中映射到真实 `tab` |
| 12 | 关注球队 | 从 `/api/app/users/me/stand` 读取主队和关注球队，横向展示并按 ID 去重 |
| 13 | Feed 模型 | data DTO 转换为领域 sealed card；页面不解析 JSON |
| 14 | CONTENT 卡 | 封面、类型、两行标题、可选热评、作者、日期、点赞/评论只读展示 |
| 15 | MATCH 卡 | 联赛、球队/Logo、时间、三种状态、真实比分与可选赛况；缺比分不造 0:0 |
| 16 | Unknown 卡 | 安全类型文本、轻量日志、不展示原始 JSON、不阻断后续卡片 |
| 17 | 混合布局 | 连续内容卡双列，比赛/未知卡全宽，保持后端顺序 |
| 18 | 刷新分页 | 首屏/刷新/近底加载、防并发、去重、hasMore、追加失败保留列表与重试 |
| 19 | 状态保持 | 主壳 indexed stack、首页 PageStorage key、当前筛选保留；未做各筛选独立缓存 |
| 20 | 占位详情 | 搜索、发布、内容、比赛路由只显示后续任务说明和安全 ID |
| 21 | 修改文件 | `git status --short` 所列 F04 Flutter、测试、脚本、文档和本报告文件 |
| 22 | 新增依赖 | 无；继续使用已锁定 Flutter/Riverpod/go_router/Dio |
| 23 | Mock/Widget 测试 | 新增 DTO、控制器、卡片、混合流、主壳状态和大字/尺寸测试 |
| 24 | 真实 Feed smoke | `F04 local backend feed smoke passed`；使用前端 ApiClient/Repository |
| 25 | check-repo | `Frontend repository base check passed` |
| 26 | check-f03-1 | 聚合中再次通过：`F03.1 client visual baseline check passed` |
| 27 | check-mobile-f04 | `F04 Flutter main shell and feed check passed`；61 个默认测试通过，analyze 零问题 |
| 28 | smoke-mobile-feed-f04 | `F04 local backend feed smoke passed` |
| 29 | check-f04 | `F04 Flutter main shell home feed check passed` |
| 30 | APK 路径 | `apps/mobile/build/app/outputs/flutter-apk/app-debug.apk`，构建已复核 |
| 31 | 修改后端 | 否 |
| 32 | 重置数据库 | 否；真实测试仅创建唯一测试用户和合法偏好 |
| 33 | 假首页数据 | 生产代码无；测试 fixture 仅在 `test` 中 |
| 34 | 敏感信息 | 未发现；测试不打印密码和完整 Token |
| 35 | Git 写操作 | 未执行 add/commit/push/reset/clean |
| 36 | 人工视觉验收 | 未执行；见 `F04_UI_REVIEW_CHECKLIST.md` |
| 37 | 未完成项 | F05 内容/发布/互动，F06 数据/比赛详情，F07 消息/我的完整业务；均按范围保留占位 |
| 38 | 风险点 | 后端旧文档 cardType 命名滞后；筛选切换不保留每个筛选的独立缓存；需人工验证长列表真实视觉 |
| 39 | 是否建议提交 | 自动化已满足；建议完成人工视觉 checklist 后提交 |
| 40 | 建议提交信息 | `feat: add Flutter main shell and home feed` |

## 实际后端卡片字段

真实 `CONTENT` 包含 `cardId/contentId/contentType/title/summary/coverUrl/author/hotComment/publishTime/likeCount/commentCount` 等；真实 `MATCH` 包含 `cardId/matchId/leagueName/homeTeam/awayTeam/homeScore/awayScore/matchStatus/matchTime/eventSummary` 等。图片可为相对 URL 或空。前端只消费展示所需字段，对未知/畸形单卡降级，不复制后端 Entity。
