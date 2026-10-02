# VR2-R2 数据中心控制栏补修执行记录

日期：2026-09-18  
状态：**已执行，已提交 Plan 模型复验**

## 本轮范围

本轮只执行 VR2-R2，处理 VR2-B02-R，不进入旗舰比赛详情阶段。

- 主控制行只显示“赛季＋赛程/积分榜/球员榜/球队榜”，不再常驻独立“阶段”按钮。
- 阶段选择并入点击“赛季”后的“选择赛季与阶段”底部层；切换赛季后仍刷新可用阶段并保持栏目上下文。
- 使用同一新 APK 重新安装并采集 10 张 Android 截图，生成 5 张真实原型/实机并排对照图。

未修改后端、数据库、API 契约、Feed 排序、首页布局、比赛详情、淘汰树业务数据或 M2 的数据脚本；B01、B03～B06 仅沿用已验证结果。

## 定向验证

执行 VR2 计划规定的定向测试命令，结果：**37 项全部通过**。

```powershell
flutter test test/features/football/football_controller_test.dart test/features/football/match_display_sort_test.dart test/features/football/f06_app_router_test.dart test/features/football/f06_football_widget_test.dart test/features/football/f12_football_rankings_api_test.dart test/features/football/f12_football_rankings_controller_test.dart test/features/football/f12_football_rankings_widget_test.dart
```

- `flutter analyze`：通过，`No issues found!`
- `git diff --check`：通过；仅有既有 CRLF 转换提示，无 whitespace 错误。
- 新增覆盖：主控制行移除阶段按钮、赛季入口与四栏目顺序、赛季底部层包含阶段选项。

## API smoke

真实后端 `http://localhost:8080` 返回 HTTP 200、`code=0`：

| 接口 | 结果 |
|---|---|
| `/api/app/football/leagues` | 11 个联赛 |
| `/api/app/football/matches/important?pageNum=1&pageSize=10` | 10 条 |
| `/api/app/football/matches?pageNum=1&pageSize=10` | 10 条 |
| `/api/app/football/leagues/12000000000000004/seasons` | 2 个赛季 |
| `/api/app/football/leagues/12000000000000004/seasons/20000000000000008/stages` | HTTP 200、code=0 |
| `/api/app/football/standings?leagueId=12000000000000004&seasonId=20000000000000008` | 10 队 |
| `/api/app/football/team-ranks?...&pageSize=100` | 10 队 |
| `/api/app/football/player-ranks?...&pageSize=100` | 90 名球员 |

Android 使用已登录会话验证了关注球队条；本轮未通过匿名接口伪造关注数据。

## APK

- 路径：`apps/mobile/build/app/outputs/flutter-apk/app-debug.apk`
- 构建次数：2 次，均成功
- 大小：187,905,093 bytes
- 修改时间：2026-09-18 22:02:13
- SHA-256：`70FAA609B3330C1D6FE23936BEC0185BAC302F3894FF3085F9CF70FF4FC04F7F`
- 已安装到 `emulator-5554`，本轮截图均来自该 APK 和真实 API；构建脚本生成 APK 后另行完成安装。

## 截图证据

本目录包含同一新 APK 的 10 张 VR2-R2 截图：

1. `01_important_matches.png`：已登录“关注”状态及关注球队筛选条
2. `02_league_schedule.png`：非默认联赛赛程
3. `03_league_standings.png`：积分榜及可见积分末列
4. `04_league_team_ranking.png`：球队榜
5. `05_league_player_ranking.png`：球员榜及球员头像
6. `06_width_360.png`：360dp 宽度
7. `07_font_140.png`：140% 字体
8. `08_bottom_navigation.png`：底部导航
9. `09_knockout_entry.png`：淘汰树入口菜单
10. `10_knockout_placeholder.png`：淘汰树“正在开发”占位页

实际原型/实机对照图为 `comparison_01.png`～`comparison_05.png`，详见 [VISUAL_COMPARISON.md](./VISUAL_COMPARISON.md)。

本记录只提交 Plan 模型复验，不自行宣布 VR2 通过。
