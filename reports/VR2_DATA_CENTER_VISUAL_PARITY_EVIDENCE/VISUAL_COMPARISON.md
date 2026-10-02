# VR2-R2 原型与实机视觉对照

实机截图来自同一新 APK：`70FAA609B3330C1D6FE23936BEC0185BAC302F3894FF3085F9CF70FF4FC04F7F`。每张 `comparison_*.png` 均为实际原型与对应实机截图的并排合成图；状态栏差异不计入应用内容区判断。

| 目标 | 原型 | 实机证据 | 并排对照 | 关键断言 |
|---|---|---|---|---|
| 关注与球队筛选 | `C:\Users\hekmatyar\Desktop\足球APP\数据-比赛-重要.png` | `01_important_matches.png` | `comparison_01.png` | 已登录“关注”选中；关注球队条显示阿森纳、Arsenal、Barcelona、Liverpool，可切换“全部”及球队源。 |
| 联赛赛程 | `C:\Users\hekmatyar\Desktop\足球APP\数据-西甲-赛程.png` | `02_league_schedule.png` | `comparison_02.png` | 选择非默认联赛后，控制行从完整“赛季”入口开始，随后为赛程/积分榜/球员榜/球队榜；无常驻阶段按钮。 |
| 积分榜 | `C:\Users\hekmatyar\Desktop\足球APP\数据-西甲-积分榜.png` | `03_league_standings.png` | `comparison_03.png` | 同一联赛上下文下，控制行仍为“赛季＋四栏目”，表头和行内“积分”列在截图右侧可见。 |
| 球队榜 | `C:\Users\hekmatyar\Desktop\足球APP\数据-西甲-球队榜.png` | `04_league_team_ranking.png` | `comparison_04.png` | 10 队榜单来自真实 API，首屏连续填充；控制行未显示独立阶段按钮。 |
| 球员榜 | `C:\Users\hekmatyar\Desktop\足球APP\数据-西甲-球员榜.png` | `05_league_player_ranking.png` | `comparison_05.png` | 10 条首屏分页记录可见；球员头像使用独立球员图片回退，不复用球队队徽。 |
| 360dp | 适配门槛 | `06_width_360.png` | — | 360dp 截图保留数据页、榜单内容和底部导航，未出现横向溢出错误。 |
| 140% 字体 | 适配门槛 | `07_font_140.png` | — | 放大字体后仍可读取数据页主要层级，榜单右侧关键数值未被裁切。 |
| 底部导航 | VR1 已通过导航 | `08_bottom_navigation.png` | — | 数据选中态及底部导航安全区保持。 |
| 淘汰树入口 | 原型范围外回归 | `09_knockout_entry.png` | — | “更多数据”菜单打开并显示现有淘汰树入口。 |
| 淘汰树占位 | 原型范围外回归 | `10_knockout_placeholder.png` | — | 进入现有“淘汰树正在开发”占位页，未新增真实淘汰树数据。 |

## 证据说明

- 对照图使用的 5 张原型文件均来自 `C:\Users\hekmatyar\Desktop\足球APP`，不是旧实机截图拼接。
- 实机截图均在 2026-09-18 22:02:13 构建的新 APK 上重新安装后采集。
- 榜单 API 使用 `leagueId=12000000000000004`、`seasonId=20000000000000008`：积分榜 10 队、球队榜 10 队、球员榜总计 90 名。
- 阶段入口仅在点击“赛季”后出现的底部层中提供；`06_width_360.png` 与 `07_font_140.png` 均显示完整赛季入口和真实内容。
- 该文件记录证据和断言，VR2 最终是否通过仍由 Plan 模型复验决定。
