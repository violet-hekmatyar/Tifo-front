# P3-M0 基线与门禁记录

日期：2026-09-18

## 结论

P3-M0 已通过，可以进入 P3-M1。基线期间未修改后端、数据库、SQL、seed、API 契约或 P2 生产代码；仅修正了一个沿用旧详情 UI 查找方式的路由测试断言。

## 定向测试与分析

football 数据中心、路由、球队详情、球员详情、比赛详情、评分及排序定向测试共 81 项，全部通过。

```text
flutter test test/features/football/f06_football_widget_test.dart test/features/football/f06_app_router_test.dart test/features/football/football_controller_test.dart test/features/football/f12_football_rankings_controller_test.dart test/features/football/f12_football_rankings_api_test.dart test/features/football/f12_football_rankings_widget_test.dart test/features/football/f13_team_detail_api_test.dart test/features/football/f13_team_detail_controller_test.dart test/features/football/f13_team_detail_responsive_widget_test.dart test/features/football/f13_team_detail_widget_test.dart test/features/football/f13_team_detail_sections_widget_test.dart test/features/football/f14_player_detail_api_test.dart test/features/football/f14_player_detail_controller_test.dart test/features/football/f14_player_detail_responsive_widget_test.dart test/features/football/f14_player_detail_widget_test.dart test/features/football/f14_player_detail_sections_widget_test.dart test/features/football/f15_match_detail_api_test.dart test/features/football/f15_match_detail_controller_test.dart test/features/football/f15_match_detail_responsive_widget_test.dart test/features/football/f15_match_detail_widget_test.dart test/features/football/f15_match_detail_sections_widget_test.dart test/features/football/f15_match_rating_controller_test.dart test/features/football/match_display_sort_test.dart
```

`flutter analyze`：`No issues found!`

路由测试修正：

- 载入后的比赛详情使用稳定的 `match_header` Key；
- 事件球员入口使用稳定的 `event_player_1` Key；
- 未修改路由或生产页面逻辑。

## 真实 API smoke

使用当前后端和开发数据库，只读请求均为 HTTP 200、业务 `code=0`：

- 联赛：11 条；
- 重要比赛：66 条，代表比赛 `50001`；
- 比赛详情：`/api/app/football/matches/50001`；
- 球队详情：球队 `30001`；
- 球员详情：球员 `14000000000000067`。

## APK 门禁

- APK：`apps/mobile/build/app/outputs/flutter-apk/app-debug.apk`
- 时间：2026-09-18 12:53:30
- 大小：187,904,767 bytes
- SHA-256：`C12FFC555AECF685AA1DC358F7635BBD2242EE02250911AA6CF0044C33CEC1FE`
- 设备：`emulator-5554`，`1080x2400`，`420dpi`；已通过 `adb reverse tcp:8080 tcp:8080` 启动并截图。

基线截图：[P3_M0_BASELINE.png](./P3_M0_BASELINE.png)

## M1 预登记发现

数据中心当前真实比赛能显示，但部分球队 logo URL（例如 `/uploads/team/barcelona.png`）返回 `application/json` 而不是图片，客户端正确回退为首字占位。该问题登记到 P3-M1 媒体契约/资源验收，不在 M0 擅自伪造或替换队徽。

