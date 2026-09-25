# P2-M3 执行记录

日期：2026-09-18

## 结论

P2-M3 已完成，可以进入 P2-M4。比赛卡和专用卡已在真实 Feed 混排中显示，未修改后端、数据库、P1 数据或 Feed 排序。

## 变更范围

- `apps/mobile/lib/features/feed/presentation/widgets/match_card.dart`
  - 统一深绿色比赛事件区、状态胶囊、比分/时间层级和事件摘要区域；
  - 保留 LIVE、FINISHED、SCHEDULED、无比分、无事件摘要和原有点击路由。
- `apps/mobile/lib/features/feed/presentation/widgets/supplementary_feed_cards.dart`
  - 收紧热门评论、讨论、榜单和球员评分卡的信息层级；
  - 对空摘要、空榜单、空评分使用安全的紧凑降级展示。
- `apps/mobile/test/features/feed/f10_feed_card_renderer_test.dart`
  - 增加比赛比分/时间/事件摘要和专用卡缺省字段覆盖。

## 定向测试

以下命令通过：

```text
dart format test/features/feed/f10_feed_card_renderer_test.dart
flutter test test/features/feed/f10_feed_card_renderer_test.dart test/features/feed/f04_home_feed_widget_test.dart test/features/feed/feed_display_sections_test.dart test/features/recommendation/f17_feed_attribution_test.dart
```

结果：`All tests passed!`。测试输出中的 `Unsupported feed card type: POLL` 为既有未知类型安全降级日志，无测试失败。

## Android 验收

- APK：`apps/mobile/build/app/outputs/flutter-apk/app-debug.apk`
- APK 时间：2026-09-18 11:26:32
- APK 大小：187,904,767 bytes
- SHA-256：`C12FFC555AECF685AA1DC358F7635BBD2242EE02250911AA6CF0044C33CEC1F`
- 已使用当前 APK 安装到 Android 设备，并通过 `adb reverse tcp:8080 tcp:8080` 连接当前后端。
- 混排画面覆盖：比赛卡、讨论、热门评论、排名、球员评分，以及未开始/进行中状态和比赛事件摘要。

截图证据：

- [首页混排顶部](./01_mixed_top.png)
- [讨论卡](./02_discussion.png)
- [热门评论卡](./03_hot_comment.png)
- [比赛与排名混排](./04_matches_ranking.png)
- [排名卡](./05_ranking.png)
- [球员评分卡](./06_player_rating.png)
- [未开始/进行中比赛与事件](./07_scheduled_live_events.png)

## 保护项

- 未修改后端、数据库、API 契约、P1 数据和 Feed 排序；
- 未处理历史比赛 `50004`；
- 未提前执行 P2-M4 的全阶段联调、`flutter analyze` 或最终多尺寸验收。

