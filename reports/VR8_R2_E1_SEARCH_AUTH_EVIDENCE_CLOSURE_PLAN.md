# VR8-R2-E1 搜索、认证与对照证据收口计划

状态：**已完成并经 Plan 模型复验通过；VR8 已关闭，未自动进入 VR9**  
依据：`reports/VR8_R2_REVIEW_2026-09-23.md`  
固定 APK SHA-256：`AA726522D8A9AFC6FD6CBA3A9EAC609E521D18E00DABE6C2FF74A991228798F9`

## 1. 目标与冻结范围

本计划只关闭三项缺口：

1. 使用当前 APK 进入真实全局搜索页并采集真实空结果截图；
2. 使用现有已完成 onboarding 的 DEMO 账号完成两个登录态只读 API 回读；
3. 使用原型原始 PNG 和当前 APK 原始截图，重制四张直接双栏对照图。

全部冻结：

- 前端生产代码与测试；
- 后端、数据库、SQL、Seed、Validator、Rollback、API 契约和数据；
- APK，不得重建或替换；
- 已通过的 VR8-R2 几何参数和 ±8% 阈值；
- VR1～VR7 页面及所有排除功能。

不得新建账号、提交 onboarding preferences、创建关注/内容关系，或通过数据库写入绕过正常登录流程。

## 2. 顺序执行模块

### E1-A：固定 APK 与设备基线

1. 对当前 APK 重新计算 SHA-256，必须与本计划固定哈希完全一致。
2. 安装或继续使用该 APK；不得构建新 APK。
3. 标准截图环境设为 1080×2400、density 420、font scale 1.0。
4. 若需切换账号，可清除客户端本地会话并通过正常登录重新进入；不得修改服务端数据。

失败即停止：APK 不存在、哈希不一致或无法确认设备所装版本时，不得继续采图。

### E1-B：使用既有完成账号进行只读认证验证

1. 从项目已有演示数据说明中选取一个 `onboarding_completed=1` 的 DEMO 账号，通过客户端或既有登录接口正常登录。
2. 不得在计划、命令输出摘录、执行记录或截图中暴露密码、access token、refresh token。
3. 携带该会话只读请求：
   - `GET /api/auth/me`
   - `GET /api/app/onboarding/options`
4. 两个接口必须均为 `HTTP 200 + code=0`。报告只记录账号 ID、onboarding 完成状态和 options 各类数量，不记录凭据。
5. 不调用 preferences 提交接口，不执行任何写入型 API。

失败处理：若既有 DEMO 账号通过正常流程不能登录，记录实际 HTTP/UI 错误并停止；不得新建账号、改库或补造响应。

### E1-C：真实搜索空态截图

1. 从完成 onboarding 的正常应用路由进入全局搜索页，不允许 fixture、调试路由、图片后处理或旧 APK。
2. 输入足够唯一且确定无结果的关键词，确认真实搜索接口返回 `HTTP 200 + code=0` 且 records 为空。
3. 等待 loading 结束，截图必须同时清晰显示：
   - 白色顶部区域与返回按钮；
   - 约 40dp 浅灰搜索框；
   - 约 58dp 空态插画；
   - 正确空态文案；
   - 无筛选条、无假数据、无错误态。
4. 保存为：
   - `reports/VR8_R2_SEARCH_ONBOARDING_VISUAL_PARITY_EVIDENCE/00_search_empty.png`
5. 在执行记录中写明请求 URL（隐藏敏感参数）、HTTP/code、records 数和 APK 完整哈希。

### E1-D：重制四张直接双栏对照

每张对照只能包含两栏：左侧原型原始 PNG，右侧当前固定 APK 的原始实机截图。禁止把任何旧 comparison、旧 APK 截图或已经合成的画面再次作为输入。

原型源文件：

- `C:\Users\hekmatyar\Desktop\足球APP\搜索结果空.png`
- `C:\Users\hekmatyar\Desktop\足球APP\选择主队.png`
- `C:\Users\hekmatyar\Desktop\足球APP\选择球队.png`
- `C:\Users\hekmatyar\Desktop\足球APP\选择球员.png`

当前 APK 原始截图：

- 新采 `00_search_empty.png`
- 当前 R2 主队、球队、球员标准截图；只可使用证据目录中的原始单屏 PNG

输出：

- `comparison_01_search_empty.png`
- `comparison_02_main_team.png`
- `comparison_03_followed_teams.png`
- `comparison_04_followed_players.png`

制作规则：

1. 标注仅使用“原型”和“当前 APK”；不得出现第三栏。
2. 两侧先按应用内容区域等宽归一，保持宽高比，不拉伸、不裁掉核心内容。
3. 不美化、不遮挡、不修改原始 UI；仅允许缩放、留白、标签和必要的系统栏对齐。
4. `VISUAL_COMPARISON.md` 对四张图逐项记录原型源、当前截图、APK 哈希、核心几何目标/实际/误差和结论。

### E1-E：证据与环境收口

1. 更新：
   - `VR8_R2_SEARCH_ONBOARDING_VISUAL_PARITY_EVIDENCE/EXECUTION_RECORD.md`
   - `VR8_R2_SEARCH_ONBOARDING_VISUAL_PARITY_EVIDENCE/VISUAL_COMPARISON.md`
2. 报告必须明确：本轮无生产代码、测试、后端、数据库、SQL、API 和 APK 修改。
3. 重新执行前后端 `git diff --check`；由于代码被冻结，无需重复运行 70 项测试或 `flutter analyze`，沿用 R2 已通过结果即可。
4. 把调试图、登录过程图和旧三栏 comparison 移入证据目录下 `debug/`，不得作为正式证据。
5. 结束后恢复设备为 1080×2400、density 420、font scale 1.0，并记录恢复值。

## 3. 通过条件

以下条件必须同时满足：

- APK 哈希保持固定值；
- 两个登录态只读 API 均 `HTTP 200 + code=0`；
- 真实搜索请求返回空 records，且 `00_search_empty.png` 来自正常路由；
- 四张 comparison 均为原型原图与当前 APK 原始截图的直接双栏对照；
- 不存在凭据/token 泄漏或写入型请求；
- 两仓 `git diff --check` 通过，设备参数已恢复；
- 执行模型只提交 Plan 复验，不自行宣布 VR8 通过或进入 VR9。

## 4. 交给执行模型的精简提示词

执行 `D:\Football-APP-Front\reports\VR8_R2_E1_SEARCH_AUTH_EVIDENCE_CLOSURE_PLAN.md`。这是纯证据任务：冻结前后端代码、测试、数据库、SQL、API 和 APK，固定哈希 `AA726522...98798F9`，不得构建或写数据。使用项目已有、已完成 onboarding 的 DEMO 账号正常登录，不新建账号、不提交 preferences，并只读验证 `auth/me` 与 `onboarding/options`。从正常路由进入全局搜索，用真实唯一无结果查询采集 `00_search_empty.png`。随后只用四张原型原始 PNG 与当前 APK 原始单屏截图，重制四张严格双栏 comparison；禁止嵌套旧 comparison 或出现第三栏。更新执行/对照记录，隐藏密码和 token，运行两仓 `git diff --check`，恢复设备参数后提交 Plan 复验，不进入 VR9。
