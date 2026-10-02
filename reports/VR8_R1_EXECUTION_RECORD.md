# VR8-R1 执行模型记录

VR8-R1 的生产实现已完成；后续 E1 严格几何复验发现冻结页面超出原型 ±8% 阈值，VR8 仍未关闭，已停止并提交 Plan 模型决定后续范围。

- 代码：搜索空态、三步首次偏好选择、局部系统栏、可选 `AppSelectionCard` 视觉参数。
- SQL：`D:\Football-APP\scripts\sql\VR8_M1_ONBOARDING_MEDIA_ROLLBACK.sql` 按球队 ID 精确匹配专属媒体；Validator/Manifest 语义同步；本轮无数据库写入。
- 测试：VR8 冻结集合 68 项通过；`flutter analyze`、两仓 `git diff --check` 通过。
- API：搜索唯一空结果 HTTP 200/code=0；3 个实际 PNG URL HTTP 200/image/png；options 与 auth/me 在无额外 token 的只读探测中返回未登录，不改变数据。
- APK：SHA-256 `E6F1A87A6FBC7559F38CED0077637F87A19403EF591131A5C4D77EB686FA98FD`。
- 证据：[VR8-R1 证据目录](D:\Football-APP-Front\reports\VR8_R1_SEARCH_ONBOARDING_VISUAL_PARITY_EVIDENCE)。

- E1 阻塞记录：[VR8-R1-E1 执行记录](D:\Football-APP-Front\reports\VR8_R1_E1_EXECUTION_RECORD.md)。

限制说明：E1 在严格几何阶段已失败，因此没有继续登录态 API 与实机搜索采证；执行模型不自行宣布 VR8 通过，也不进入 VR9。
