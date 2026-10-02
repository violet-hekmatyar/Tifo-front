# P3-M1 数据中心执行记录

日期：2026-09-18

## 结论

P3-M1 通过，进入 P3-M2。

数据中心已使用现有真实 API 展示赛程、联赛筛选和比赛字段；加载、刷新、空态、错误重试、窄屏和大字体相关定向测试通过。缺少可访问图片时保留稳定的球队首字母降级，不伪造队徽或扩展后端契约。

## 验证结果

- 足球与媒体定向回归：83 个测试全部通过。
- `flutter analyze`：`No issues found!`。
- 数据中心 Android 截图：[`P3_M1_DATA_WITH_AUTH_MEDIA.png`](P3_M1_DATA_WITH_AUTH_MEDIA.png)。
- 新鲜 APK：`D:\Football-APP-Front\apps\mobile\build\app\outputs\flutter-apk\app-debug.apk`。
- APK 时间：2026-09-18 13:06:40。
- APK 大小：187,904,767 bytes。
- APK SHA-256：`C10DA5E4D128B51ADAF02D73078A82075BEE1C0805C31C506CB0AF5A4E5BC438`。

## 客户端最小修复

- `AppEntityAvatar` 与 `AppContentImage` 在存在登录令牌时为图片请求附加现有 `requestHeadersProvider` 返回的 Authorization header。
- 无 `ProviderScope` 的纯 Widget 测试仍保持可渲染；图片请求失败继续使用既有 fallback。
- 未修改 Spring Boot、数据库、SQL、seed、接口路径或 Feed/P2 页面逻辑。

## 资源残项

当前匿名模拟器访问 `/uploads/team/barcelona.png`、`/uploads/team/bayern.png` 返回 `401 + application/json`，不是图片。该资源权限问题属于现有后端媒体契约边界；客户端已正确降级为首字母，未将 JSON 当图片展示，也未伪造或替换队徽。登录态验证留在最终 Android 验收中复核。

