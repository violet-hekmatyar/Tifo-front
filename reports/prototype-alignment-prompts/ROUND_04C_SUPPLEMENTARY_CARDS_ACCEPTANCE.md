# 原型对齐第 04C 轮验收 Prompt

任务：
补齐 HOT_COMMENT、DISCUSSION、RANKING、PLAYER_RATING 四类全宽卡片的边界状态和大字体验收；若测试暴露布局问题，在同一组件文件内最小修复。

范围：
- 只修改 `supplementary_feed_cards.dart` 和 `f10_feed_card_renderer_test.dart`。
- 不修改其他 Feed 卡片、首页布局、Controller/Repository/domain/mock 数据、路由或后端。

要求：
- 在 412px、1.4 倍字体下构造并验证四类卡片，测试数据覆盖长标题/长名称、缺失作者或图片、可选摘要/热评为空、RANKING 空 items、未知 `rankingType`、PLAYER_RATING 空 topPlayers/缺失比分。
- 断言 HOT_COMMENT/Discussion 可空区块自然收起且计数保留；RANKING 空态明确、未知类型不崩溃且不误跳错误实体；PLAYER_RATING 缺分显示 `vs`、空评分有明确空态。
- 四类卡片宽度一致且为全宽，无 RenderFlex overflow；关键长文本允许合理换行或省略，不关闭字体缩放。
- 保留正常数据下的球队/球员/内容/比赛点击、ValueKey、attribution/曝光链路和既有 renderer 测试。
- 若新增测试失败，只允许在 `supplementary_feed_cards.dart` 做响应式或 nullable 安全的最小修复，不重构模型。

完成标准：
- 正常、nullable、空数组、未知 ranking 类型和大字体长文本均有通过的定向证据。
- `flutter analyze`、完整 `f10_feed_card_renderer_test.dart` 与 `f04_home_feed_widget_test.dart` 全部通过。

执行：
直接实现，只读取上述组件、模型定义和两个测试文件。不启动模拟器、不 build APK、不跑全量测试。

最终仅汇报：
- 修改文件
- 新增边界覆盖与必要修复
- 验证结果
- 阻塞/剩余问题

成功标志：
Round 04C supplementary cards acceptance passed
