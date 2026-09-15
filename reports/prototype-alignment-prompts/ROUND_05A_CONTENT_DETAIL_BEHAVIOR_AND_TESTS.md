# 原型对齐第 05A 轮收口 Prompt

任务：
恢复详情底部栏点赞/收藏的推荐行为上报，并补齐第 05 轮新增详情交互的 Widget 测试。

范围：
- 只修改 `content_detail_page.dart` 及 content 目录下必要的定向测试，可新增一个详情交互测试文件。
- 不修改 Controller/Repository/domain、评论组件内部、发布页、路由、mock 数据或后端。

要求：
- 根因已确认：旧正文按钮在 `toggleLike/toggleFavorite` 成功后记录 LIKE/FAVORITE；迁移到底部栏后只保留了 toggle。将成功上报逻辑恢复到详情页面，并继续使用传入的 `recommendationSource`；失败或 source 无效时不得产生错误事件。
- 底部栏按钮增加稳定 Key，测试 ready 时显示，loading/error/notFound 时不显示；验证评论、点赞、收藏计数与 active 状态。
- 使用 fake interactions 和可观测 dispatcher，分别点击点赞/收藏并 flush，断言成功时产生对应行为且 attribution 保持；不得只断言 Controller 被调用。
- 测试分享按钮打开弹层，拦截 Clipboard platform call，断言写入 `/contents/{id}`、弹层关闭并出现“链接已复制”；取消不得写入。
- 使用长正文验证评论按钮调用后现有 CommentSection 被滚动到可见区域；验证底部栏不遮挡内容。412px、1.4 倍字体无异常。
- 保留返回、作者/关联跳转、ARTICLE 编辑权限和现有测试，不做视觉扩张。

完成标准：
- LIKE/FAVORITE 推荐行为链路恢复，成功、失败和无 source 边界正确。
- 底部栏、评论定位、复制/取消分享及非 ready 状态均有通过的定向证据。
- `flutter analyze`、content 定向测试和 `f05_publish_return_route_test.dart` 全部通过。

执行：
直接实现，只读取上述相关文件。不启动模拟器、不 build APK、不跑全量测试。

最终仅汇报：
- 修改文件
- 推荐行为修复
- 新增交互覆盖
- 验证结果
- 阻塞/剩余问题

成功标志：
Round 05A content detail behavior and tests passed
