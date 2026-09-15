# 原型对齐第 04 轮执行 Prompt

任务：
参照 `C:\Users\hekmatyar\Desktop\足球APP\首页.png`，完成首页 MATCH 全宽卡片的视觉和状态对齐。

范围：
- 只修改 `match_card.dart` 及 MATCH 必要的定向 Widget 测试。
- 不修改 CONTENT、HOT_COMMENT、DISCUSSION、RANKING、PLAYER_RATING、unknown 卡片，不修改瀑布流、Controller/Repository/domain/mock 数据、路由或后端。

要求：
- 使用现有 Design Token，将联赛/状态、主客队、队徽、比分或开赛时间、可选事件摘要整理为原型中的清晰全宽比赛卡片层级。
- SCHEDULED 只显示开赛时间，不伪造 0:0；LIVE、FINISHED 使用已有比分和中文状态。比分缺失、时间为空、队徽缺失、长联赛名和长队名均安全降级。
- `eventSummary` 为空时整块收起；非空时最多两行并避免撑坏布局。
- 保留整卡点击、稳定 Key、推荐 attribution/曝光与点击链路，不新增按钮或假数据。
- 延续 03C 响应式修复，在 412px、1.4 倍字体下比分/时间、队徽和队名不溢出；不得关闭字体缩放或裁掉关键信息。

完成标准：
- MATCH 卡片与首页原型的结构、圆角、绿色状态和信息层级一致。
- 未开始、进行中、已结束及 nullable/长文本状态均无异常。
- 混合 Feed 中仍保持全宽，CONTENT 瀑布流和其他卡片不回归。

执行：
直接修改代码，只读取本任务相关文件。开发中不启动模拟器、不 build APK、不跑全量测试；完成后只运行 `flutter analyze` 和 `f04_home_feed_widget_test.dart`，补充本轮必要的 MATCH 状态与大字体断言。

最终仅汇报：
- 修改文件
- 完成结果
- 验证结果
- 阻塞/剩余问题

成功标志：
Round 04 home match card passed
