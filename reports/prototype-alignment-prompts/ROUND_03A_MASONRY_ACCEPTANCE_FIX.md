# 原型对齐第 03A 轮收口 Prompt

任务：
补齐第 03 轮 CONTENT 瀑布流的关键验收覆盖，并消除列表构建中的重复分组计算。

范围：
- 只修改 `home_feed_page.dart` 的瀑布流局部实现和 `f04_home_feed_widget_test.dart`。
- 不改卡片视觉、其他五类卡片、顶部筛选、Controller/Repository/model/mock 数据、路由或后端。

要求：
- `_visualEntries(sections.entries)` 每次页面 build 只计算一次，不得在 `itemBuilder` 中随每个条目重复创建整份分组。
- 增加定向 Widget 测试，使用测试内构造数据覆盖：至少 3 个连续且高度不同的 CONTENT、奇数数量、CONTENT 前后或中间存在全宽非 CONTENT。
- 断言两列横坐标不同、同列卡片独立向下排列、没有 `IntrinsicHeight`、奇数末卡保持半列宽；断言非 CONTENT 保持全宽并位于对应两个 CONTENT 区段之间。
- 测试必须验证实际几何或可观察结构，不能只检查卡片数量；保留现有无热评收起、点击、顺序及 Shell 测试。
- 不新增依赖、不扩大实现范围。

完成标准：
- 瀑布流分组只计算一次，分页规模增长时不会在单次构建中重复遍历全部条目。
- 连续多卡、独立双列、奇数半列和全宽分段均有通过的定向断言。
- 第 03 轮现有视觉与交互行为不回归。

执行：
直接修改代码，只读取上述相关文件。开发中不启动模拟器、不 build APK、不跑全量测试；完成后只运行 `flutter analyze` 和 `f04_home_feed_widget_test.dart`。

最终仅汇报：
- 修改文件
- 修复与新增覆盖
- 验证结果
- 阻塞/剩余问题

成功标志：
Round 03A masonry acceptance fix passed
