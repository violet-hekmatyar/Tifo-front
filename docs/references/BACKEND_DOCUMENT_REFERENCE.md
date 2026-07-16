# 后端文档与前端用途映射

后端原始文件优先于同步快照。快照只用于 Codex 在前端仓库内读取，前端不得修改后端契约。

| 后端源文件 | 前端用途 | 前端主线文档 | 复制为快照 | 权威性说明 |
|---|---|---|---|---|
| `00_DOCUMENT_MAP.md` | 来源导航 | 00 | 是 | 后端文档入口 |
| `01_PROJECT_OVERVIEW.md` | 产品背景 | 01 | 是 | 产品背景参考 |
| `02_REQUIREMENT_SCOPE.md` | 需求边界 | 02 | 是 | 后端范围参考，前端已确认范围优先 |
| `03_TECH_STACK.md` | 后端环境/旧前端建议参考 | 03 | 是 | 不覆盖前端 Vue 决策 |
| `04_BACKEND_ARCHITECTURE.md` | 服务边界 | 04/05 | 是 | 不复制内部实现到前端 |
| `05_DATABASE_SCHEMA.md` | 理解业务语义 | 05 | 是 | 非前端数据模型契约 |
| `06_API_SPEC.md` | API 接入 | 05 | 是 | API 权威契约 |
| `07_AUTH_SECURITY.md` | 鉴权与安全 | 07 | 是 | 安全权威契约 |
| `08_ALGORITHM_INTEGRATION.md` | 推荐降级与卡片 | 05/06 | 是 | 算法边界参考 |
| `09_DEPLOYMENT_GUIDE.md` | 构建部署参考 | 08 | 是 | 后端部署不等于前端部署 |
| `10_AI_CODING_RULES.md` | AI 边界 | 09 | 是 | 与前端规则共同约束 |
| `11_VALIDATION_AND_SMOKE_GUIDE.md` | 验证参考 | 10 | 是 | 后端命令不直接套用前端 |
| `12_CODEX_TASK_PLAN.md` | 任务拆分参考 | 11 | 是 | 前后端路线独立维护 |
