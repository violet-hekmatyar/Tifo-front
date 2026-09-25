# P2-M4 阶段验收记录

日期：2026-09-18

## 结论

P2-M4 已完成，P2 阶段全部完成。当前源码 APK 已重新构建、安装并使用真实后端响应完成 Android 验收；未修改后端、数据库、P1 数据、API 契约或 P3/P4 范围。

## 定向验证

### Flutter

通过的 M4 定向测试：

```text
flutter test test/features/feed/f04_home_feed_widget_test.dart test/features/feed/f06_team_entry_widget_test.dart test/features/feed/f10_feed_card_renderer_test.dart test/features/feed/f18_2_feed_stability_test.dart test/features/feed/feed_display_sections_test.dart test/features/feed/feed_controller_test.dart test/features/recommendation/f17_feed_attribution_test.dart
```

结果：`All tests passed!`，共 39 个用例。计划中的 `f06_team_entry_widget_test.dart` 实际位于 `test/features/feed/`，已按仓库真实路径执行。

`flutter analyze` 结果：`No issues found!`

### 真实 API smoke

使用当前运行中的 P1 后端和开发数据库，只读验证均为 HTTP 200、业务 code 0：

- `GET /api/app/feed?tab=recommend&pageNum=1&pageSize=20`
- `GET /api/app/feed?tab=news&pageNum=1&pageSize=20`
- `GET /api/app/feed?tab=following&pageNum=1&pageSize=20`
- `GET /api/app/feed?tab=team&pageNum=1&pageSize=20&teamId=13000000000000011`，返回 14 条记录；
- `GET /api/app/football/teams/13000000000000011/overview`
- `GET /api/app/football/teams/13000000000000011/contents?pageNum=1&pageSize=20`，返回 8 条记录。

### APK

- 路径：`apps/mobile/build/app/outputs/flutter-apk/app-debug.apk`
- 构建时间：2026-09-18 11:34:08
- 大小：187,904,767 bytes
- SHA-256：`C12FFC555AECF685AA1DC358F7635BBD2242EE02250911AA6CF0044C33CEC1FE`
- 设备：`emulator-5554`，Pixel 8 主尺寸，物理 `1080x2400`，`420dpi`，逻辑宽度约 `412dp`；APK 通过 `adb reverse tcp:8080 tcp:8080` 访问本机后端。

## Android 截图索引

- [推荐顶部与首屏双列](./01_recommend_top.png)
- [推荐混排 1：讨论及内容卡](./02_recommend_mixed_1.png)
- [推荐混排 2：内容卡及热门评论](./02_recommend_mixed_2.png)
- [推荐混排 3：比赛卡及赛事状态](./02_recommend_mixed_3.png)
- [资讯首屏单列](./03_news_top.png)
- [球队筛选后的推荐首页](./06_team_filter_recommend.png)
- [360dp 宽度](./07_width_360dp.png)
- [140% 字体比例](./08_font_140.png)

截图确认：推荐内容封面、作者头像、球队标识、比赛卡、资讯单列、球队筛选和专用卡均可见；360dp 与 140% 字体下无溢出、遮挡或底栏覆盖。设备显示参数已恢复为原始值。

## 交互 smoke

已在新 APK 上执行搜索打开/返回、发布打开/返回、推荐/资讯切换、球队选择/清除、底部数据页切换并返回首页、Feed 上滑加载与下拉刷新、内容点击进入详情并返回；未出现 adb、进程或渲染异常。

## 保护项与未处理项

- 未重跑或修改 seed，未修改 Feed 排序；
- 未处理历史比赛 `50004`；
- 未运行后端全量测试、数据库 validator、全仓回归或 P3/P4 页面截图；
- M4 未新增业务代码，当前生产改动均属于已完成的 P2-M1～M3 客户端范围。
