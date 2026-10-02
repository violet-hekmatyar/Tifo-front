# VR14 M0 基线执行记录

日期：2026-09-30  
范围：首页、数据、我的、消息四个根模块的当前实现与直接契约；未修改业务实现、后端或数据库。

## 只读运行基线

- `GET /api/public/health`：`code=0`。
- `GET /api/app/feed?tab=recommend&pageNum=1&pageSize=10`：`code=0`，当前卡片类型为 `CONTENT, CONTENT, CONTENT, DISCUSSION, CONTENT, CONTENT, CONTENT, HOT_COMMENT, CONTENT, MATCH`。
- 当前推荐首 6 条没有 `RANKING` 或 `PLAYER_RATING`，与首页原型要求的积分/评分专用卡节奏不符。
- 使用既有 `test_user`（用户 ID `10002`）只读登录后，通知接口返回 `total=8`，未读数为 `5`；通知数据在后端存在，问题不能简单归因为数据库为空。
- 用户截图中的“我的高亮但仍显示首页”未在现有源码检查和既有复检中稳定复现，因此 M0 不修改路由。

## 新增定向测试

文件：`apps/mobile/test/features/vr14_root_pages_regression_test.dart`

- 首页基线测试以当前推荐接口形状构造快照，要求首页具备积分榜和赛后评分专用卡。
- 当前基线实际失败：找不到 `积分榜`，证明测试不是静态永远通过断言。
- 不同球队媒体身份字段测试通过，作为 M1 防止球队 ID/队徽映射再次合并的保护。

## M0 结论

M0 完成：已记录一个可复现的首页专用卡缺失失败；通知后端数据存在但客户端运行态仍需在 M1/M4 联调中核对；路由错位暂不作为已确认根因。进入 M1 前不修改 Feed 算法、候选上限或底部路由。
