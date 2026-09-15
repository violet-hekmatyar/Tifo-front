# 原型对齐第 05B 轮收口 Prompt

任务：
为第 05 轮新增的内容详情底部栏、评论定位、分享和推荐行为补齐 Widget 验收测试。

范围：
- 主要新增 content 目录下的详情交互测试文件；原则上不改生产代码。
- 若测试暴露第 05 轮范围内的明确问题，只允许最小修改 `content_detail_page.dart`；不改 Controller/Repository/domain、评论组件内部、路由、mock 数据或后端。

要求：
- 用 fake content/interaction repository 构造 ready 详情，断言评论、点赞、收藏三个稳定 Key、计数与 active 图标；loading、failure、notFound 时底部栏不显示。
- 传入有效 `recommendationSource` 并注入可观测 dispatcher。分别点击点赞、收藏，等待操作完成后 flush，断言只在成功时产生 LIKE/FAVORITE，且 target 与 attribution 未丢失。
- 使用足够长的正文使评论区初始位于屏幕外；点击评论 Key 后，断言详情列表发生滚动且现有 CommentSection 被定位到可见区域。
- 拦截 Flutter `SystemChannels.platform` 的 Clipboard 调用：验证分享入口打开圆角弹层；“取消”不复制且关闭；“复制链接”写入准确的 `/contents/{id}`、关闭弹层并显示“链接已复制”。测试结束恢复 method handler。
- 在 412px、DPR 1、1.4 倍字体下执行 ready 详情交互并断言无布局异常；正确恢复视口和像素比。
- 保留现有返回、编辑权限、ARTICLE block 和内容模块测试，不通过弱化断言规避问题。

完成标准：
- 新增功能均有可重复的行为级测试，不只是查找文字或 Widget 数量。
- 成功/失败上报、非 ready 底栏、评论定位、复制/取消分享和大字体全部通过。
- `flutter analyze`、完整 `test/features/content` 和 `f05_publish_return_route_test.dart` 通过。

执行：
直接补齐测试并处理其暴露的本轮问题。不启动模拟器、不 build APK、不跑全量或无关测试。

最终仅汇报：
- 修改文件
- 新增行为覆盖与必要修复
- 验证结果
- 阻塞/剩余问题

成功标志：
Round 05B content detail interaction tests passed
