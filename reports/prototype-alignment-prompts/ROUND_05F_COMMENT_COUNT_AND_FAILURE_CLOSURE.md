# 第 05F 轮执行 Prompt：评论总数同步与失败状态最终收口

## 任务

在 `D:\Football-APP-Front` 修复 05E 审查确认的两个遗漏：评论创建/删除后详情页权威 `commentCount` 没有刷新，以及回复提交失败后的目标标和焦点缺少行为测试。直接持续执行到实现和定向验证全部通过；普通测试失败不得作为停止理由。

## 已确认根因

- `CommentSection` 已定义并在提交/删除成功后调用 `onCommentsChanged`，但 `content_detail_page.dart` 创建它时没有传入回调，因此详情标题和固定底栏可能继续显示旧评论总数。
- 当前 CMT-11 只验证普通评论失败保留文本，没有验证回复失败后 `reply_target`、文本和焦点继续保留。

## 允许修改

- `content_detail_page.dart`
- 必要时最小修改 `content_detail_controller.dart`，用于不破坏 ready 页面结构的权威详情刷新
- `comment_section.dart`（仅确有必要）
- `f05_detail_interaction_widget_test.dart`
- `comment_section_widget_test.dart`

禁止修改 Repository/API/domain 契约、Feed、发布、路由、主题、后端、数据库和依赖；不得重写已经通过的评论与回复体系。

## 要求

1. 详情页必须把评论变化回调接到详情控制器的权威刷新；创建或删除成功后，评论标题与固定底栏最终显示 Repository 返回的新 `commentCount`。
2. 刷新期间保留当前详情正文和底栏，不能闪回全屏 loading、丢失滚动位置或重复触发 DETAIL 推荐行为；刷新失败保留旧详情并安全提示。
3. 评论创建失败或删除失败不得刷新权威详情总数。
4. 增加详情集成测试：fake detail 依次返回不同 `commentCount`，分别验证创建和删除成功后的标题/底栏更新，并断言分享按钮仍可用。
5. 扩充 CMT-11：先选择回复目标，再制造提交失败，断言文本、`reply_target`、准确昵称和输入焦点仍保留；恢复成功后才清空目标与文本，且回调只触发一次。
6. 保留 CMT-01～CMT-12、分享复制、LIKE/FAVORITE、COMMENT、分页竞态和返回逻辑，不弱化任何现有断言。

## 最小验证

- `flutter analyze`
- `flutter test test/features/interaction/comment_section_widget_test.dart`
- `flutter test test/features/content/f05_detail_interaction_widget_test.dart`
- `flutter test test/features/content`
- `flutter test test/features/content/f05_publish_return_route_test.dart`
- `git diff --check`

不启动模拟器、不 build APK、不跑全仓测试、不进入第 06 轮。

## 最终仅汇报

1. 修改文件；
2. 权威计数刷新方式及失败行为；
3. 新增测试名称与断言；
4. 验证命令和数量；
5. 阻塞；无则写“无”。

全部通过后输出：

`Round 05F content interaction final closure passed`
