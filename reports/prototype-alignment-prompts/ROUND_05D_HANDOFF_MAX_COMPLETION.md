# 第 05D 轮交接 Prompt：持续执行至评论体系完整通过

## 任务

接手当前未完成的 05D，直接在现有改动上继续，完整收口内容详情中的评论、回复、输入和行为级测试。尽最大努力自主完成全部要求；除非出现经过验证且在允许范围内无法解决的真实阻塞，否则不得停止、等待用户确认或把未做事项留给下一轮。

## 持续执行规则（最高优先级）

1. 不要重新规划项目，不要输出阶段性总结后结束；只需简短说明正在处理什么，然后持续修改、运行定向测试、定位失败并修复。
2. 编译错误、测试失败、布局溢出、fake 不完善、异步测试不稳定、实现比预期复杂，都不是阻塞，必须继续处理。
3. 一种实现方式失败时先查根因，再采用更小、更符合现有结构的方案继续；不要通过删除断言、跳过测试、强制成功、增加任意延时或修改无关代码规避问题。
4. 只有以下情况可以停止：缺少项目中不存在的必要契约/能力、需要越权修改明确禁止的范围、外部工具或环境持续不可用且已验证替代方案也不可行。报告时必须给出命令/错误/调用链证据以及已尝试的解决方式。
5. 在所有验收编号通过前不得输出成功标志；如果因真实阻塞停止，逐项列出尚未完成编号。不得用“后续补测试”“现有逻辑可用”“本轮时间不足”作为剩余问题。
6. 若上下文或执行时间紧张，减少解释和视觉微调，优先完成正确行为、专项测试和最小验证；不要提前交付半成品。

## 原型参考

- `C:\Users\hekmatyar\Desktop\足球APP\资讯主页-评论区.png`
- `C:\Users\hekmatyar\Desktop\足球APP\资讯主页-评论区回复.png`
- `C:\Users\hekmatyar\Desktop\足球APP\资讯主页-回复评论区.png`
- `C:\Users\hekmatyar\Desktop\足球APP\资讯主页-回复评论区回复.png`
- `C:\Users\hekmatyar\Desktop\足球APP\帖子详情.png`

## 已完成基线：保留并验证，不要重复推翻

- 分享仅在 `DetailStatus.ready` 可用；取消后等待弹层退出、再次打开、复制 `/contents/42` 和成功提示的测试已通过。
- 固定底栏的评论/点赞/收藏 Key 已存在，LIKE/FAVORITE 成功上报已恢复。
- 详情页已持有并释放评论输入 FocusNode，向 `CommentSection` 传入权威 `commentCount`。
- `CommentSection` 已有 `comment_input` Key，楼中楼提交使用 `replyTo.rootId ?? replyTo.commentId` 作为 `parentId`，并保留 `replyToUserId`。
- 已增加顶层评论“已经到底了”、回复弹层拖动手柄/圆角/SafeArea 和基础失败提示。
- 当前 `flutter analyze` 与 `flutter test test/features/content`（32 项）已通过。

不得无证据地修改上述分享流程、推荐上报、Repository/API/domain 契约或已通过测试。

## 允许范围

- `apps/mobile/lib/features/content/presentation/pages/content_detail_page.dart`
- `apps/mobile/lib/features/interaction/presentation/widgets/comment_section.dart`
- 必要时最小修改 `apps/mobile/lib/features/interaction/presentation/controllers/comment_controller.dart` 及其 presentation state
- `apps/mobile/test/features/content/f05_detail_interaction_widget_test.dart`
- 新建/修改 `apps/mobile/test/features/interaction/` 下评论专项测试和局部测试 fake

禁止修改后端、数据库、Repository/API/domain 契约、Feed、发布、路由、依赖和其他业务页面。继续使用现有本地模拟/测试数据，不把原型示例写入生产 Widget。

## 顺序执行，不得跳项

### 阶段一：把现有详情联动变成可验证闭环

- 底部评论按钮滚动到实际输入区域并请求真实焦点；测试必须断言滚动位置变化、`comment_input` 获得焦点，而非只断言无异常。
- 直接点击根评论“回复”以及从回复弹层选择某条回复后，都要自动滚动、聚焦，并显示准确“回复 @昵称”；关闭弹层后应等待退出完成再操作底层页面。
- 外部和内部 FocusNode 生命周期正确；输入尚未构建或页面销毁时安全。
- 权威总数与已加载条数不同的夹具中，标题仍显示详情 `commentCount`；不可用时只显示“评论”。

### 阶段二：顶层评论状态、排序、分页、点赞与删除

- 对齐绿色紧凑排序控件和评论项层级；覆盖 loading、empty、failure/retry、ready、loadingMore、分页失败重试、到底。
- 热门/最新切换重置旧页；为异步竞态增加最小的过期请求保护，较慢旧请求不得覆盖新排序结果。
- 分页按 commentId 去重；失败保留已有列表并可再次加载，busy 防重复。
- 评论点赞必须可观察地 optimistic 更新，重复点击受控，失败回滚并显示反馈。
- 删除仅本人可见；取消不调用 repository，确认成功刷新/移除，失败保留评论并反馈。若页面权威总数无法即时回写，至少保证列表正确并重新加载详情/使用现有回调同步，禁止伪造总数。

### 阶段三：楼中楼回复弹层完整状态

- 回复预览使用浅色圆角块，安全展示昵称、可空“回复 @昵称”和正文；`replyCount > preview.length` 时显示“查看全部 N 条回复”。
- 当前失败按钮只是关闭弹层，不算重试。改为在弹层内原位重试，并补 empty、loading、ready、分页加载、分页失败重试、到底状态。
- 分页继续调用现有 `controller.replies(root, page: n)`，按 commentId 去重，不修改契约；旧请求不得污染已经关闭或切换的弹层。
- 弹层顶部保留根评论摘要和关闭入口，适配 SafeArea、键盘、412px 宽和 1.4 倍字体。

### 阶段四：输入提交与失败恢复

- 普通评论和回复共用输入；取消回复只清除目标，不清除已输入文字。
- 空白或超长不调用 repository；发送中禁用并防止重复提交。
- 失败后保留文本、焦点与回复目标并给出可见反馈；成功后清空文本和回复目标、刷新当前排序，并且 `onCommentCreated`/COMMENT 行为只触发一次。
- 使用 fake 精确断言普通评论 `parentId=0`；回复使用根评论 id 和目标用户 id，不能产生第三层 parentId。

### 阶段五：补齐专项行为测试并自审

创建 `apps/mobile/test/features/interaction/comment_section_widget_test.dart`（可按测试结构拆成少量文件），使用可控制分页、延迟和异常的 fake repository。必须是行为测试，断言真实调用参数与 UI 状态。

逐项完成以下矩阵：

| 编号 | 强制验收结果 |
| --- | --- |
| CMT-01 | 详情底栏滚动到输入且获得焦点 |
| CMT-02 | 权威总数不等于加载条数时仍显示正确 |
| CMT-03 | loading/empty/error/retry/ready 完整 |
| CMT-04 | 热门/最新切换及旧请求竞态安全 |
| CMT-05 | 分页去重、失败重试、防重复和到底 |
| CMT-06 | 点赞 optimistic、busy、成功及失败回滚 |
| CMT-07 | 本人删除可见，取消/成功/失败；他人不可见 |
| CMT-08 | 回复预览及查看全部计数正确 |
| CMT-09 | 回复弹层 empty/error 原位 retry/分页/到底完整 |
| CMT-10 | 根回复和子回复选择均聚焦；parentId/replyToUserId 正确，可取消目标 |
| CMT-11 | 空白不提交、失败保留、成功清空且 COMMENT 只触发一次 |
| CMT-12 | 412px、DPR 1、1.4 倍字体无异常；现有分享及 LIKE/FAVORITE 不回归 |

## 最小验证

在实现完成后统一运行：

- `flutter analyze`
- `flutter test test/features/interaction/comment_section_widget_test.dart`（若拆分则运行全部新评论专项文件）
- `flutter test test/features/content`
- `flutter test test/features/content/f05_publish_return_route_test.dart`

不跑全仓测试，不启动模拟器，不 build APK，不进入第 06 轮。

## 最终汇报

仅在全部完成或出现符合定义的真实阻塞后汇报：

1. 修改文件；
2. 完成行为；
3. CMT-01～CMT-12 对照表，每项写出具体测试名称和通过/未通过；
4. 各命令与测试数量；
5. 真实阻塞及证据；无则写“无”。

全部编号和最小验证通过后才能输出：

`Round 05D comment system completion passed`
