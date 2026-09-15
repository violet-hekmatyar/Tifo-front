# 第 05C 轮继续执行 Prompt：内容详情与评论体系完整收口

## 总目标

不要停留在当前分享测试失败。先按已确认根因修好测试与分享状态条件，再完整实现评论列表、排序分页、点赞删除、回复弹层、输入聚焦与提交状态，使内容详情业务域一次收口。

## 原型参考

- `C:\Users\hekmatyar\Desktop\足球APP\帖子详情.png`
- `C:\Users\hekmatyar\Desktop\足球APP\详情分享弹窗.png`
- `C:\Users\hekmatyar\Desktop\足球APP\资讯主页-评论区.png`
- `C:\Users\hekmatyar\Desktop\足球APP\资讯主页-评论区回复.png`
- `C:\Users\hekmatyar\Desktop\足球APP\资讯主页-回复评论区.png`
- `C:\Users\hekmatyar\Desktop\足球APP\资讯主页-回复评论区回复.png`

## 可修改范围

- `content_detail_page.dart`
- `comment_section.dart`
- 必要的 interaction presentation controller/widget
- content/interaction 目录下定向测试

不得修改 Repository/API/domain 契约、Feed、发布页、全局路由、本地 mock 数据源、后端和依赖。

## A. 先解除当前已知阻塞

当前失败不是两个状态监听路径不一致：第一次分享点击已成功打开弹层，否则测试无法点击“取消”；失败发生在取消后的第二次点击，因为没有等待 modal bottom sheet 退出动画。

1. 在 `f05_detail_interaction_widget_test.dart` 点击“取消”后执行 `pumpAndSettle()`，断言“复制链接”已消失且 Clipboard 未写入，再第二次点击分享。
2. 不得使用 `warnIfMissed: false`、直接调用回调、强制 enable 或跳过第二次打开来绕过真实点击。
3. 将分享按钮条件恢复为 `s.status == DetailStatus.ready`。当前改成 `s.detail != null` 不是根因，还会错误允许携带旧 detail 的 loading 状态分享。
4. 修复两条 analyze warning：Clipboard mock handler 的所有路径显式 `return null`；`if` 使用花括号。
5. 测试 ready 时 `IconButton.onPressed` 非空；loading/failure/notFound 时分享按钮 disabled、底部互动栏不存在。

## B. 完成内容详情互动行为验收

1. 分享：验证取消不复制；复制写入准确 `/contents/42`、关闭弹层、显示成功提示。
2. 点赞/收藏：使用有效 recommendationSource 和可观测 dispatcher；成功后分别断言 LIKE/FAVORITE 的 targetType、targetId、impressionId；inactive 或异常时不产生行为事件。
3. 评论入口：详情页持有或协调输入 FocusNode。点击底部评论必须同时滚动到输入区域并请求焦点，而不只是滚到 CommentSection 外框。
4. 保留底部栏计数、active/busy 状态、失败回滚、返回流程、作者/关联跳转、ARTICLE block 顺序与 unknown 降级。

## C. 评论列表与全部状态对齐

1. 按原型重排评论标题、总数、热门/最新切换、列表间距、分隔和绿色选中态。总数优先使用详情的 `commentCount`，不要用当前页 `items.length` 冒充总数。
2. 覆盖 loading、empty、failure/retry、ready、loadingMore、分页失败重试、到底状态；切换排序应重置旧列表，分页继续复用 controller 去重。
3. 评论项展示头像、昵称、发布时间、正文、回复、点赞和本人删除。长昵称/正文、空头像、nullable 时间/回复对象在 412px、1.4 倍字体下安全。
4. 评论点赞保留 optimistic 与失败回滚；busy 时防重复。删除入口仅当前用户本人可见，确认后删除，取消不得调用 repository。

## D. 回复预览与回复弹层

1. 根评论下的回复预览使用浅色圆角区域；显示回复人、可空 `回复 @昵称` 和正文。`replyCount` 大于预览数时显示“查看全部 N 条回复”。
2. 回复弹层使用圆角、拖动手柄、安全区和键盘适配；顶部展示根评论摘要，主体覆盖 loading、empty、failure/retry、分页加载和到底状态。
3. 点击回复项后关闭弹层、滚动到详情输入区并聚焦，显示“回复 @昵称”；支持取消回复目标。
4. 提交时继续使用现有 parentId/replyToUserId 语义，不制造额外层级或修改数据契约。

## E. 评论输入完整闭环

1. 普通评论与回复态共用输入区，提供稳定 Key，保留 1000 字限制、发送中禁用和明确状态反馈。
2. 空白或超长内容不调用 repository；失败保留输入文本和回复目标，可直接重试。
3. 成功后清空输入、退出回复态、刷新当前排序并触发现有 COMMENT 推荐行为。
4. 键盘出现时输入框和发送按钮不被底部栏遮挡；取消回复、关闭键盘、页面重建后的状态一致。

## F. 必须新增的行为级测试

除修复现有 `f05_detail_interaction_widget_test.dart` 外，新增或扩展评论 Widget 测试，至少覆盖：

- 分享取消→完全关闭→再次打开→复制；两条 warning 清零。
- ready/non-ready 底栏和分享状态。
- LIKE/FAVORITE 成功 attribution 与失败不发送。
- 点击详情评论按钮后滚动位置增加且 `comment_input` 获得焦点。
- empty、error/retry、热门/最新切换、分页成功/失败。
- 评论点赞 busy/回滚、本人删除确认/取消、他人无删除入口。
- 回复预览、打开回复弹层、失败重试、选择回复对象、取消回复。
- 空白不提交、失败保留文本与回复目标、成功清空并触发 COMMENT。
- 412px、DPR 1、1.4 倍字体和正确 teardown，无 RenderFlex overflow。

测试必须验证 repository 调用参数和可观察状态，不能只检查 Widget 数量或“无异常”。

## 最小验证

- `flutter analyze`
- 完整 `test/features/content`
- interaction/comment 相关定向测试
- `f05_publish_return_route_test.dart`
- 不启动模拟器、不 build APK、不跑全仓测试

## 最终仅汇报

1. 修改文件；
2. 已知阻塞根因修正；
3. 评论/回复/输入完成情况；
4. 新增测试场景及数量；
5. 验证结果；
6. 剩余阻塞。

成功标志：
Round 05C content interaction full closure passed
