# VR12 执行记录

日期：2026-09-29

## 当前范围

本阶段仅处理现有用户名密码登录页与协议确认弹层；未修改后端、数据库、API、Repository、认证字段、路由契约或其他页面。

## 已完成

- 登录页改为绿色品牌区 + 全宽白色底部操作面板，保留用户名、密码、显隐、校验、登录和注册入口。
- 品牌区使用现有足球图标和代码绘制的低对比方格纹理，没有引入截图背景或新依赖。
- 协议交互改为居中白色圆角 Dialog，包含“不同意 / 同意”分栏；关闭、不同意不发起登录请求，同意后沿用原 `AuthController.login`。
- 注册页继续复用同一协议行为，未改注册页业务结构。
- 新增 `vr12_login_visual_test.dart`，覆盖禁用入口、绿色区/白色面板几何、协议 Dialog 几何、零请求/单次请求、busy、360dp、140% 字体、错误反馈和输入保留。

## 定向验证

- VR12 新增测试：5 项通过；R1 新增页脚几何测试 1 项。
- 既有 auth 登录/注册/引导视觉回归及 `auth_redirect_test.dart`：29 项通过。
- 本轮 R1 定向测试合计：35 项通过。
- `flutter analyze --no-pub`：通过。
- `git diff --check`：通过；仅有既有 LF/CRLF 警告。

## M6 Android 证据

已使用普通 Windows Terminal 构建并安装当前源码 APK，完成 8 张正式 Android 截图和 2 张直接双栏对照。证据目录为：

`D:\Football-APP-Front\reports\VR12_EXISTING_ACCOUNT_LOGIN_VISUAL_PARITY_EVIDENCE`

APK：`D:\Football-APP-Front\apps\mobile\build\app\outputs\flutter-apk\app-debug.apk`

- 构建时间：2026-09-29 17:32:44
- 大小：213,472,172 bytes
- SHA-256：`C47D49A76012463AABB623E576F3F1D146E9AE0EA6C5FA3AD752BB5FA81C7652`
- 标准参数：1080×2400、density 420、font scale 1.0
- 360dp 参数：945×2400、density 420、font scale 1.0；`945 / 420 × 160 = 360dp`
- 字体参数：1080×2400、density 420、font scale 1.4
- 采证完成后已恢复标准设备参数并停止应用。

使用已有演示账号完成了真实登录接口和 `auth/me` 只读验证，均为 HTTP 200、`code=0`；不在报告中记录密码或 Token。Android 证据保留无效测试输入的真实错误反馈，不声称已完成成功路由截图。

## 当前交付状态

VR12-R1 已完成代码返修、定向验证和同 APK Android 证据重采，现提交 Plan 模型复验。本执行模型不宣布 VR12 通过，也不进入 VR13；视觉是否正式关闭以 Plan 模型复验为准。
