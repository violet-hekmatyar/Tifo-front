# F18 Backend V1 Flutter 第一版统一验收报告

## 1. 验收结论

不含通知、私信、IM、WebSocket、Push 的 Flutter 第一版已通过代码检查、静态分析、全量自动测试、Android Debug APK 构建和 Backend V1 关键链路 smoke。

当前版本可以进入 Pixel 8 人工验收。人工验收用于确认真机/模拟器上的布局、点击、返回、滚动、键盘、图片失败和 140% 字体表现，不替代已经通过的自动契约验证。

## 2. 发现并修复的问题

| 问题 | 影响 | 修复结果 |
|---|---|---|
| 生产目录保留 3 个已经被真实页面替代的历史 Placeholder 页面 | 容易误判为仍有未完成功能，且包含旧阶段文案 | 已删除登录完成、通用功能和个人中心历史 Placeholder；通信占位不在本次范围内 |
| F06 的 3 条旧详情测试仍假设阵容、排名、统计等 Tab 未实现 | F15 后真实数据源会初始化，旧测试出现 `pumpAndSettle` 超时并检查过时文案 | 已删除重复且失真的旧断言；F13、F14、F15 的现行完整测试继续覆盖球队、球员和比赛详情 |
| 缺少一条 F18 统一真实后端 smoke | 分阶段测试通过，但最终验收证据分散 | 已新增 F18 smoke，一次覆盖 Feed、Search、内容、足球数据、三类详情、用户中心和推荐行为 |
| F18 smoke 初版错误读取 `MatchOverviewV1.match.id` | 新验收测试无法通过静态分析 | 已按真实模型改为 `matchId` |
| Codex Windows 子进程中的 Java NIO loopback 失败 | Gradle 无法启动，Debug APK 首次构建被环境阻断 | 确认为临时目录映射导致的宿主环境问题；仅为构建进程使用短 TEMP 后成功，无工程配置改动 |

## 3. F09–F17 功能闭环检查

| 范围 | 验收结果 | 关键证据 |
|---|---|---|
| F09 公共契约 | 通过 | Result/PageResult、Long、nullable、空数组、ISO 时间、相对媒体 URL、unknown enum/cardType 均有公共处理与测试 |
| F10 Feed 与 Search | 通过 | 六类 Feed renderer；unknown 安全降级；四类搜索、筛选、分页、错误/空态和详情跳转完整 |
| F11 ARTICLE | 通过 | ARTICLE 创建、编辑、blocks、封面、关联选择、详情渲染及退出确认均有实现和测试 |
| F12 赛季、阶段与榜单 | 通过 | league → season → stage 上下文、积分榜/球员榜/球队榜、分页与跳转完整 |
| F13 球队详情 | 通过 | overview、players、stats、honors、matches、contents 使用真实接口；旧“后端未提供”已消失 |
| F14 球员详情 | 通过 | overview、stats、teams、career、matches、contents 使用真实接口；nullable 国家队和退役状态安全 |
| F15 比赛详情与评分 | 通过 | overview、lineups、当前排名、stats、player-stats、ratings 及评分提交/撤销完整；CURRENT_STANDING 只显示“当前排名” |
| F16 用户中心 | 通过 | 我的点赞、头像上传绑定、关系状态、关注确认和公开列表 403 隐私态完整 |
| F17 推荐行为 | 通过 | EXPOSE/CLICK/DETAIL/LIKE/FAVORITE/COMMENT、跨路由 attribution、可见曝光、批量去重和有限重试完整 |

代码搜索未发现上述可达业务路径存在生产 mock、假按钮、“后端未提供”旧文案或新阶段占位。消息相关不可用页面属于明确排除的通信范围。

## 4. 自动验证结果

| 检查 | 结果 | 说明 |
|---|---|---|
| `flutter analyze` | 通过 | `No issues found` |
| `flutter test` | 通过 | 175 项全部通过 |
| Android Debug APK | 通过 | `apps/mobile/build/app/outputs/flutter-apk/app-debug.apk`，约 179.2 MiB |
| APK SHA-256 | 通过 | `9A3EC5DB221DCA022EDFDA20DA9BE2660F9E6FB29DE30BADD43205268B95C300` |
| Backend V1 F18 smoke | 通过 | 真实 Spring Boot 环境，1 项统一 smoke 全部通过 |

F18 smoke 覆盖：六类推荐 Feed、TEAM/PLAYER/MATCH/CONTENT 搜索、内容详情、联赛/赛季/阶段/积分榜、球队六类详情数据、球员六类详情数据、比赛概览/阵容/排名/统计/评分、登录后用户摘要，以及推荐行为 saved/duplicated 幂等解析。

## 5. 风险与边界

- 通知、私信、IM、WebSocket 和 Push 按范围排除，未作为验收缺口。
- 自动测试不能替代 Android 端视觉和手势检查；Pixel 8、键盘遮挡、图片失败和 140% 字体仍需按人工清单确认。
- APK 构建需在当前 Codex Windows 子进程内使用短 TEMP；这是宿主执行环境限制，不是仓库构建配置问题。普通 Android Studio 或外部终端不应需要工程内规避。

## 6. 最终状态

自动验收已通过，可以进入人工验收；当前无代码级或 Backend V1 契约级阻塞。

**F18 Backend V1 Flutter first version acceptance passed**
