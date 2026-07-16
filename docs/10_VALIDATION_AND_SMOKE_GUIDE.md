# 南看台前端验证与 Smoke 指南

> 版本：v0.1  
> 当前阶段：F00  
> 文档定位：验证命令与 smoke 计划的唯一权威文档。  
> 不负责：任务路线或业务实现细节。

## F00 唯一验证

```powershell
powershell -ExecutionPolicy Bypass -File .\scripts\windows\check-repo.ps1
```

F00 不执行 `flutter analyze`、`flutter test`、`flutter build`、`npm install`、`npm run lint` 或 `npm run build`，因为尚未创建应用工程。

## Flutter 后续验证计划

F01 后按任务逐步启用：`flutter pub get`、`dart format --set-exit-if-changed .`、`flutter analyze`、`flutter test`、`flutter build apk --debug` 和 `integration_test`。具体工作目录与参数以初始化后的 README 为准。

## Vue 后续验证计划

使用 F01 确认的包管理器安装锁定依赖，并运行 lint、type-check、Vitest 单元测试和 production build。不得在未锁定包管理器时伪造命令结果。

## 业务 Smoke 计划

覆盖用户登录、首次选择、首页、内容详情、评论/点赞/收藏、足球数据、我的页面；后台覆盖管理员登录、用户与内容管理、足球数据维护和文件上传。每项同时验证成功、无权限、空数据、网络错误和关键回退路径。

报告必须保留命令、退出码、通过/失败项、环境和未执行原因。失败项存在时不得把对应阶段标记完成。
