# VR12 Android 证据执行记录

日期：2026-09-29

## APK

- 路径：`D:\Football-APP-Front\apps\mobile\build\app\outputs\flutter-apk\app-debug.apk`
- 构建时间：2026-09-29 17:32:44
- 大小：213,472,172 bytes
- SHA-256：`C47D49A76012463AABB623E576F3F1D146E9AE0EA6C5FA3AD752BB5FA81C7652`
- 8 张正式截图和 2 张 comparison 均来自该 APK。

## 设备证据

| 文件 | 设备参数 | 尺寸 | 说明 |
|---|---|---:|---|
| `01_login_empty.png` | 1080×2400 / density 420 / font 1.0 | 1080×2400 | 标准空态 |
| `02_login_filled.png` | 1080×2400 / density 420 / font 1.0 | 1080×2400 | 填写态，密码保持遮蔽 |
| `03_agreement_dialog.png` | 1080×2400 / density 420 / font 1.0 | 1080×2400 | 居中协议弹层 |
| `04_agreement_accepted.png` | 1080×2400 / density 420 / font 1.0 | 1080×2400 | 同意后继续登录，错误反馈保留 |
| `05_width_360dp.png` | 945×2400 / density 420 / font 1.0 | 945×2400 | `945 / 420 × 160 = 360dp` |
| `06_width_360dp_dialog.png` | 945×2400 / density 420 / font 1.0 | 945×2400 | 360dp 协议弹层 |
| `07_font_140.png` | 1080×2400 / density 420 / font 1.4 | 1080×2400 | 140% 字体空态 |
| `08_font_140_dialog.png` | 1080×2400 / density 420 / font 1.4 | 1080×2400 | 140% 字体协议弹层 |

截图均在关闭调试布局/脏区域绘制后采集，无人工边框；填写态没有在记录中保存明文密码。协议页脚位于注册入口之后，标准截图中页脚中心约为页面高度 91.7%；未选/已选选择器为 20dp 圆形。`comparison_01_login.png` 与 `comparison_02_agreement_dialog.png` 为原型原图和当前 APK 原始截图的直接双栏合成。

## 真实链路

- 使用已有演示账号进行只读认证验证：登录接口 `HTTP 200 / code=0`，随后 `auth/me` 为 `HTTP 200 / code=0`。
- 账号和密码未写入报告，Token 未写入报告或文件。
- Android 截图中的错误反馈使用无效测试输入验证；成功 API 路径已通过，但本轮未将成功后的受保护页截图纳入 VR12 证据。

## 设备恢复

采证完成后已恢复：1080×2400、density 420、font scale 1.0，并停止应用进程。
