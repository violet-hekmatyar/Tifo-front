# 南看台前端技术栈

> 版本：v0.1  
> 当前阶段：F00  
> 文档定位：技术栈和依赖边界的唯一权威文档。  
> 不负责：页面流程、接口字段、目录树或完整验收命令。

## Flutter 移动端

| 能力 | 方案 |
|---|---|
| 框架/语言 | Flutter / Dart |
| 状态管理 | Riverpod |
| 路由 | go_router |
| 网络 | Dio |
| 模型生成 | Freezed / json_serializable |
| 安全存储 | flutter_secure_storage |
| 普通偏好 | shared_preferences |
| 图片缓存/选择 | cached_network_image / image_picker |
| 测试 | Flutter 原生测试 / integration_test |

## Vue 管理后台

| 能力 | 方案 |
|---|---|
| 框架/语言 | Vue 3 / TypeScript |
| 构建 | Vite |
| 路由/状态 | Vue Router / Pinia |
| 网络 | Axios |
| UI/样式 | Element Plus / SCSS |
| 测试/质量 | Vitest / ESLint / Prettier |

## 约束

Flutter 统一使用 Riverpod，不混用 Bloc；后台固定 Vue 3 + TypeScript，不改用 React。F00 不生成依赖或 lock 文件，具体小版本和包管理器由 F01 初始化时依据当时稳定版本锁定。

第一版不引入第二套 UI 组件库、微前端、Nuxt、SSR 或 GraphQL。新增依赖必须说明用途、维护状态、体积与替代方案，并由人工确认。
