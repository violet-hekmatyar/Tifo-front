# 南看台前端技术栈

## F05 新增依赖

新增官方 `image_picker ^1.2.3`，只用于 Android/iOS 相册多图选择；不调用相机、视频、裁剪或压缩，与 Dart 3.12.2 / Flutter 3.44.6 兼容。

> 版本：v0.1
> 当前阶段：F03
> 文档定位：技术栈和完整依赖版本表的唯一权威文档。
> 不负责：本机安装路径、页面流程、接口字段或验收教程。

## Flutter 移动端版本

| 技术 | F03 实际版本 |
|---|---:|
| Flutter | 3.44.6 stable |
| Dart | 3.12.2 stable |
| DevTools | 2.57.0 |
| flutter_riverpod | 3.3.2 |
| go_router | 17.3.0 |
| Dio | 5.10.0 |
| http_mock_adapter（测试） | 0.6.1 |
| flutter_secure_storage | 10.3.1 |
| flutter_lints | 6.0.0 |

当前只使用安全存储保存 Access Token；模型生成等后续依赖尚未安装。

## Vue 管理后台版本

| 技术 | F02 实际版本 |
|---|---:|
| Node.js | 24.17.0 |
| npm | 11.13.0 |
| Vue | 3.5.40 |
| TypeScript | 6.0.3 |
| Vite | 8.1.5 |
| Vue Router | 5.2.0 |
| Pinia | 3.0.4 |
| Element Plus | 2.14.3 |
| Vitest | 4.1.10 |
| ESLint | 10.7.0 |
| Prettier | 3.8.4 |
| Sass | 1.101.0 |
| Vue Test Utils | 2.4.11 |
| Vue DevTools Vite plugin | 8.1.5 |
| Oxc linter | 1.69.0 |
| Axios | 1.18.1 |
| axios-mock-adapter（测试） | 2.1.0 |

包管理器固定为 npm，锁文件为 `package-lock.json`。Vue DevTools 和 Oxc linter 是 create-vue 3.22.4 当前生成配置的一部分。

## 版本来源与约束

Flutter/Dart 版本来自 `flutter --version`，Dart 包来自 `pubspec.lock`，Node/npm 来自命令输出，Vue 依赖来自 `package-lock.json` 与 `npm list --depth=0`。Flutter 统一使用 Riverpod，不混用 Bloc；后台固定 Vue 3 + TypeScript，不改用 React，不引入第二套 UI 库、微前端、Nuxt、SSR 或 GraphQL。
