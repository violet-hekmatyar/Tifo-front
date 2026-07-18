# F05 发布返回、Feed 刷新与首页分区修复报告

> 日期：2026-07-18。最终自动聚合已通过；人工复验尚未执行。

## 人工发现与根因

人工验收发现发布详情无法可靠返回原首页、返回后不能确认 Feed 刷新，并出现 `MATCH_1 → CONTENT_1 → MATCH_2`。发布入口本来使用 push，但成功后使用 `context.go` 替换整个路由栈；改用 replacement 后又发现发布页草稿 `PopScope` 会在文本仍存在时拦截程序化替换，因此必须在提交成功后先解除草稿拦截。首页旧 `_blocks` 按混合列表逐项渲染，只对相邻 CONTENT 配对，必然保留跨类型交错。

## 修正

- 首页 push 发布页；发布成功取得真实 contentId 后进入“已提交”状态，下一帧 `pushReplacement` 详情页，发布页不留在返回栈。
- 详情页明确返回按钮，并以 `PopScope` 统一 Android 返回。有历史栈 pop，无历史栈 go `/app/home`。
- 发布详情退出发送一次性 `FeedRefreshRequest`。原 Home 实例消费后调用 `FeedController.refresh()`；信号立即清除，控制器同时防重复刷新。
- refresh 保留旧列表、当前 tab/teamId 和滚动控制器；失败展示旧列表与重试提示。generation 阻止旧请求覆盖新筛选或刷新。

## 展示分区

集中式 `FeedDisplaySections.fromCards` 将原始卡片建立为：

1. MATCH：全宽、按后端和分页到达顺序；
2. CONTENT：双列、按后端和分页到达顺序，奇数最后一张占左列；
3. Unknown：兼容区末尾，不显示原始 JSON。

原始 `MATCH_1, CONTENT_1, MATCH_2, CONTENT_2, MATCH_3` 因此显示为 `MATCH_1, MATCH_2, MATCH_3, CONTENT_1, CONTENT_2`。这是明确改变跨类型全局展示顺序，但不改变任一类型内部顺序，不修改 DTO/domain 原始列表、后端接口、分页或推荐权重。第一页 MATCH_1/CONTENT_1 与第二页 CONTENT_2/MATCH_2 合并后为比赛区 MATCH_1/MATCH_2、内容区 CONTENT_1/CONTENT_2。

稳定去重使用 matchId、contentId、Unknown cardId。追加失败保留当前分区；筛选或下拉刷新以控制器新原始列表重新建区。

## 真实 Feed 核验

真实 smoke 发布唯一 POST，详情读取成功。重复观测（最新示例 contentId `2078386167343927298`）结果一致：recommend 未返回，news 未返回，following 第 3 页返回；真实球队筛选 teamId `30002` 未返回。新帖没有球队关联。该帖子经 `FeedDisplaySections` 位于内容区；真实 MATCH 统一在展示内容区之前。结果受后端 tab、球队关系、排序和分页规则影响，前端未注入假帖子，也未修改数据库规则或重置数据库。

## 测试与风险

新增/修正覆盖路由 replacement、草稿拦截解除、顶部与 Android 返回、无历史兜底、首页状态保留、一次性刷新、刷新失败与竞态、稳定去重、交错及跨页分区、Unknown、全宽比赛/双列内容、Pixel 8 大尺寸布局。全量 88 个测试通过、Flutter analyze 零问题、真实 smoke 通过、Debug APK 构建通过；最终 `check-f05.ps1` 输出 `F05 Flutter content publish interaction check passed`。

新增 MATCH 到比赛区会增加内容区上方高度；ScrollController 不被重建，但 Flutter 无法在所有动态卡片高度下保证内容像素锚点绝对不移动，这是已知轻微位移风险，不能通过隐藏 MATCH 规避。

人工复验未执行，问题尚不能宣称完全关闭。请按 `F05_UI_REVIEW_CHECKLIST.md` 完成本轮新增清单。
