# 原型对齐第 04B 轮执行 Prompt

任务：
参照 `C:\Users\hekmatyar\Desktop\足球APP\首页.png`，统一完成首页 HOT_COMMENT、DISCUSSION、RANKING、PLAYER_RATING 四类全宽卡片的原型对齐。

范围：
- 主要修改 `supplementary_feed_cards.dart`，允许修改 `f10_feed_card_renderer_test.dart`、`f04_home_feed_widget_test.dart` 的必要定向测试。
- 不修改 CONTENT、MATCH、unknown 卡片、首页布局/筛选、Controller/Repository/domain/mock 数据、路由或后端。

要求：
- 四类卡片复用统一白色圆角全宽容器、绿色标题层级、边框/阴影和间距，同时保留各自清晰业务差异。
- HOT_COMMENT 展示评论正文、可空来源内容、作者及点赞/回复；DISCUSSION 展示标题、可空摘要/热评、关联标签、作者、时间及互动数，无值区域自然收起。
- RANKING 展示标题、可空联赛/赛季和最多 5 行排行；TEAM/PLAYER 使用对应队徽/头像和点击目标，空 items 显示明确空态，unknown rankingType 安全不可误跳。
- PLAYER_RATING 展示比赛双方、可空比分/联赛/时间、最多 3 名球员及可用评分、参与人数；无球员或评分为空时自然降级。
- 保留整卡/实体点击、稳定 Key、推荐 attribution/曝光链路；不增加虚假按钮或原型示例数据。
- 四类卡片在 412px、1.4 倍字体、长名称、缺头像/队徽及 nullable 数据下无溢出。

完成标准：
- 四类卡片的结构和视觉层级与首页原型一致，并在混合 Feed 中保持全宽及原有顺序。
- 空数组、缺失字段、长文本和未知排名类型不崩溃、不误导。
- CONTENT、MATCH、unknown 和瀑布流不回归。

执行：
直接修改代码，只读取本任务相关文件。不启动模拟器、不 build APK、不跑全量测试；完成后运行 `flutter analyze`、`f10_feed_card_renderer_test.dart` 和 `f04_home_feed_widget_test.dart`，补充四类卡片的 nullable/empty/大字体定向断言。

最终仅汇报：
- 修改文件
- 四类卡片完成结果
- 验证结果
- 阻塞/剩余问题

成功标志：
Round 04B home supplementary cards passed
