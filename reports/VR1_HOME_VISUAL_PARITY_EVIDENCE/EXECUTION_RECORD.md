# VR1 首页视觉复刻执行记录

状态：**待 Plan 模型验收**

日期：2026-09-18

## 本次修改

仅修改首页 Feed、首页空态和底部导航视觉相关客户端代码：

- `apps/mobile/lib/features/feed/presentation/pages/home_feed_page.dart`
- `apps/mobile/lib/features/feed/presentation/widgets/feed_filter_bar.dart`
- `apps/mobile/lib/features/feed/presentation/widgets/content_card.dart`
- `apps/mobile/lib/features/feed/presentation/widgets/match_card.dart`
- `apps/mobile/lib/features/feed/presentation/widgets/supplementary_feed_cards.dart`
- `apps/mobile/lib/features/main_shell/presentation/main_shell_page.dart`
- `apps/mobile/lib/app/theme/app_theme.dart`
- `apps/mobile/test/features/feed/f04_home_feed_widget_test.dart`

工作区中原有的 P1–P3、P2 业务改动未重置；本阶段未修改后端、数据库、Feed Controller、DTO、Repository、领域模型、路由、鉴权、网络层或其他功能页面。

## 完成内容

- 搜索和发布入口保持一行胶囊布局。
- 频道与球队入口合并为单行横向导航，移除首页使用的大号“全部”球队卡；保留球队筛选、清除和管理球队入口。
- 推荐流将现有六类 Feed 卡片按后端去重后的到达顺序放入确定性双列瀑布流。
- 内容、比赛、热评、讨论、榜单、评分卡压缩半宽展示的内边距、间距、圆角和次要信息密度。
- 资讯保留单列横向卡、摘要、作者、时间和后端顺序。
- 关注空态使用生产 Widget 绘制的本地盾牌星形插画、“暂无关注球队”和“快去关注” CTA，按钮继续进入现有搜索路由。
- 底栏保留四个分支和状态恢复，仅调整为白色悬浮胶囊、透明选中指示块、绿色选中图标/文字。
- 首页内容边距收敛为约 10dp、列间距约 8dp；日期改为短格式以降低 140% 字体断行风险。

## 验证结果

- 定向 Flutter 测试：39 项全部通过。
- `flutter analyze`：`No issues found!`。
- API 只读 smoke：
  - `recommend`：HTTP 200，`code=0`，10 条。
  - `news`：HTTP 200，`code=0`，10 条。
  - `following`：HTTP 200，`code=0`。
  - 有效 `teamId=13000000000000001`：HTTP 200，`code=0`，10 条。
  - `cover-stadium.png`、`cover-training.png`、`user-demo.png`：HTTP 200，`image/png`。
- APK：`apps/mobile/build/app/outputs/flutter-apk/app-debug.apk`。
- APK 大小：187,904,767 bytes。
- APK SHA-256：`9F3BEE15B1E44D8A129B4B00CAE52163835B4252D53C907ED9FDED780B7188D`。
- Android 设备：`emulator-5554`，最终恢复为 1080 × 2400、420dpi、字体比例 1.0。

## 截图与对照

- 截图目录：本目录。
- 逐项对照：[VISUAL_COMPARISON.md](./VISUAL_COMPARISON.md)。
- 原型：首页 `C:\Users\hekmatyar\Desktop\足球APP\首页.png`；关注空态 `C:\Users\hekmatyar\Desktop\足球APP\暂无关注球队.png`。

## 未通过项 / 留给验收模型的关注项

- 当前关注球队返回的部分图片资源仍在客户端显示为首字母降级，原因是既有资源格式/可解码性问题；本阶段没有越界修改媒体接口、后端或数据库。请 Plan 模型重点判断这一项是否需要单独媒体补修。
- 部分历史演示资讯本身没有封面，继续显示既有中性占位；没有为截图硬编码业务数据。

## 结论

已完成 VR1 首页客户端实现、定向验证和截图证据整理，当前结论为：**已提交 Plan 模型验收**。不自行宣布 VR1 视觉通过，也不进入下一阶段。
