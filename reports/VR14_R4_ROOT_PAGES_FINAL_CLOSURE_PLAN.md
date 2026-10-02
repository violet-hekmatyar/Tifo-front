# VR14-R4 根页面最终收口计划

状态：待执行模型执行
前置报告：`reports/VR14_R3_REVIEW_2026-10-02.md`
目标：修复"我的"看台卡路由缺陷，收口 f04 四项失败断言与首页两项视觉偏差，补齐返回链路守卫测试与同 APK 证据，建立两页偏差表后关闭 VR14。

## 1. 范围与冻结项

允许修改：

- `my_profile_page.dart`（两处 onTap 路由目标）；
- `match_card.dart`（未开始卡日期/时分布局）、`supplementary_feed_cards.dart`（排名卡列标签与重复副标题）、`followed_team_bar.dart`（球队名宽度约束）；
- 测试：`f04_home_feed_widget_test.dart`、`f17_user_center_acceptance_test.dart`、`f06_app_router_test.dart`。

冻结：R2 推荐组合策略、`pageSize=10`、`min-gap=3`、分页与曝光归因；R3 转会快讯 displayData 与全部 SQL；后端代码与契约；数据页比赛卡与日期分组排序（已登记为偏差/产品决策）；手机号验证码/微信登录、私信/IM/WebSocket/Push、完整淘汰树等既定排除项。不提交、不推送 Git；不顺手重做详情页或其他已通过页面。

## 2. M0："我的"看台卡路由修复与返回守卫

1. `my_profile_page.dart:240` 改为 `context.push('/users/me/followed-teams')`，`:247` 改为 `context.push('/users/me/followed-players')`。两路由已注册并挂在 rootNavigatorKey 上（`app_router.dart:188-196`），不得新增路由。
2. 修正 `f17_user_center_acceptance_test.dart` USER-05（约 317-350 行）：测试路由器注册 `/users/me/followed-teams`、`/users/me/followed-players`（可渲染 `FollowedEntitiesPage(teams: true/false)` 或等价桩），断言点击两张看台卡后到达对应页面；删除虚假 `/teams`、`/players` 桩路由。
3. 在 `f06_app_router_test.dart` 增加真实路由守卫用例：认证态进入 `/app/profile` → 点击"我关注的球星" → 出现 `FollowedEntitiesPage` → 触发返回 → 回到 `/app/profile` 且"我的"页面仍可见。仓库数据可复用该文件既有 fake 模式；关注球员数据不足时以既有 fake  repository 补齐，不伪造截图。
4. 完成门槛：新增/修正测试通过；手动或测试路径均验证"列表页 → 返回 → 我的"链路恢复。

## 3. M1：f04 四项失败收口与未开始卡日期显示

1. 未开始比赛卡按 R3 计划 M1"日期/时分分别布局"补齐日期表达：原型形态为"今天 4:00"；实现上日期（今天/明天/具体日期）与时分都必须完整可见、不截断，无比分时不显示伪造 `0 : 0`。真实 feed 第 2 页存在未开始比赛（`MATCH:15000000000000016` 等），以此验证。
2. 更新 `f04_home_feed_widget_test.dart` 两项时间断言：按新结构断言日期与时分各自完整可见、`maxLines` 不截断、无伪造比分；不再断言旧单字符串 `07-17\n20:00`。
3. 更新内容卡降级断言：缺封面时验证实际可见的本地降级资产 `assets/ui/home/neutral-football-cover.png`（或其对等语义），替代旧"帖子"文本断言。
4. 重建瀑布几何断言：按 R3 新分列策略，断言两列顶部同高、卡片等宽、卡序与后端 cardKey 顺序一致；不再复用旧 `index.isEven` 位置值。断言失败时以新预期节奏量测值为准，不得放松成恒真。
5. 完成门槛：`flutter test --no-pub test/features/feed/` 全绿，且执行记录逐项列明四个原失败用例的新断言内容。

## 4. M2：首页排名卡与顶部球队名

1. 排名卡补"排名/球队/积分"列标签（R3 计划 M1 明确要求）；移除与标题重复的联赛副标题行；条目只用真实 API 数据，不为凑行数填充。
2. 排名卡行内队名与顶部球队入口均不得截断真实显示名：`followed_team_bar.dart:74` 的 `maxWidth: 108` 取消或放宽至名称完整显示（栏已横向滚动，总宽不受限）；排名卡行内同理处理。360dp 与 140% 字体下允许横向滚动，不得截成无法辨认的残文。
3. 完成门槛：标准 375dp 截图中"Real Madrid"等名称完整可辨认；排名卡列标签可见；相关定向测试通过。

## 5. M3：验证、同 APK 证据与偏差表

1. `flutter analyze --no-pub` 通过；`flutter test --no-pub test/features/feed/ test/features/vr14_root_pages_regression_test.dart test/features/football/f06_football_widget_test.dart test/features/football/f06_app_router_test.dart test/features/user_center/f17_user_center_acceptance_test.dart test/shared/widgets/p1_media_widgets_test.dart` 全绿；前后端 `git diff --check` 通过。
2. 在普通 Windows Terminal / PowerShell 构建新 APK（禁止在 Codex 进程内构建），安装至模拟器并核对本地/设备完整 SHA-256 一致，记录于执行记录。
3. 同 APK 截图证据（标准 984×2400 ≈ 375dp，存入 `reports/VR14_R4_FINAL_EVIDENCE/`）：
   - 我的→我关注的球星→关注球员列表→返回"我的"的逐步截图（球队卡同路径一张即可）；
   - 首页：排名卡列标签、顶部球队入口完整名称；滚动至未开始比赛卡的日期/时分显示；
   - 首页 360dp 与 140% 字体各一张回归图（只验证上述改动区域无溢出）。
4. 建立首页/数据两页逐项偏差表（写入执行记录或证据目录）：逐项列出 R3/R4 已关闭项，以及登记项（数据页轮次字段契约缺失、日期分组状态优先排序、"全部"芯片、日期头格式），注明原因与后续归属，未关闭项不得写成通过。
5. 恢复设备 `1080×2400 / 420dpi / font scale 1.0`。

## 6. 给执行模型的指令

执行本计划，按 M0→M1→M2→M3 顺序只处理上述四项缺陷：两处路由目标、四个测试断言与未开始卡日期、排名卡列标签与球队名截断。每轮修改后只运行直接相关测试；APK 必须在普通 Windows 终端构建并核对哈希。最终提交执行记录：逐项完成/未完成、测试清单与结果、新 APK 完整哈希、同 APK 截图与两页偏差表。VR14 保持开启，等待 Plan 模型复验，不得自行宣称视觉验收通过或进入下一阶段。
