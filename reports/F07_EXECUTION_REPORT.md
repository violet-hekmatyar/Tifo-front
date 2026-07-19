# F07 用户中心、关注与消息基础执行报告

> 日期：2026-07-18。人工视觉验收未执行，不伪造结论。

## 后端能力与实现

- 当前用户真实接口覆盖 summary、stand、contents、favorites、comments；`/users/me/contents` 是“我的发布”的确定数据源。
- 公开用户覆盖 profile、contents、followings、followers；用户关注使用 POST/DELETE，球队与球员使用通用 toggle。
- following Feed 服务端会纳入关注用户作者、关注球队和关注球员关系。
- 缺口：无“我的点赞”分页查询；无消息/通知列表、未读数量、单条/全部已读及消息目标字段。客户端显示正式不可用状态，未伪造数据。

Flutter 新增 `user_center` data/domain/presentation 分层、真实我的页面、昵称/简介编辑、公开用户页、通用分页列表、收藏取消、本人评论删除、球队/球员关注管理和用户关注乐观更新/回滚。Feed 卡与内容详情作者均可进入公开主页。正式路由覆盖 `/users/me/*`、`/users/:userId` 及 `/messages`。

## 验证与边界

- F07 定向测试：4 项通过，覆盖我的发布分页、关注乐观更新/防重复/自关注阻止及消息缺口页。
- 最终通过：analyze 零问题、全量 121 项测试通过、Android Debug APK 构建成功，`check-f07.ps1` 输出 `F07 Flutter user center follow message check passed`。
- 官方真实 smoke 通过：用户 B 的专用“我的发布”命中新帖；用户 A 关注 B 后，B 的第二篇内容在 following Feed 第 1 页命中；关注/粉丝、收藏、评论及取消关注均验证成功。
- 过程偏差：最终链第一次 analyze 因 6 个单行 `if` lint 停止，修正后通过；首次通过后复核发现资料编辑及列表内取消收藏/删除评论仍应补齐，完成后又执行最终链。合计 analyze 3 次（1 次失败、2 次通过）、全量测试 2 次、APK 2 次、正式 smoke 2 次。另有一次未带集成开关的编译预检因测试缺少提前 return，虽标记 skipped 但仍执行了后端主体；已修正。真实后端主体合计执行 3 次并留下额外唯一测试帖子。
- 未运行 F01–F06 聚合脚本；未修改后端；未重置数据库；未执行 Git add/commit/push。
- 每次真实 smoke 创建两个唯一测试账号及两个唯一帖子，并清理临时评论、收藏与用户关注；普通用户无帖子删除接口，因此三次执行的账号和帖子保留为已知测试数据。
- 生产代码无假用户、假消息或本地发布历史。

## 未完成与风险

- 我的点赞、消息/通知能力等待后端正式契约。
- 用户发布的测试帖子无法由普通用户清理；真实设备的长昵称、140% 字体、返回位置与网络失败观感仍需人工验收。
- 建议提交信息：`feat: add Flutter user center follow and message flows`。
