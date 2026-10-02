# VR10-R3 系统栏与纯净证据最终收口计划

状态：**已通过 Plan 模型最终复验；VR10 已完成并关闭**  
目标：让浅色设置页使用清晰的深色系统状态栏图标，并移除截图采集链路产生的亮绿色外框，完成最终同 APK 证据。

## 1. 严格范围

允许修改：

- `apps/mobile/lib/features/user_center/presentation/pages/settings_pages.dart`
- `apps/mobile/test/features/user_center/f19_settings_acceptance_test.dart`
- VR10 证据目录、执行记录与视觉对照报告

禁止修改：

- 页面结构、标题、图标、行高、分隔线、退出块、账号行和所有业务交互；
- `phoneMasked`、后端、数据库、认证流程和其他页面；
- 通过裁剪、涂色或后期修图隐藏绿色边框；
- 使用旧 APK、旧截图或 fixture。

## 2. R3-M0：系统栏失败断言

1. 为设置主页和账号安全页补充系统栏样式断言。
2. 两页都必须存在局部 `AnnotatedRegion<SystemUiOverlayStyle>` 或等价配置，并断言：
   - `statusBarColor` 为透明或页面同色；
   - `statusBarIconBrightness == Brightness.dark`；
   - iOS 对应 `statusBarBrightness == Brightness.light`；
   - 系统导航栏保持页面浅色且图标/手势条可见。
3. 断言在当前代码上应失败，证明问题被测试捕获。

## 3. R3-M1：唯一代码修复

1. 在设置模块的两页外层增加局部浅色页面系统栏样式，优先复用同一个私有常量/包装组件。
2. 不使用全局 `SystemChrome.setSystemUIOverlayStyle` 产生跨页面残留；页面离开后由路由目标自己的 `AnnotatedRegion` 接管。
3. 仅设置系统栏颜色和图标明暗，不改任何页面布局或业务代码。
4. 运行 F19、认证/路由定向测试与 `flutter analyze --no-pub`，核对前后端 `git diff --check`。

完成门槛：新增系统栏断言及原有全部测试通过，diff 只包含允许文件。

## 4. R3-M2：排除绿色边框来源

1. 在构建前确认模拟器没有启用布局边界、检查器选择框、焦点高亮、放大框或其他屏幕边缘叠加层。
2. 不使用会给画面添加高亮框的截图/控制工具。优先通过 Android 原生 `screencap` 生成设备文件后再 `adb pull`，保留原始像素。
3. 首张截图生成后立即检查四个角点和四边：角点应为页面背景色附近，不得为 RGB `171,212,47` 或其他人工高亮色。
4. 如果绿色外框仍存在，停止采集并定位来源；不得裁边、覆盖像素或在 comparison 阶段隐藏。

## 5. R3-M3：新 APK 与全量重采

1. 在普通 Windows Terminal 从最终源码重新运行 `flutter build apk --debug`，记录新的完整 SHA-256；不得复用 `B972...66A8`。
2. 安装同一 APK，使用真实登录态确认 `/api/auth/me` 为 HTTP 200、`code=0`，页面只显示脱敏值或“未绑定”。
3. 覆盖重采同一组 8 张正式图：
   - `01_settings.png`
   - `02_account_security.png`
   - `03_unavailable_feedback.png`
   - `04_logout_confirm.png`
   - `05_360dp_settings.png`
   - `06_360dp_account_security.png`
   - `07_140_percent_settings.png`
   - `08_140_percent_account_security.png`
4. 每张图必须同时满足：无绿色/调试外框；浅色页面上的状态栏时间、网络、电池清晰可见；主体布局未回归。
5. 用新的 `01`、`02` 重制 2 张直接双栏对照，不嵌套旧图。
6. 更新 `EXECUTION_RECORD.md` 和 `VISUAL_COMPARISON.md`：记录新 APK/截图哈希、系统栏明暗、角点像素检查、设备参数和对照结论。
7. 结束后恢复设备为 1080×2400、density 420、font scale 1.0。

## 6. 最终通过条件

- 深色状态栏图标在两页及 360dp/140% 图中清晰可见；
- 8 张正式图不存在亮绿色或其他人工外框；
- 页面主体保持 R2 已通过结构，无新视觉回归；
- 新 APK 哈希、8 张新截图哈希、2 张新对照和真实 API 记录齐全；
- 定向测试、analyze、两仓 diff 通过，设备参数恢复；
- 执行模型只提交 Plan 最终复验，不自行关闭 VR10 或进入 VR11。

## 7. 交给执行模型的精简提示词

执行 `D:\Football-APP-Front\reports\VR10_R3_SYSTEM_BAR_AND_CLEAN_EVIDENCE_PLAN.md`。页面主体已通过，本轮只允许：在设置主页和账号安全页增加局部浅色 `SystemUiOverlayStyle`，确保状态栏图标为深色；补对应 F19 断言；查明并关闭截图链路产生的约 4px 亮绿色外框。不得改布局、业务、后端、数据库或其他页面。测试/analyze/diff 通过后，在普通 Windows Terminal 重建新 APK，禁止复用 `B972...66A8`；使用无叠加层的 Android 原生截图链路重采 8 张图、重制 2 张直接对照。每张图须验证状态栏清晰且角点不是 RGB `171,212,47`。记录新哈希并恢复设备参数，只提交 Plan 最终复验，不进入 VR11。
