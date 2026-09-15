# 第 05E 轮执行 Prompt：安全整合 05D 并完成最终验收

## 任务

在主工作目录 `D:\Football-APP-Front` 上，把 detached worktree 中已经实现并通过测试的评论体系按语义安全整合进当前 01–05C 累积代码，同时保留主目录已有的分享、推荐行为、Feed 与视觉成果。持续执行到整合、补测和最小验证全部通过；除非出现有证据且范围内无法解决的真实阻塞，否则不得提前停止。

## 关键背景

- **目标目录（唯一允许写入）**：`D:\Football-APP-Front`
- **只读参考实现**：`C:\Users\hekmatyar\.codex\worktrees\5739\Football-APP-Front`
- 参考 worktree 从提交 `db0aeeb` detached 创建，没有继承主目录的未提交 01–05C 改动。
- 参考实现自身已复验：`flutter analyze` 通过、评论专项 13 项通过、内容测试 32 项通过。
- 但参考 worktree 的详情页没有主目录已完成的分享按钮、Clipboard 流程和 `f05_detail_interaction_widget_test.dart`，所以不能整文件替换或直接视为 05D 主线通过。

## 持续执行纪律

1. 直接修改目标目录，不输出长篇计划后停止。
2. 编译错误、测试失败、冲突、异步测试问题和布局溢出都属于本轮应解决问题，不算阻塞。
3. 禁止 `git reset`、`git checkout --`、强制复制整个文件、覆盖目标目录、清理未提交改动、cherry-pick 不存在的提交或改变 worktree 结构。
4. 对三个生产文件逐段比较，手工/补丁式迁移语义变化；发生结构冲突时以目标目录现有功能为基线，把评论能力融合进去。
5. 只有必要契约不存在、必须越权修改禁止范围或工具环境持续不可用且替代方案也失败时才允许停止，并提供命令和错误证据。

## 允许修改

- `apps/mobile/lib/features/content/presentation/pages/content_detail_page.dart`
- `apps/mobile/lib/features/interaction/presentation/controllers/comment_controller.dart`
- `apps/mobile/lib/features/interaction/presentation/widgets/comment_section.dart`
- `apps/mobile/test/features/content/f05_detail_interaction_widget_test.dart`
- `apps/mobile/test/features/interaction/comment_section_widget_test.dart`
- 必要的同目录局部测试 fake

禁止修改 Repository/API/domain 契约、Feed、发布页、路由、主题、后端、数据库、依赖及其他业务模块。

## 阶段一：安全迁移评论实现

从只读参考实现中迁移并按目标现状调整以下能力：

- `CommentsState.moreFailure`、首屏请求版本保护、分页去重/失败重试、防重复请求。
- 评论点赞 optimistic/busy/失败回滚状态保持。
- 删除成功本地移除、失败保留与 busy 释放。
- 楼中楼提交使用 `rootId ?? commentId` 作为根 `parentId`，保留 `replyToUserId`。
- `CommentSection` 的外部/内部 FocusNode 正确所有权、输入锚点、权威 `commentCount`、评论变化回调。
- 评论完整状态、排序、分页、到底、点赞、删除确认、回复预览。
- `_RepliesSheet` 的原位重试、空态、分页、去重、到底、安全区与关闭后的回复聚焦。
- 输入空白/长度/发送中校验、失败保留、成功清空、COMMENT 回调一次。

迁移后不得出现两套底部互动栏、两个输入 FocusNode、重复 Key 或重复推荐事件。

## 阶段二：强制保留主目录既有能力

以下主目录能力必须原样可用，不能因为参考 worktree 缺失而消失：

- `content_detail_share` 只在 `DetailStatus.ready` 可用。
- 分享弹层“取消”不复制；退出完成后可再次打开；复制准确 `/contents/{id}` 并显示“链接已复制”。
- 固定底栏评论/点赞/收藏稳定 Key。
- 点赞和收藏成功分别上报 LIKE/FAVORITE，失败或无有效 recommendation source 不误报。
- 内容详情正文、ARTICLE/POST、作者和关联跳转、返回逻辑不回归。
- 01–04 已完成的主题与 Feed 文件一律不触碰。

整合详情底栏时，以目标目录现有 `_DetailActionBar` 为基础增加评论输入滚动/聚焦，不要用参考 worktree 的 `_DetailBottomBar` 整体覆盖它。

## 阶段三：迁移并修正评论专项测试

把参考 worktree 的 `comment_section_widget_test.dart` 迁入目标目录，但要修正以下证据缺口后才能保留 CMT-01～CMT-12 的通过结论：

1. CMT-01 详情测试必须断言获得焦点的是 `comment_input` 对应 FocusNode/EditableText，不能只断言 `primaryFocus != null`。
2. CMT-03 必须以 Widget 方式分别看到 loading、empty、error、点击 retry 后 ready；不能用 controller unit 状态代替 empty UI。
3. CMT-07 保留本人/他人、取消、成功、失败断言，并确认失败不移除原评论。
4. CMT-09 保留回复弹层首屏失败后**原位**重试、分页去重和到底；不得通过关闭重开实现重试。
5. CMT-10 同时断言：普通评论 `parentId=0`；回复根评论使用根 id；回复子评论仍使用根 id，并传准确 `replyToUserId`。
6. CMT-11 增加纯空白与超过 1000 字不调用 repository；提交失败保留文本、回复目标和可重试状态；成功只调用一次回调。
7. CMT-12 除 412px/DPR 1/1.4 倍字体无异常外，必须实际运行并保留主目录 `f05_detail_interaction_widget_test.dart` 对分享及 LIKE/FAVORITE 的断言，不能只在报告中声称回归通过。
8. 所有测试恢复 physicalSize、devicePixelRatio 和平台 mock；不得使用 `warnIfMissed: false`、直接调用不可点击控件回调或任意长延时绕过真实交互。

## 阶段四：验收矩阵

全部项目必须在**目标目录**中有实现和测试证据：

| 编号 | 验收结果 |
| --- | --- |
| CMT-01 | 详情底栏及根/子回复均滚动到真实输入并聚焦 |
| CMT-02 | 权威评论总数不被加载条数替代 |
| CMT-03 | loading/empty/error/retry/ready UI 完整 |
| CMT-04 | 排序重置及旧请求竞态安全 |
| CMT-05 | 分页去重、失败重试、防重复和到底 |
| CMT-06 | 点赞 optimistic、busy、成功与回滚 |
| CMT-07 | 删除权限、取消、成功与失败 |
| CMT-08 | 回复预览和查看全部计数 |
| CMT-09 | 回复弹层原位重试、分页、去重和到底 |
| CMT-10 | 普通/根回复/子回复参数及聚焦准确 |
| CMT-11 | 空白/超长/失败保留/成功清空及 COMMENT 一次 |
| CMT-12 | 大字体布局、分享、LIKE/FAVORITE、内容返回均不回归 |

## 最小验证

所有命令必须从 `D:\Football-APP-Front\apps\mobile` 运行：

- `flutter analyze`
- `flutter test test/features/interaction/comment_section_widget_test.dart`
- `flutter test test/features/content/f05_detail_interaction_widget_test.dart`
- `flutter test test/features/content`
- `flutter test test/features/content/f05_publish_return_route_test.dart`
- 回到仓库根目录运行 `git diff --check`

不跑全仓测试，不启动模拟器，不 build APK，不提交，不进入第 06 轮。

## 最终汇报

只有目标目录整合完成并通过验证后才汇报：

1. 修改文件；
2. 如何避免覆盖主目录未提交改动；
3. CMT-01～CMT-12 每项对应的具体测试名称和结果；
4. 各验证命令与测试数量；
5. 阻塞；无则写“无”。

全部通过后输出：

`Round 05E integrated content interaction acceptance passed`
