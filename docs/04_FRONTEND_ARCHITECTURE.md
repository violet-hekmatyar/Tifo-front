# 南看台前端架构

## F07 User Center

`features/user_center` 采用 `Page → Controller/Provider → UserCenterRepository → UserCenterApi → ApiClient`，JSON 只在 data 层映射。个人摘要使用 FutureProvider；多类分页列表复用带请求类型的 ChangeNotifier；公开主页控制器负责关注乐观状态、重复保护和失败回滚。`features/message` 仅承载正式能力缺口页，因为后端没有消息契约。用户与列表详情通过 root Navigator 覆盖主壳并保留底部 Tab 实例。

## F06 路由与展示排序修正

详情 GoRoute 通过 `parentNavigatorKey: rootNavigatorKey` 覆盖 StatefulShellRoute，push 后保留来源分支。认证 redirect 明确认可 matches/teams/players。纯函数 `domain/match_display_sort.dart` 在 Controller 首屏和分页合并后集中排序；Widget 只按已排序集合建立日期组。

## F06 Football Feature

`features/football` 包含集中 JSON 适配的 `data/football_api.dart`、仓储契约与实现、纯领域模型、数据页和球队/球员/比赛详情。数据页与球队赛程使用 ChangeNotifier 控制首次加载、刷新、分页、去重、防并发和旧请求隔离；详情使用按 ID 的 auto-dispose FutureProvider，并由 `IndexedStack` 保留页内 Tab。固定调用链为 `Page/Widget → Controller/Provider → FootballRepository → FootballApi → ApiClient`。

## F05 内容、互动与上传

`content` 管详情/发布，`interaction` 管 toggle、评论分页/回复，`file_upload` 管 F05 图片上传/删除。调用为 `Page → Controller → Repository → ApiClient`，multipart 复用统一 Bearer 注入。

> 版本：v0.1
> 当前阶段：F03.1
> 文档定位：定义总体架构、目录边界、依赖方向和唯一完整项目结构树。
> 不负责：接口字段、完整技术版本或任务路线。

## 总体架构

Flutter App 与 Vue 管理后台物理隔离、独立构建，共享后端 HTTP 契约但不共享平台代码。前端仓库与 `D:\Football-APP` 后端仓库独立；前端只消费公开 API 和只读文档快照，不依赖数据库、Entity、Mapper 或 Service。

## F03 实际结构

F03 在 F02 网络层上新增 `core/auth`、`features/auth`、`features/onboarding` 和认证路由状态机。F03.1 新增 `shared/design_system` 与 `shared/widgets`，集中 Flutter 视觉 Token、通用状态、表单、按钮、选择卡片及实体图片占位。调用方向固定为页面 → Controller → Repository → ApiClient；页面不直接访问 Dio 或 secure storage。Vue 保持 F02，不增加登录功能。

```text
apps
├── mobile
│   ├── android / ios
│   ├── lib
│   │   ├── main.dart
│   │   ├── app/{app.dart,config,router,theme}
│   │   ├── core/network
│   │   ├── core/auth
│   │   ├── shared/{design_system,widgets}
│   │   └── features/{auth,onboarding}
│   └── test
└── admin
    ├── src
    │   ├── api
    │   ├── config
    │   ├── components/common
    │   ├── router
    │   ├── stores
    │   ├── styles
    │   └── views/{skeleton,error}
    └── public
```

## 完整项目结构树（Complete Project Structure Tree）

下方是目标结构，仍是完整项目结构树的唯一权威维护位置；未出现在上述 F01 实际结构中的业务目录由后续任务按需创建。

```text
D:\Football-APP-Front
├── README.md
├── .gitignore
├── .editorconfig
├── docs
├── apps
│   ├── mobile                         # Flutter
│   │   ├── pubspec.yaml
│   │   ├── assets
│   │   ├── lib
│   │   │   ├── main.dart
│   │   │   ├── app
│   │   │   │   ├── router
│   │   │   │   └── theme
│   │   │   ├── core
│   │   │   │   ├── config
│   │   │   │   ├── network
│   │   │   │   ├── auth
│   │   │   │   ├── storage
│   │   │   │   ├── error
│   │   │   │   └── utils
│   │   │   ├── shared
│   │   │   │   ├── design_system
│   │   │   │   ├── widgets
│   │   │   │   ├── models
│   │   │   │   └── providers
│   │   │   └── features
│   │   │       ├── splash
│   │   │       ├── auth
│   │   │       ├── onboarding
│   │   │       ├── main_shell
│   │   │       ├── feed
│   │   │       ├── content
│   │   │       ├── interaction
│   │   │       ├── publish
│   │   │       ├── football
│   │   │       │   ├── data
│   │   │       │   ├── domain
│   │   │       │   └── presentation
│   │   │       ├── follow
│   │   │       ├── user_center
│   │   │       ├── message
│   │   │       └── file_upload
│   │   ├── test
│   │   └── integration_test
│   └── admin                          # Vue 3 + TypeScript
│       ├── package.json
│       ├── vite.config.ts
│       ├── src
│       │   ├── main.ts
│       │   ├── App.vue
│       │   ├── api
│       │   │   ├── request.ts
│       │   │   └── modules
│       │   ├── assets
│       │   ├── components
│       │   │   ├── common
│       │   │   └── business
│       │   ├── composables
│       │   ├── constants
│       │   ├── layouts
│       │   ├── router
│       │   ├── stores
│       │   ├── styles
│       │   ├── types
│       │   ├── utils
│       │   └── views
│       │       ├── login
│       │       ├── dashboard
│       │       ├── user
│       │       ├── content
│       │       ├── football
│       │       ├── file
│       │       ├── operation-log
│       │       └── error
│       └── public
├── scripts
├── prompts
├── reports
└── tmp
```

不会创建 `apps/h5`、`apps/web` 或 `apps/miniprogram`。

## Flutter 边界与依赖方向

采用 feature-first。`core` 只放跨业务基础设施，`shared` 放稳定、无特定业务归属的复用元素，`features` 按业务闭环组织。复杂 feature 可使用 `data → domain ← presentation`；简单模块允许省略 domain，避免空壳抽象。

页面/Widget 调用状态控制器，状态控制器调用用例或仓储，数据层调用统一网络/存储；禁止页面直接创建 Dio、捕获 `DioException`、跨 feature 访问对方 data 层或基础层反向依赖 feature。`appConfigProvider → dioProvider → apiClientProvider` 可在测试中替换。

业务页面不得散落颜色、间距、圆角和字体常量，统一从 `shared/design_system` 消费；共享 Widget 不依赖 auth/onboarding data 层。视觉唯一权威见 [13_CLIENT_UI_VISUAL_BASELINE.md](13_CLIENT_UI_VISUAL_BASELINE.md)。

### F04 主框架与 Feed 实际结构

认证完成后由 `StatefulShellRoute.indexedStack` 承载首页、数据、消息、我的四个分支；分支各自保留导航栈，首页滚动位置使用稳定 PageStorage key。`features/main_shell/presentation` 负责壳与三个最小入口，`features/feed` 按 `data/domain/presentation` 分层，卡片 DTO、领域联合类型、控制器与渲染器职责分离。

调用链固定为 `HomeFeedPage/Widget → FeedController → FeedRepository → FeedApi → F02 ApiClient`。原始 JSON 只在 data/dto 层解析；`FeedCardRenderer` 集中分发内容、比赛和未知卡片；页面不依赖 Dio。连续内容卡按原顺序组成双列，比赛和未知卡全宽，分组不重排后端顺序。

## Vue 边界与依赖方向

`views` 负责页面编排，`api` 封装后端访问，`stores` 管客户端状态，`router` 负责路由和守卫，`layouts` 负责后台框架，`components/common` 保持通用，`components/business` 承载复用业务展示，`types` 定义前端模型。

调用方向为 view/component → store/composable/api → 统一 request。禁止页面各自解析返回格式或捕获 `AxiosError`、API 层依赖 view、store 直接操作 DOM 或业务组件进入 common。401/403 在 F02 只转换为统一 HTTP 错误。

## 命名与扩展

Dart 文件使用 `snake_case`，类型使用 `UpperCamelCase`；TypeScript 变量使用 `camelCase`，Vue 组件使用 `PascalCase`。新增模块先确认业务归属和依赖方向；仅因“以后可能复用”不得提前建立大量抽象层。

## F05 发布返回与 Feed 展示分区修正

- 发布页位于主框架之上的命令式路由栈；成功后解除草稿离开拦截，并以 replacement 将发布页替换为详情页。
- `FeedRefreshRequest` 是一次性 presentation 协调信号。原首页消费后调用既有 `FeedController.refresh()`，不重建 StatefulShellRoute。
- `FeedDisplaySections.fromCards` 是集中式展示模型：MATCH、CONTENT、Unknown 分组；原始 DTO/domain 列表不被重排或污染。
- 稳定去重键分别为 matchId、contentId、Unknown cardId；同类型保持后端与跨页到达顺序。
