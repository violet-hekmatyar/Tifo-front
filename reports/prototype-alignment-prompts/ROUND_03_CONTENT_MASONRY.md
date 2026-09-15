# 原型对齐第 03 轮执行 Prompt

任务：
参照 `C:\Users\hekmatyar\Desktop\足球APP\首页.png`，将首页 CONTENT 卡片改为双列错落瀑布流，并对齐内容卡片视觉。

范围：
- 只修改 CONTENT 展示分组、首页对应布局、`content_card.dart` 及必要定向测试。
- 不修改 MATCH、HOT_COMMENT、DISCUSSION、RANKING、PLAYER_RATING、unknown 卡片，不修改顶部筛选、返回顶部、Controller/Repository/domain/mock 数据、路由或后端。

要求：
- 连续 CONTENT 组成一个双列区段；遇到任何非 CONTENT 卡片即结束区段，让该卡片继续全宽显示，保持区段与全宽卡片的到达顺序。
- 两列应独立自然累积高度，形成错落布局；移除当前 `IntrinsicHeight` 等高行和无热评时预留的固定空白。奇数张 CONTENT 最后一张保持半列宽。
- 内容卡片按原型保留封面/中性缺图态、两行标题、可选热评、作者、日期、点赞和评论；无热评时整块收起，不伪造内容。
- 卡片点击、作者点击、稳定 Key、去重和 attribution/曝光链路不得回归。
- 不新增瀑布流依赖；复用现有 Design Token，在窄屏、长标题和 1.4 倍字体下无溢出。

完成标准：
- 高度不同的 CONTENT 卡片呈双列错落排列，无被强行拉等高或大块无意义空白。
- 混合 Feed 中非 CONTENT 卡片仍位于正确区段之间并保持全宽；奇数、缺图、无热评均安全。
- 其余卡片和 Feed 分页行为不变。

执行：
直接修改代码，只读取本任务相关文件。开发中不启动模拟器、不 build APK、不跑全量测试；完成后只运行 `flutter analyze`、`f04_home_feed_widget_test.dart`，并补充双列错落、奇数卡片及混合顺序的定向测试。

最终仅汇报：
- 修改文件
- 完成结果
- 验证结果
- 阻塞/剩余问题

成功标志：
Round 03 content masonry passed
