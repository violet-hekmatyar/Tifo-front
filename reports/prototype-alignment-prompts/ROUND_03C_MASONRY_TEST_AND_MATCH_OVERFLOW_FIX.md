# 原型对齐第 03C 轮修复 Prompt

任务：
根据 03B 已确认根因，修正瀑布流几何测试的卡片定位，并最小修复 MatchCard 在 412px、1.4 倍字体下的横向溢出。

范围：
- 只修改 `f04_home_feed_widget_test.dart` 和 `match_card.dart`。
- 不修改瀑布流生产布局、其他 Feed 卡片、Controller/Repository/domain/mock 数据、路由或后端。

要求：
- 测试不得按 `find.byType(ContentCard)` 的树遍历下标推断 Feed 顺序；应通过 m1–m8 的唯一标题分别定位其祖先 `ContentCard` 并读取 Rect。
- 修复测试中重复注册的 teardown：每个改写视口的测试各自正确恢复 `physicalSize` 和 `devicePixelRatio`。
- 保留 03B 的同列 x、左右列、独立纵向累积、奇数半列、MATCH 全宽及前后区段断言，并增加 `IntrinsicHeight` 不存在和 `takeException()` 为空的断言。
- MatchCard 根因是中间时间/比分作为非弹性 Row 子项在大字体下占用固有宽度。只调整比赛主体横排的约束/弹性，使两队、比分或时间在 412px 和 1.4 倍字体下完整或自然缩放且不溢出；不得通过裁掉内容、关闭字体缩放或降低全局字号规避。
- 比赛状态、比分/时间语义、队徽队名、点击与既有 Key 不变。

完成标准：
- 新增几何测试稳定通过，并真实覆盖指定卡片而非依赖树顺序。
- MatchCard 在目标尺寸和字体下无 RenderFlex overflow，原有 MATCH 测试不回归。
- `flutter analyze` 与完整 `f04_home_feed_widget_test.dart` 通过。

执行：
直接修改上述两文件，不启动模拟器、不 build APK、不运行全量或无关测试。

最终仅汇报：
- 修改文件
- 根因修复结果
- 验证结果
- 阻塞/剩余问题

成功标志：
Round 03C masonry and match overflow fix passed
