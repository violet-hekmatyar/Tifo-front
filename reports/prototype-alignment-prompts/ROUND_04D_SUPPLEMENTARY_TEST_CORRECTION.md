# 原型对齐第 04D 轮收口 Prompt

任务：
修正四类补充 Feed 卡片的边界测试，使其真实覆盖 412px 大字体、全宽一致和 unknown ranking 防误跳。

范围：
- 只修改 `f10_feed_card_renderer_test.dart`；若真实窄屏测试暴露布局缺陷，允许在 `supplementary_feed_cards.dart` 做最小响应式修复。
- 不修改其他生产文件、数据层、路由或后端。

要求：
- 将边界测试视口明确设为 412px 宽、足够高度、DPR 1，并分别注册 `resetPhysicalSize`、`resetDevicePixelRatio`；确保 1.4 倍字体的 `MediaQuery` 位于 `MaterialApp` 内实际页面上。
- 为 HOT_COMMENT、DISCUSSION、两种 RANKING、PLAYER_RATING 分别读取 Rect，断言卡片宽度一致且占满父级可用宽度，`takeException()` 为空。
- unknown RANKING 的测试 item 必须同时携带有效 `entityId` 或 `teamId`，点击后仍不得触发球队/球员回调，确保旧错误逻辑会被该测试捕获。
- 增加正常 TEAM、PLAYER 排名项的点击回调断言，证明防误跳修复未禁用合法跳转。
- 保留 nullable、空 items、空 topPlayers、`vs`、缺图片和长文本覆盖；不得删除或弱化现有测试。

完成标准：
- 412px、1.4 倍字体下四类卡片无溢出且全宽一致。
- unknown 排名有有效目标 ID 仍不可跳转，TEAM/PLAYER 正常跳转。
- `flutter analyze`、完整 `f10_feed_card_renderer_test.dart` 和 `f04_home_feed_widget_test.dart` 全部通过。

执行：
直接实现，只运行上述最小检查；不启动模拟器、不 build APK、不跑全量测试。

最终仅汇报：
- 修改文件
- 测试修正与必要布局修复
- 验证结果
- 阻塞/剩余问题

成功标志：
Round 04D supplementary card acceptance passed
