# 南看台 Flutter 移动端

## F07 用户中心与关注

“我的”使用真实 `/api/app/users/me/summary`，支持昵称/简介编辑，并提供我的发布、收藏、评论、关注/粉丝和关注球队/球员入口。收藏可直接取消、本人评论可直接删除，失败时恢复列表。公开用户主页支持真实关注/取消关注，按钮防重复、乐观更新且失败回滚；Feed 与内容详情作者均可进入 `/users/:userId`。列表支持刷新、分页、空状态、错误重试和追加重试。

后端没有“我的点赞”查询，也没有消息/通知、未读或已读接口；客户端保留正式页面说明缺口，不拼装本地记录或虚构消息。真实 F07 smoke 使用两个唯一测试账号验证我的发布、用户关注、关注/粉丝列表和 following Feed 联动，不重置数据库。

## F06 路由、排序与分页修正

Football 详情位于 root Navigator；数据页、首页 MATCH、球队赛程和内容 MATCH 都使用绝对 `/matches/:matchId` push。排序集中在 `sortMatchesForDisplay`，分页 Footer 明确显示加载、重试和到底。比赛卡球队区、比赛头部、首页关注球队快捷入口可进入球队详情；球员仅在事件或内容关系提供真实 playerId 时开放。

## F06 足球数据与详情

数据 Tab 使用真实联赛、重要比赛、关注球队比赛和按联赛赛程，支持日期分组、下拉刷新与分页。真实详情路由为 `/teams/:teamId`、`/players/:playerId`、`/matches/:matchId`；首页 MATCH、内容关系和详情内实体入口均进入对应页面。数据沿 `Page → Controller → FootballRepository → FootballApi → ApiClient` 流动。

球队、球员和比赛 Logo/头像均复用统一 URL Resolver 与稳定占位。后端无积分榜、球队阵容列表、球员统计/比赛记录、比赛阵容/统计接口时显示明确空状态，不用球队赛程猜球员出场，也不计算排名。

## F05 内容与互动

真实详情支持 POST/ARTICLE、多图、点赞收藏、hot/latest 评论、回复与本人删除。发布使用 `image_picker 1.2.3` 仅从相册选图，上传 `CONTENT_IMAGE` 后提交 `mediaFileIds`。限制为标题 255、正文 2000、图片 9 张/10MB、评论 1000 字。

项目名 `tifo`，Android applicationId 与 iOS bundle identifier 均为 `com.southstand.tifo`。F03 使用 Dio、Riverpod、go_router 与 `flutter_secure_storage`，完成注册、登录、登录态恢复、首次偏好选择和本地退出。后端当前只有 Access Token，没有 Refresh Token；不保存密码或完整响应。

## 本机真实后端

在前端仓库根目录运行：

```powershell
powershell -NoProfile -ExecutionPolicy Bypass -File .\scripts\windows\ensure-local-backend-f03.ps1
powershell -NoProfile -ExecutionPolicy Bypass -File .\scripts\windows\status-local-backend-f03.ps1
```

Android 模拟器通过 `10.0.2.2` 访问 Windows 宿主机：

```powershell
flutter run -d Pixel_8_API_36 `
  --dart-define=APP_ENV=development `
  --dart-define=API_BASE_URL=http://10.0.2.2:8080
```

登录页、注册页与 onboarding 页面使用真实数据；完成后进入首页、数据、消息、我的四栏正式主框架。首页通过真实 Feed 接口展示推荐、资讯、关注和关注球队筛选；数据 Tab 已由 F06 接入真实 football 数据，消息和我的完整功能留待 F07。

## F03.1 设计系统与占位

视觉 Token 位于 `lib/shared/design_system`，共享表单、按钮、状态、选择卡片和实体占位位于 `lib/shared/widgets`；唯一视觉规则见 `docs/13_CLIENT_UI_VISUAL_BASELINE.md`。球队 Logo 与球员头像优先使用后端 URL，空值或失败时按稳定实体 ID/名称显示一致的本地占位，不下载随机网络图片。

人工预览需启动本地后端和 Pixel 8 模拟器，再使用下方 `flutter run` 命令；逐页检查登录、注册、三步首次设置、错误重试和临时完成页。自动测试与 APK 构建不能替代人工视觉观察。

## 测试与验收

```powershell
flutter test
powershell -NoProfile -ExecutionPolicy Bypass -File ..\..\scripts\windows\check-mobile-f06.ps1
powershell -NoProfile -ExecutionPolicy Bypass -File ..\..\scripts\windows\smoke-mobile-football-f06.ps1
```

默认 `flutter test` 只运行 Mock/Widget 测试；真实 smoke 使用独立 `test_local_backend`，会创建唯一命名测试用户且不重置数据库。Windows 不执行 iOS build。

## F04 首页

Feed 数据经 `FeedApi → FeedRepository → FeedController → HomeFeedPage` 流动，页面不访问 Dio 或解析 JSON。当前真实实现识别 `CONTENT`、`MATCH`；内容详情与发布已由 F05 接通，比赛详情由 F06 接通，搜索仍提供清晰占位。

首页不再完全交错渲染 MATCH/CONTENT。`FeedDisplaySections` 保留控制器原始分页列表，按稳定 contentId/matchId/cardId 去重后展示为全宽比赛区、双列内容区、Unknown 兼容区。发布入口使用 push，成功后 replacement 进入详情；详情返回通过一次性信号刷新当前 tab/teamId，不向首页硬插帖子。

F06 收口后，关注球队栏只有两种单一交互：“全部”清除球队筛选，真实球队整卡直接 push `/teams/:teamId`。卡片不再叠加独立箭头；无效 teamId 禁用跳转，语义标签为“查看 <球队名称> 详情”。push/pop 不销毁首页，因此 Feed tab、筛选、列表和滚动位置继续保留。

联网文字核验不属于 App 数据源，也没有写入生产 Dart；详情页继续原样展示 API。审计只产生报告与 corrections，本轮不处理视觉/媒体资源、不改后端和数据库。
