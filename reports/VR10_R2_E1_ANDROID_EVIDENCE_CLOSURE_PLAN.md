# VR10-R2-E1 Android 视觉证据补正计划

状态：**证据已提交但最终复验未通过：状态栏图标不可见且截图含人工绿色外框；转入 VR10-R3**  
前置：VR10-R2 已通过 Plan 模型源码复验  
目标：使用当前最终源码构建同一 APK，完成两张设置原型的 Android 证据与最终复验材料。

## 1. 范围与保护项

本阶段只允许：

- 从普通 Windows Terminal 构建、安装当前源码 APK；
- 运行真实 API/脱敏手机号只读核对；
- 调整模拟器尺寸与字体并采集截图；
- 生成直接双栏对照和更新 VR10 证据报告。

禁止修改：

- Dart、Java、SQL、测试、路由、API 契约和数据库；
- 原型图或截图内容；
- 登录、消息、个人中心其他页面及 VR11 范围；
- 使用旧 APK、fixture APK、旧截图或嵌套 comparison。

如证据暴露真实视觉问题，停止并如实报告，不得在 E1 内临时改代码。

## 2. 普通 Windows Terminal 构建

在普通 Windows Terminal 执行：

```powershell
$ErrorActionPreference = 'Stop'
Set-Location -LiteralPath 'D:\Football-APP-Front\apps\mobile'
flutter build apk --debug
Get-FileHash -Algorithm SHA256 -LiteralPath '.\build\app\outputs\flutter-apk\app-debug.apk'
```

要求：

1. 构建前记录前端 commit 和工作树状态；不得清理或覆盖已有改动。
2. 构建产物必须为当前命令新生成的 `app-debug.apk`，记录完整 SHA-256 和构建时间。
3. 安装后再次核对设备内 APK 与记录哈希一致；后续全部正式截图使用这一 APK。
4. 若普通 Terminal 仍失败，保存完整错误日志并停止，不得用旧 APK 替代。

## 3. 真实状态核对

1. 使用已有测试账号登录，不新建账号、不改数据库。
2. `GET /api/auth/me` 必须为 HTTP 200、`code=0`；页面只显示 `phoneMasked` 或“未绑定”。
3. 报告不得记录 Token、完整手机号、密码或完整认证响应。
4. 实际点击并验证：账号与安全进入/返回、三个设置入口暂未开放、手机号/修改密码/注销账号暂未开放、退出确认取消。
5. 不执行真正退出，除非需要单独验证且能安全重新登录；不得触发任何不存在的敏感操作。

## 4. 同一 APK 截图

证据目录：`reports/VR10_SETTINGS_ACCOUNT_SECURITY_VISUAL_PARITY_EVIDENCE/`

必须采集：

- `01_settings.png`
- `02_account_security.png`
- `03_unavailable_feedback.png`
- `04_logout_confirm.png`
- `05_360dp_settings.png`
- `06_360dp_account_security.png`
- `07_140_percent_settings.png`
- `08_140_percent_account_security.png`

标准图使用 1080×2400、density 420、font scale 1.0。360dp 与 140% 字体必须实际切换设备参数并重新进入页面，不能由图片缩放生成。

截图检查：

- 设置页无右箭头，账号安全页有 3 个右箭头；
- 5 条分隔线约从页面 x=25dp 延伸到分组右边界；
- 设置组、账号安全组、标题、图标、退出块和大面积留白与原型一致；
- 脱敏手机号不泄露完整号码；
- 360dp、140% 字体无 overflow、遮挡或不可点击。

## 5. 对照与报告

1. 生成：
   - `comparison_01_settings.png`
   - `comparison_02_account_security.png`
2. 每张仅由对应原型原始 PNG 与本次 APK 原始标准图直接双栏组成，等高或等宽保持比例。
3. `VISUAL_COMPARISON.md` 逐图记录结构、关键坐标、目标/实际/误差和平台系统栏豁免。
4. `EXECUTION_RECORD.md` 记录 APK 哈希、截图哈希、设备参数、API 只读结果、交互结果和恢复结果。
5. 完成后恢复设备为 1080×2400、density 420、font scale 1.0，并核对两仓 `git diff --check`。

## 6. 完成条件

- 当前源码 APK 构建、安装和 SHA-256 闭环；
- 8 张正式截图与 2 张直接双栏对照齐全；
- 两张标准图严格符合原型，响应式图无异常；
- 真实脱敏数据和交互核对通过；
- 未修改任何生产代码、后端、数据库或测试；
- 设备参数已恢复；
- 完成后只提交 Plan 模型最终复验，不自行宣布 VR10 通过或进入 VR11。

## 7. 交给执行模型的精简提示词

执行 `D:\Football-APP-Front\reports\VR10_R2_E1_ANDROID_EVIDENCE_CLOSURE_PLAN.md`。VR10-R2 源码已通过 Plan 复验，本轮禁止修改生产代码、后端、数据库和测试。请在普通 Windows Terminal 运行 `flutter build apk --debug`，记录当前 `app-debug.apk` 完整 SHA-256，安装同一 APK，以真实登录态核对脱敏手机号和交互；按计划采集 8 张 Android 原始截图、制作 2 张原型直接双栏对照并更新执行/视觉报告。360dp 与 140% 必须真实切换设备参数，结束后恢复 1080×2400、420dpi、100% 字体。若构建或截图暴露问题，停止并报告，不得复用旧 APK或临时改代码。完成后只提交 Plan 最终复验，不进入 VR11。
