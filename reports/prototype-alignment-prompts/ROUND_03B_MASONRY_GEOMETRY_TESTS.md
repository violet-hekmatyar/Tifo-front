# 原型对齐第 03B 轮执行 Prompt

任务：
只补齐第 03 轮 CONTENT 瀑布流的 Widget 几何测试，完成本阶段验收证据。

范围：
- 只修改 `apps/mobile/test/features/feed/f04_home_feed_widget_test.dart`。
- 不修改任何生产代码、页面、组件、数据层、mock 源或后端；若测试暴露实际布局缺陷，停止并如实汇报。

要求：
- 在测试内构造一个页面：全宽 MATCH 前至少 5 个连续 CONTENT，MATCH 后至少 3 个连续 CONTENT；使用长短标题和有/无 hotComment 形成不同卡片高度。
- 使用足够高的测试视口，并通过唯一标题定位各 `ContentCard` 后读取 Rect。
- 断言同一列 x 坐标一致、左右列 x 不同、后续卡片紧随本列前一张而不是等待另一列、奇数第 5 张保持左侧半列宽。
- 断言 MATCH 宽度明显大于 CONTENT，且其纵向位置在前一瀑布流区段之后、后一瀑布流区段之前。
- 断言页面不存在 `IntrinsicHeight`，1.4 倍字体下无布局异常；保留现有全部测试。

完成标准：
- 连续多卡独立双列、奇数半列、全宽分段和大字体均有可重复通过的测试证据。
- `flutter analyze` 与 `f04_home_feed_widget_test.dart` 全部通过。

执行：
直接补测试，只读取本测试和构造测试数据必需的模型定义。不启动模拟器、不 build APK、不运行其他测试。

最终仅汇报：
- 修改文件
- 新增测试覆盖
- 验证结果
- 阻塞/剩余问题

成功标志：
Round 03B masonry geometry tests passed
