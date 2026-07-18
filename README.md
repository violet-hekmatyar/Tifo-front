# 南看台前端 / Tifo Frontend

## F06 人工阻塞修正

正式 `/matches/`、`/teams/`、`/players/` 已加入认证路由白名单并使用根 Navigator，详情覆盖主框架且返回来源页。比赛展示统一按“进行中 → 即将开始 → 已结束 → 其他状态”排序；未开始按时间升序，已结束按时间降序，前端不修改后端状态。真实数据不足时由 Mock 多页测试验证自动分页，不向生产环境写假比赛。

南看台前端包含面向普通用户的 Flutter 原生移动 App，以及仅供内部管理员使用的 Vue 3 + TypeScript 管理后台。当前不建设面向用户的 H5、PWA 或小程序。

- 当前阶段：F06（Flutter 足球数据中心与球队/球员/比赛详情）
- Flutter：`apps/mobile`
- Vue 管理后台：`apps/admin`
- 文档入口：[docs/00_DOCUMENT_MAP.md](docs/00_DOCUMENT_MAP.md)
- 完整结构树：[docs/04_FRONTEND_ARCHITECTURE.md](docs/04_FRONTEND_ARCHITECTURE.md)
- 本机环境与预览：[docs/12_LOCAL_DEVELOPMENT_ENVIRONMENT.md](docs/12_LOCAL_DEVELOPMENT_ENVIRONMENT.md)

## 日常运行

```powershell
cd D:\Football-APP-Front\apps\mobile
flutter devices
flutter run -d <android-device-id>

cd D:\Football-APP-Front\apps\admin
npm ci
npm run dev
```

## F03 本地后端与客户端预览

```powershell
powershell -NoProfile -ExecutionPolicy Bypass -File .\scripts\windows\status-local-backend-f03.ps1
cd apps\mobile
flutter run -d Pixel_8_API_36 `
  --dart-define=APP_ENV=development `
  --dart-define=API_BASE_URL=http://10.0.2.2:8080
```

F03 已为 Flutter 接入本机真实后端的注册、登录、Access Token 安全存储、冷启动恢复、Bearer 注入、首次偏好选择和本地退出。F04 已将认证完成入口替换为正式四栏主框架，并通过真实 Feed 接口提供首页混合卡片流。Vue 管理后台登录尚未开始，留待 F08。

F03.1 建立的 Design Token、共享组件和稳定图片占位继续作为视觉基础。F04/F05 已接通首页 Feed、内容发布与互动。F06 已将数据 Tab 替换为真实联赛/赛程页，并接通 `/teams/:teamId`、`/players/:playerId`、`/matches/:matchId`。搜索、消息和我的完整业务仍是明确占位。

后端状态管理入口为 `ensure-local-backend-f03.ps1`、`status-local-backend-f03.ps1` 和 `stop-local-backend-f03.ps1`。F06 移动端检查、真实 football smoke 与完整验收分别运行 `check-mobile-f06.ps1`、`smoke-mobile-football-f06.ps1` 和 `check-f06.ps1`。

F05 人工复验修正后，发布成功只替换发布页，详情返回原首页并触发一次真实 Feed 刷新。首页展示按“连续比赛区 → 双列内容区 → 兼容区”分组；这只改变跨类型展示顺序，同类型仍保持后端与分页到达顺序，不修改接口或推荐结果。

F06 只展示后端真实字段。当前后端没有积分榜、球队阵容列表、球员赛季统计、比赛阵容或复杂统计接口，对应页签使用正式空状态；实时比分推送、评分、视频与高级统计均未实现。

```powershell
powershell -NoProfile -ExecutionPolicy Bypass -File .\scripts\windows\check-f06.ps1
```

F06 最终收口取消了首页关注球队卡右上角的独立箭头：真实球队整卡直接进入 `/teams/:teamId`，不会先改变 Feed 球队筛选；“全部”仍只负责恢复全部 Feed。返回后由原页面实例保留 Feed tab、球队筛选、列表与滚动位置。

现实足球文字核验仅输出 `reports/F06_REAL_WORLD_TEXT_DATA_AUDIT.md` 与机器可读 corrections；运行时仍以本机后端 API 为唯一事实源。本轮未处理视觉/媒体资源，未修改后端或数据库，现实数据修正必须另建获授权的后端任务。

```powershell
powershell -NoProfile -ExecutionPolicy Bypass -File .\scripts\windows\check-f06-text-data-audit.ps1
```
