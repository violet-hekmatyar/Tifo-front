# P2-M2 推荐内容卡与资讯版式验收记录

日期：2026-09-18

## 实现范围

- 推荐和关注频道继续使用 `ContentCardLayout.grid`，保留连续内容双列、独立列高度和后端到达顺序。
- 资讯频道使用同一 `ContentFeedCard` 数据模型的 `ContentCardLayout.news`，渲染封面在左、标题/摘要/作者/日期在右的单列紧凑卡。
- 摘要仅在有值时显示，最多两行；无摘要自然收起；缺封面沿用统一足球图标降级；热评只在原有字段返回时显示。
- 未修改后端、数据库、Feed 排序、分页、稳定键、推荐归因、路由或 P1 媒体资源。

## 定向验证

- 通过：`f04_home_feed_widget_test.dart`
- 通过：`f18_2_feed_stability_test.dart`
- 通过：`feed_display_sections_test.dart`
- 新增资讯单列、长摘要、无摘要测试；既有测试覆盖推荐双列、长标题、无封面、热评有/无、140% 字体、刷新锚点和后端顺序。

## Android 验收

- 使用脱离 Codex 子进程树的 Task Scheduler 构建入口连续构建两次，任务返回码为 0。
- APK：`D:\Football-APP-Front\apps\mobile\build\app\outputs\flutter-apk\app-debug.apk`
- 最后修改时间：`2026-09-18 10:29:45 +08:00`
- 文件大小：`187904767` bytes
- SHA-256：`4A5767001AC4A3286351730ACEFB476B2985FE665D1E1B9975FF09D36D58F077`
- `adb install -r`：成功；`adb reverse tcp:8080 tcp:8080`：成功。
- 推荐页截图：[01_recommendation.png](01_recommendation.png)
- 资讯页截图：[02_news.png](02_news.png)

## 构建环境处理

- Codex 内直接执行仍稳定失败于 Java NIO loopback；未修改 Gradle、JDK 或业务依赖。
- 新增 [build-mobile-debug-detached.ps1](../../scripts/windows/build-mobile-debug-detached.ps1)，通过 Windows Task Scheduler 独立启动现有构建脚本，完成后自动清理临时任务。

结论：P2-M2 完成，可以进入 P2-M3。
