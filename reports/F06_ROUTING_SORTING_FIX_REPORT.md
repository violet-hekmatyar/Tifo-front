# F06 比赛路由、排序与分页修正报告

> 日期：2026-07-18。人工复验尚未执行，不能宣称人工问题完全关闭。

## 人工问题与根因

人工看到真实数据页，但点击比赛后回到类似首页，导致球队、球员、事件和返回链路无法继续。根因不是 matchId、卡片 onTap 或 MatchDetailPage：数据卡已使用真实 `match.id` 和绝对 `/matches/{id}`。根因是 `authRedirect` 只把旧 `/match/` 识别为登录后合法路径，遗漏正式 `/matches/`，也遗漏 `/teams/`、`/players/`；`authenticatedReady` 因而把这些路径重定向至 `/app/home`。

## 路由修正

- GoRouter 设置 `rootNavigatorKey`；match/team/player 详情显式使用 `parentNavigatorKey`，位于 StatefulShellRoute 之上。
- 认证白名单加入 `/matches/`、`/teams/`、`/players/`；旧 `/match/` 继续兼容重定向。
- 数据页、首页 MATCH、球队赛程和内容 MATCH 均 push 同一 `/matches/:matchId`。
- 非法 matchId 保留在详情错误页，显示“比赛编号无效”；404 显示不存在/已下架，不回首页。
- 详情返回逐层 pop；无历史栈才进入 `/app/data`。

## 展示排序

集中纯函数 `sortMatchesForDisplay` 在首屏、刷新和分页合并后运行：

1. 进行中：真实 `LIVE`，兼容 IN_PROGRESS/PLAYING/HALF_TIME 等；保持后端相对顺序。
2. 即将开始：真实 `SCHEDULED`，兼容 NOT_STARTED/UPCOMING；时间升序，空时间组内置后。
3. 已结束：真实 `FINISHED`，兼容 ENDED/COMPLETED；时间降序，最近结束优先，空时间组内置后。
4. POSTPONED/CANCELLED/SUSPENDED/未知：统一置后并保持相对顺序。

排序不看比分、不修改 status、不回写后端。日期标题直接遍历排序后列表，因此允许进行中的不同日期组位于顶部。

## 可发现入口

- 数据比赛卡球队区和比赛详情主客队均有 Ink、chevron/语义标签并携带真实 teamId。
- 首页关注球队横条保留球队 Feed 筛选，同时提供显式 chevron 进入球队详情。
- 内容 TEAM/PLAYER/MATCH 继续使用真实 relationId。
- 比赛事件仅在真实 playerId 存在时显示球员查看图标和跳转；无 playerId 不猜测。
- 后端没有球队阵容列表，球员入口依赖真实比赛事件或内容关系，不伪造完整 roster。

## 分页

生产仍读取真实分页，没有补写数据。Footer 明确显示正在加载、追加失败点击重试和已经到底；追加失败停止滚动自动重试，旧列表保留。多页 Mock 使用第一页 2 场/hasMore、第二页 2 场，验证滚动触发、防重复、失败重试、追加去重、完整集合重新排序和最终到底。真实 important 当前仅 6 场，人工环境可能不足一页，因此以自动多页覆盖证明分页逻辑。

## 验证记录

- 新增/加强：真实 App Router、认证 redirect、排序纯函数、多页 Footer、球队/球员逐层入口和真实 smoke 状态/事件球员覆盖。
- Flutter analyze：零问题；全量测试：112 项通过；F06 移动端检查和 Debug APK 已通过。
- 真实 smoke：3 个联赛、6 场比赛；状态为 FINISHED/LIVE/SCHEDULED；所选详情含 2 个事件和 2 个真实 playerId，球队与事件球员查询通过。
- F05 全量历史回归通过；最终 `check-f06.ps1` 输出 `F06 Flutter football data details check passed`。
- APK：`apps/mobile/build/app/outputs/flutter-apk/app-debug.apk`。
- 后端修改：否；数据库重置：否；生产假 football 数据：否；Git 写操作：否。

## 风险与建议

真实比赛若没有带 playerId 的事件，人工需改用内容 PLAYER 关系验证球员页。本次真实 smoke 的所选比赛已有 2 个真实事件 playerId。人工 Pixel 8、140% 字体和系统返回链仍待用户复验。人工复验后建议提交：`fix: complete F06 football routing sorting and pagination`。人工复验完成前不进入 F07。

## 最终入口补充

首页球队入口在后续收口中进一步简化为整卡直接 push 球队详情，删除原右上角独立箭头，且不再先调用 `selectTeam`。root Navigator 的详情覆盖与 pop 返回机制不变，因此原 Feed tab、筛选、列表和滚动位置继续由首页实例保留。“全部”仍调用 `selectTeam(null)`。现实文字核验只写报告和修正 JSON，不改变本报告中的路由/排序实现，也不修改后端或数据库。
