# 南看台前端架构

> 版本：v0.1
> 当前阶段：F01
> 文档定位：定义总体架构、目录边界、依赖方向和唯一完整项目结构树。
> 不负责：接口字段、完整技术版本或任务路线。

## 总体架构

Flutter App 与 Vue 管理后台物理隔离、独立构建，共享后端 HTTP 契约但不共享平台代码。前端仓库与 `D:\Football-APP` 后端仓库独立；前端只消费公开 API 和只读文档快照，不依赖数据库、Entity、Mapper 或 Service。

## F01 实际结构

F01 只创建 skeleton 能力，不提前建立空业务模块。Flutter 使用 `ProviderScope → MaterialApp.router → GoRouter → SkeletonPage`；Vue 使用 `App → Router → View`，并注册 Pinia 与 Element Plus。

```text
apps
├── mobile
│   ├── android / ios
│   ├── lib
│   │   ├── main.dart
│   │   ├── app/{app.dart,router,theme}
│   │   └── features/skeleton/presentation/pages
│   └── test
└── admin
    ├── src
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

页面/Widget 调用状态控制器，状态控制器调用用例或仓储，数据层调用统一网络/存储；禁止页面直接创建 Dio、跨 feature 访问对方 data 层或基础层反向依赖 feature。

## Vue 边界与依赖方向

`views` 负责页面编排，`api` 封装后端访问，`stores` 管客户端状态，`router` 负责路由和守卫，`layouts` 负责后台框架，`components/common` 保持通用，`components/business` 承载复用业务展示，`types` 定义前端模型。

调用方向为 view/component → store/composable/api → 统一 request。禁止页面各自解析返回格式、API 层依赖 view、store 直接操作 DOM 或业务组件进入 common。

## 命名与扩展

Dart 文件使用 `snake_case`，类型使用 `UpperCamelCase`；TypeScript 变量使用 `camelCase`，Vue 组件使用 `PascalCase`。新增模块先确认业务归属和依赖方向；仅因“以后可能复用”不得提前建立大量抽象层。
