# VR1-R1 首页补修执行记录

日期：2026-09-18

结论：**已提交 Plan 模型复验**。本记录不自行宣布视觉通过。

## 修改范围

- `apps/mobile/lib/features/feed/presentation/pages/home_feed_page.dart`
  - 收紧首页顶部、内容区、双列间距与卡片首屏密度；
  - 收紧关注空态插画、文字和 CTA 比例；
  - 保持原有路由、控制器、刷新、分页和底部导航。
- `apps/mobile/lib/features/feed/presentation/widgets/feed_filter_bar.dart`
  - 改为固定频道区、横向球队区和固定右侧管理菜单；
  - 队徽 SVG 不可解码时使用项目内中性队徽图片，不再显示首字母。
- `apps/mobile/lib/features/feed/presentation/widgets/content_card.dart`
  - 收紧双列封面比例和资讯卡高度。
- `apps/mobile/lib/features/feed/presentation/widgets/match_card.dart`
  - 增加紧凑比赛布局；未开始比赛日期/时间固定为两行，避免半宽卡逐字符断裂。
- `apps/mobile/lib/shared/widgets/app_content_image.dart`
  - 增加网络图片加载中和失败时的本地足球封面；兜底始终位于网络图片下层，避免首帧白块。
- `apps/mobile/pubspec.yaml`
  - 声明项目内 `neutral-football-cover.png` 和 `neutral-team-crest.png`。
- 定向测试：`f04_home_feed_widget_test.dart`、`f10_feed_card_renderer_test.dart` 更新了紧凑比赛断言，并新增 360dp 固定菜单和 186dp 两行时间几何断言。

## VR1-B01～B06 关闭情况

| 项目 | 执行结果 |
|---|---|
| B01 顶部密度 | 已按 360dp/Pixel 8 重新收紧，截图可见首屏信息量提升 |
| B02 媒体白块 | 已增加本地封面与加载层兜底；最终 140% 截图未出现大块纯白媒体区 |
| B03 球队导航/菜单 | 管理菜单固定右侧；队徽不可解码时显示中性队徽图片 |
| B04 半宽比赛卡 | 日期/时间显式两行；186dp 几何测试通过 |
| B05 关注空态 | 已用正式主题、正式 Shell、真实 APK 渲染；受控 fixture 仅将 following Feed 返回空列表并保留阿森纳导航，截图已采集 |
| B06 证据哈希 | 已记录完整 64 位 SHA-256，修正此前缺失末位问题 |

## 验证结果

- VR1 原定向测试命令：**41 项通过**（原 39 项加 2 项 R1 几何/菜单断言）。
- 关注空态受控证据测试：**1 项通过**；最终 APK 在模拟器中显示正式主题、球队导航、固定管理菜单、绿色空态 CTA 和底部导航。
- `flutter analyze`：**No issues found!**
- API smoke：`recommend`、`news`、`following`、球队详情均 HTTP 200 / `code=0`；封面和队徽 PNG 均 HTTP 200 / `image/png`。
- APK：`D:\Football-APP-Front\apps\mobile\build\app\outputs\flutter-apk\app-debug.apk`
- APK 大小：187,904,981 bytes
- APK SHA-256：`2D46C3968BB36663DF8C8A02BCD8E05839B216D19D5DDEA281F5E22A9F8D650E`
- 构建方式：`scripts/windows/build-mobile-debug-detached.ps1`，独立 Windows 进程完成构建。

## 最终 APK 证据

以下 9 张截图由真实 API APK 在 `emulator-5554` 采集：

- `01_recommend_top.png`
- `02_recommend_masonry_1.png`
- `03_recommend_masonry_2.png`
- `04_news.png`
- `05_following.png`
- `07_team_filter.png`
- `08_width_360.png`
- `09_font_140.png`
- `10_bottom_navigation.png`

`06_following_empty.png` 使用同一生产客户端代码构建的受控 fixture APK 采集：fixture 仅把临时验收账号的 `following` Feed 响应置为空，并返回一支阿森纳球队导航，其余请求转发至现有后端。fixture APK SHA-256 为 `E3C60F5EF91B2A532BD9C38DDA9B211CC07B7F4BA8E177F4583311C6DE5F0952`，真实 API APK 仍保留为 `2D46C3968BB36663DF8C8A02BCD8E05839B216D19D5DDEA281F5E22A9F8D650E`。临时账号为 `vr1_empty_20260918160159`，未修改既有 DEMO 账号或其数据。

证据目录：`D:\Football-APP-Front\reports\VR1_R1_HOME_VISUAL_PARITY_EVIDENCE`

## 保护项

本次未修改后端代码、Feed Controller、DTO、Repository、API 契约、排序逻辑或其他页面；仅按用户授权创建了临时验收账号，未修改既有 DEMO 数据。fixture 进程和临时测试文件均已移除。
