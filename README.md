# 南看台前端 / Tifo Frontend

南看台前端包含面向普通用户的 Flutter 原生移动 App，以及仅供内部管理员使用的 Vue 3 + TypeScript 管理后台。当前不建设面向用户的 H5、PWA 或小程序。

- 前端仓库：`D:\Football-APP-Front`
- 后端仓库：`D:\Football-APP`
- 当前阶段：F00（仓库、文档与参考快照初始化）
- 文档入口：[docs/00_DOCUMENT_MAP.md](docs/00_DOCUMENT_MAP.md)
- 唯一完整结构树：[docs/04_FRONTEND_ARCHITECTURE.md](docs/04_FRONTEND_ARCHITECTURE.md)

## F00 命令

```powershell
powershell -ExecutionPolicy Bypass -File .\scripts\windows\sync-backend-docs.ps1
powershell -ExecutionPolicy Bypass -File .\scripts\windows\check-repo.ps1
```

后端文档快照只用于前端仓库内只读参考；契约变化应先在后端仓库确认，再重新同步。Base URL、Token、密码和密钥不得硬编码或提交。F01 才会初始化两个应用并锁定具体依赖版本。
