# F03.1 客户端视觉基线执行报告

> 日期：2026-07-17  
> 前端仓库：`D:\Football-APP-Front`  
> 后端仓库：`D:\Football-APP`（只读，未修改）

## 1. 初始状态

开始时前端 `main` 工作区 clean，HEAD 为 `cd36d12 feat: add mobile authentication and onboarding flow`；后端 `main` clean。本轮未执行 Git add/commit/push/reset/clean。

## 2. 参考与文档治理

已读取前端 00-12 主线文档、F03 报告和产品 PDF；使用 Poppler 将 PDF 第 1、5 页渲染为 PNG 并视觉核对。新增 13 作为 Flutter 视觉 Token 与组件规则唯一权威，同步 README、00、04、06、10、11 和 mobile README。

## 3. 视觉实现

新增 `shared/design_system` 的颜色、间距、圆角、文字和阴影 Token，AppTheme 统一配置 ColorScheme、TextTheme、输入、按钮、卡片、Chip 与背景。新增通用按钮、输入、区块标题、状态、选择卡片和球队/球员占位；实体颜色基于稳定 identity 计算。

登录、注册与临时完成页统一使用蓝紫品牌头、浅背景和白卡。Onboarding 保留原 Controller/Repository/API，仅新增本地步骤和搜索 presentation 状态，重构为主队、球队、球员三步；仅最后一步提交，步骤返回保留选择。

## 4. 图片与后端边界

未增加真实图片资源、随机外链、图片缓存依赖、后端接口、数据库或 seed 改动。页面继续复用 F02/F03 URL resolver，共享 Widget 不拼接 Base URL。URL 为空/失败时使用稳定且语义区分的球队/球员占位。

## 5. 测试与检查

新增 `f03_1_visual_baseline_test.dart`，覆盖认证品牌和字段、小屏/文字放大、三步导航与选择保持、状态/retry、占位与稳定色、临时页边界。新增 `check-mobile-f03-1.ps1` 与 `check-f03-1.ps1`。

最终验收结果：

| 检查 | 结果 |
|---|---|
| `dart format --set-exit-if-changed` | 通过，0 changed |
| `flutter analyze` | 通过，No issues found |
| `flutter test` | 41 项通过 |
| Android Debug APK | 通过，使用 development / `http://10.0.2.2:8080` |
| `check-f03.ps1` | 通过，含真实后端 auth/onboarding smoke |
| `check-mobile-f03-1.ps1` | `F03.1 Flutter visual baseline check passed` |
| `check-f03-1.ps1` | `F03.1 client visual baseline check passed` |

APK 位于 `apps/mobile/build/app/outputs/flutter-apk/app-debug.apk`。自动测试不替代人工视觉验收。

## 6. 人工验收状态与风险

本轮未伪造人工视觉验收。仍需用户在 Pixel 8/API 36 模拟器或 Android 真机观察品牌一致性、键盘、长列表、选中态、返回键、图片失败和文字放大。Windows 未执行 iOS build；后端仍无 Refresh Token；真实图片资源的完整度依赖后端数据。

## 7. 范围结论

F04 首页、主框架、底部导航以及新闻/比赛/统计假数据均未实现。建议在人工视觉审查通过后提交，建议提交信息：

```text
feat: establish mobile client visual baseline
```

下一步 F04 只需继承 13 中的 Token、状态组件和实体占位策略，再开发正式主框架与首页真实卡片流。
