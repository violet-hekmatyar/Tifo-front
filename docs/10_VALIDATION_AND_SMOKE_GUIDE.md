# 南看台前端验证与 Smoke 指南

> 版本：v0.1
> 当前阶段：F02
> 文档定位：验证命令与 smoke 计划的唯一权威文档。
> 不负责：任务路线或本机安装教程。

## F01 自动验收

| 脚本 | 覆盖范围 | 成功输出 |
|---|---|---|
| `check-repo.ps1` | 阶段无关的目录、文档、Git 与敏感产物检查 | `Frontend repository base check passed` |
| `check-mobile-f01.ps1` | Flutter 环境、Android toolchain、格式、analyze、test、APK | `F01 Flutter mobile check passed` |
| `check-admin-f01.ps1` | Node engine、npm ci、lint、类型、测试、build | `F01 Vue admin check passed` |
| `check-f01.ps1` | 按顺序聚合以上检查 | `F01 frontend skeleton check passed` |

```powershell
powershell -ExecutionPolicy Bypass -File .\scripts\windows\check-f01.ps1
```

Windows 不执行 iOS build。APK 构建成功不等于视觉预览完成；Android 模拟器/真机和 Vue 浏览器视觉观察不放入自动脚本，操作见 [12_LOCAL_DEVELOPMENT_ENVIRONMENT.md](12_LOCAL_DEVELOPMENT_ENVIRONMENT.md)。F01 不调用后端，也不进行登录、首页或管理业务 smoke。

`flutter doctor` 中 Chrome 与 Visual Studio 缺失分别只影响 Flutter Web 和 Windows 桌面端，对本项目 Android/iOS 范围非阻塞。GitHub Network resources 偶发超时属于网络诊断提示；只要 Android toolchain、依赖解析、测试和 APK 构建成功，不应误判为 Android 构建失败。

## F02 自动验收

| 脚本 | 覆盖范围 | 成功输出 |
|---|---|---|
| `check-mobile-f02.ps1` | Dio 文件/依赖、格式、analyze、Mock 测试、Android Debug APK | `F02 Flutter network foundation check passed` |
| `check-admin-f02.ps1` | Axios/配置/`.env.example`、真实 `.env` 跟踪检查、lint、类型、Mock 测试、build | `F02 Vue network foundation check passed` |
| `check-f02.ps1` | 依次运行 `check-repo`、完整 F01 回归和双端 F02 检查 | `F02 frontend network foundation check passed` |

```powershell
powershell -NoProfile -ExecutionPolicy Bypass -File .\scripts\windows\check-f02.ps1
```

F02 单元测试全部使用 mock adapter，不访问真实后端，也不启动 dev server 或模拟器。F01 必须在聚合脚本中完整回归；失败项存在时不得标记 F02 完成。
