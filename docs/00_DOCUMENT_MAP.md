# 南看台前端文档地图

> 版本：v0.1
> 当前阶段：F03.1
> 文档定位：前端文档集入口，只负责导航。
> 权威边界：不承载项目结构、技术版本、接口细节或任务实现。

## 文档来源

本文档集依据本轮 F00 要求、`D:\Football-APP\docs` 后端原始文档及产品 PDF 整理。后端同步快照位于 `references/backend/`，产品参考位于 `references/product/`。

## 主线文档与唯一职责

| 文档 | 唯一职责 |
|---|---|
| `00_DOCUMENT_MAP.md` | 导航、阅读路径和冲突优先级 |
| `01_PROJECT_OVERVIEW.md` | 产品定位、客户端组成和第一版闭环 |
| `02_REQUIREMENT_SCOPE.md` | P0/P1/P2、暂缓项和待确认项 |
| `03_TECH_STACK.md` | 技术栈与依赖边界 |
| `04_FRONTEND_ARCHITECTURE.md` | 架构、模块边界及唯一完整结构树 |
| `05_API_INTEGRATION.md` | 后端契约的前端接入与解析规则 |
| `06_UI_INTERACTION_SPEC.md` | UI 语言和交互原则 |
| `07_AUTH_ROUTING_SECURITY.md` | 会话、路由守卫和前端安全边界 |
| `08_BUILD_DEPLOYMENT_GUIDE.md` | 构建、产物和部署计划 |
| `09_AI_CODING_RULES.md` | AI 在前端仓库中的工作规则 |
| `10_VALIDATION_AND_SMOKE_GUIDE.md` | 验证命令和 smoke 计划 |
| `11_CODEX_TASK_PLAN.md` | F00-F13 大任务路线图 |
| `12_LOCAL_DEVELOPMENT_ENVIRONMENT.md` | 本机工具、Android 模拟器和双端预览方式 |
| `13_CLIENT_UI_VISUAL_BASELINE.md` | Flutter 客户端 Token、共享组件与认证流程视觉基线 |

完整结构树只见 [04_FRONTEND_ARCHITECTURE.md](04_FRONTEND_ARCHITECTURE.md)。

## 推荐阅读路径

- 新成员环境准备：00 → 12 → 03 → 04 → 10
- Flutter：00 → 12 → 01 → 02 → 03 → 04 → 06 → 07 → 05 → 10
- Flutter UI：00 → 13 → 06 → 04 → 10
- Vue 管理后台：00 → 01 → 02 → 03 → 04 → 07 → 05 → 06 → 10
- Codex：00 → 11 → 09 → 本轮相关权威文档 → 10
- 联调与验收：05 → 07 → 10 → `references/BACKEND_API_CHANGELOG.md`

## 维护规则

完整内容只在职责对应的权威文档维护，其他文档使用链接或摘要。接口变化先由后端确认并更新原始契约，再同步快照、登记 changelog，最后修改前端适配说明。

## 冲突处理优先级

1. 已确认的产品范围与前端主线文档；
2. 后端原始 `06_API_SPEC.md`、`07_AUTH_SECURITY.md` 等契约；
3. `references/backend/` 同步快照；
4. 产品 PDF 与原型图；
5. 临时讨论记录。

快照仅方便 Codex 在本仓库内读取，不替代原始文件。若后端旧文档中的前端技术建议与本项目已确认方案冲突，例如 React 与 Vue 冲突，以本前端主线技术决策为准；接口与安全契约仍以后端原始文档为准。
