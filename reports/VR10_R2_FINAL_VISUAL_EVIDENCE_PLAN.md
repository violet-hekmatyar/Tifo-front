# VR10-R2 设置页最终小修与证据收口计划

状态：**源码已通过 Plan 复验；转入 VR10-R2-E1 纯 Android 证据补正，禁止继续改生产代码**  
目标：关闭设置主页右箭头和分隔线几何两项最后差异，再从普通 Windows Terminal 构建同一 APK 完成视觉证据。

## 1. 严格范围

只允许修改：

- `apps/mobile/lib/features/user_center/presentation/pages/settings_pages.dart`
- `apps/mobile/test/features/user_center/f19_settings_acceptance_test.dart`
- VR10 执行记录与视觉证据目录

不得修改后端、数据库、手机号脱敏契约、退出登录行为、账号安全三项行为或任何其他页面。

## 2. R2-M0：先补失败断言

1. 设置主页单独渲染时，断言 `chevron_right_rounded` 数量为 0。
2. 账号安全页单独渲染时，断言 `chevron_right_rounded` 数量为 3。
3. 为分隔线的实际 RenderBox 设置稳定 Key，并在 375×812dp 下断言：
   - 页面左边约 x=25dp；
   - 页面右边约 x=365dp；
   - 宽约 340dp；
   - y 坐标分别落在各 50dp 行的边界。
4. 以上断言必须在当前 R1 代码上失败，再进入生产代码修改。

## 3. R2-M1：两项最小修复

1. 从设置主页 `_FixedEntry` 移除右箭头，仅保留左侧图标和标题；点击热区、四行高度和暂未开放行为不变。
2. 账号安全 `_SecurityEntry` 保留右箭头，不改变手机号和值的右对齐。
3. 分隔线改为分组内左约 15dp、右约 0dp，对应页面约 x=25～365dp；两页使用相同原型几何。
4. 不调整标题、图标、退出块、页面背景、手机号字段和其他已通过尺寸。

完成门槛：R2-M0 新断言和现有全部 F19 测试通过。

## 4. R2-M2：回归与最终 APK

1. 运行 F19 设置测试及既有认证/路由定向回归，记录准确通过项数。
2. 运行 `flutter analyze` 与前后端 `git diff --check`。
3. Codex 环境仍出现 Java loopback 故障时，不重复无效构建；在普通 Windows Terminal 使用当前最终源码构建 APK，禁止复用旧 APK，记录完整 SHA-256。
4. 安装同一 APK，使用真实登录态和脱敏手机号采集：
   - `01_settings.png`
   - `02_account_security.png`
   - `03_unavailable_feedback.png`
   - `04_logout_confirm.png`
   - `05_360dp_settings.png`
   - `06_360dp_account_security.png`
   - `07_140_percent_settings.png`
   - `08_140_percent_account_security.png`
5. 生成两张原型/当前 APK 直接双栏对照；不得使用旧图、fixture 或嵌套 comparison。
6. `VISUAL_COMPARISON.md` 必须记录：设置页无右箭头、账号页 3 个箭头、分隔线 x/宽、标题、分组、退出块和账号行位置。
7. 证据不得出现完整手机号、Token 或密码；设备结束后恢复 1080×2400、density 420、font scale 1.0。

## 5. 最终通过条件

- 设置主页无右箭头，账号安全页恰有 3 个右箭头；
- 5 条分隔线的起止位置与原型一致；
- F19、认证/路由回归、analyze 和两仓 diff 通过；
- 8 张正式图、2 张直接双栏对照和同 APK 哈希齐全；
- 执行模型只提交 Plan 最终复验，不自行关闭 VR10 或进入 VR11。

## 6. 交给执行模型的精简提示词

执行 `D:\Football-APP-Front\reports\VR10_R2_FINAL_VISUAL_EVIDENCE_PLAN.md`。只做两项代码小修：移除设置主页四行右箭头，但保留账号安全页 3 个右箭头；将两页分隔线调整到页面约 x=25～365dp。先补在当前代码失败的箭头数量和分隔线矩形断言，再修改生产代码。不得改后端、数据库、脱敏字段、退出登录或其他页面。完成 F19/认证/路由定向测试、analyze、两仓 diff 后，在普通 Windows Terminal 构建当前源码 APK，采集 8 张正式图与 2 张直接双栏对照，记录完整 SHA-256 并恢复设备参数。只提交 Plan 最终复验，不进入 VR11。
