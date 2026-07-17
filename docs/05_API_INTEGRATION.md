# 南看台前端 API 接入规范

> 版本：v0.2
> 当前阶段：F02
> 文档定位：前端接口接入、解析、错误处理和变更流程的唯一权威文档。
> 不负责：复制后端完整请求/响应示例或重新定义后端契约。

## 权威来源

后端原始契约：`D:\Football-APP\docs\06_API_SPEC.md`；仓库内只读快照：`references/backend/06_API_SPEC.md`。原始文件优先于快照。

## 基础接入

Base URL 必须按环境配置，不得硬编码服务器地址。Flutter 使用 `--dart-define=APP_ENV=...` 和 `--dart-define=API_BASE_URL=...`；Vue 使用 `VITE_APP_ENV` 和 `VITE_API_BASE_URL`。环境只允许 `development`、`test`、`production`。接口前缀包括 `/api/auth/**`、`/api/app/**`、`/api/admin/**`、`/api/public/**`、`/api/file/**`。

F02 只提供可替换的请求头 provider，不生成假 Token、不选择存储方案。后续认证任务需要登录时才发送：

```http
Authorization: Bearer <access_token>
```

统一响应由网络层一次解析为 `code / message / data / traceId`；分页数据统一为 `records / total / pageNum / pageSize / pages`。页面不得自行兼容多套返回格式，也不得根据截图或数据库字段重建契约。

## 错误处理

| code | F02 前端原则 |
|---:|---|
| `40001` | 作为业务错误保留 code、message 与 traceId |
| `40101` / `40102` | 只归一化；若 HTTP 为 401 则作为 HTTP 错误，不清理会话、不跳转 |
| `40301` | 只归一化；若 HTTP 为 403 则作为 HTTP 错误，不执行权限路由 |
| `40401` / `40901` / `50001` | 保留业务错误信息，具体 UI 行为由后续业务任务决定 |

双端统一区分配置、网络断开、超时、取消、HTTP 非成功状态、业务 `code != 0`、解析和未知错误。Flutter Feature 不接触 `DioException`，Vue 调用方不接触 `AxiosError`。日志可记录路径、错误码和 traceId，不得记录完整 Token 或敏感请求体。

## 响应、分页与适配边界

统一成功码暂按后端文档的 `code == 0`；`data` 由调用方提供强类型 decoder，支持对象、空数据、列表和 `PageResult<T>`。二进制文件响应不经过 JSON 包络解析。后端对“业务失败使用 2xx 还是非 2xx”的具体端点策略、无数据时 `data` 是否始终存在，仍以联调为准；当前 HTTP 与业务错误分层集中在适配层，可局部调整而不污染 Feature。

后端返回相对图片 URL 时，后续由 URL resolver 使用当前环境 Base URL 拼接；绝对 URL 需按允许策略直接使用。DTO/VO 在网络边界转换为前端模型，页面不接触后端 Entity 概念。未知枚举或 `cardType` 必须有兼容占位和可观测日志，不能导致整个列表崩溃。

## 页面与接口关系

页面只依赖按业务域封装的 API：认证/首次选择、feed、内容互动、足球数据、用户中心、管理用户内容、文件。具体路径和实际已实现范围以最新后端契约的 Current Implementation Notes 为准；计划接口不得当作已可用接口。F02 不调用任何真实业务 API。

## 变更流程

后端先更新并确认原始契约 → 运行同步脚本 → 在 `references/BACKEND_API_CHANGELOG.md` 登记影响 → 更新前端 API 层与模型 → 完成单元/联调/smoke → 再修改页面。禁止只改页面临时适配后跳过统一网络层。
