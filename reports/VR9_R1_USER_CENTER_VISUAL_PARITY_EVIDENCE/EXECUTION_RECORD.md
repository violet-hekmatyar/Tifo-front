# VR9-R1 Android 证据执行记录

日期：2026-09-24

## 固定构建

- APK：`D:\Football-APP-Front\apps\mobile\build\app\outputs\flutter-apk\app-debug.apk`
- SHA-256：`AAA8D9E23A8C228BC991D85BA93C52868110C60291D4334EE827CCEDD3A4239A`
- 设备：`emulator-5554`
- 应用包：`com.southstand.tifo`

## 已采证据

- 5 张标准尺寸页面截图：本人看台、本人发布、公开主页、关注、粉丝。
- 1 张公开主页真实关注状态变化截图。
- 2 张 360dp 截图：本人主页、关系页。
- 2 张 140% 字体截图：本人主页、关系页。
- 5 张直接双栏对照图；左侧为原型原图，右侧为当前 APK 原始截图，未嵌套旧 comparison。

## 验证结果

- 用户中心定向测试及 VR9-R1 测试：56 项通过。
- `flutter analyze`：通过。
- R1 Seed/Validator：幂等、保护式校验和非 DEMO 泄漏检查通过。
- 设备参数已恢复为 `1080x2400 / density 420 / font scale 1.0`。
- 密码、Token 和临时认证信息未写入证据目录。

本记录完成后停止在 VR9-R1，等待 Plan 模型复验；不进入 VR10。
