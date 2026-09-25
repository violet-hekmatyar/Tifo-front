# P2-M0 构建、安装与新鲜截图验收记录

日期：2026-09-17

## 构建基线

- 前端提交：`16c640e0d0d892a4f0d1053fd3ae2452b63ccc5d`
- `apps/mobile/lib`：无未提交改动
- Flutter：`3.44.6`
- JDK：Temurin `17.0.19`
- Gradle：`9.1.0`
- Android 设备：`emulator-5554`，Android 16 / API 36

## 当前源构建

普通 Windows PowerShell 中使用同一套参数连续构建两次，均成功：

```text
flutter build apk --debug --dart-define=APP_ENV=development --dart-define=API_BASE_URL=http://10.0.2.2:8080
```

最终 APK：`D:\Football-APP-Front\apps\mobile\build\app\outputs\flutter-apk\app-debug.apk`

- 最后修改时间：`2026-09-17 17:56:55 +08:00`
- 文件大小：`187904767` bytes
- SHA-256：`572A4A63C1EE35F7035708D6CF9E47B80329B509C9A83B53E215C9F7EBA99E4E`

## 安装与运行

- `adb reverse tcp:8080 tcp:8080`：成功
- `adb install -r`：成功
- 包名：`com.southstand.tifo`
- 应用启动后首页 API 请求成功，未再出现“请求失败”弹窗
- 新鲜首页截图：[01_home_baseline.png](01_home_baseline.png)

## M0 结论

- [x] 连续两次当前源 debug APK 构建成功
- [x] 当前源 APK 可安装并启动
- [x] 已记录源码、APK 时间、文件大小和 SHA-256
- [x] 未升级依赖或修改业务代码
- [x] 已生成 Android 新鲜首页基线截图

结论：P2-M0 完成，可以进入 P2-M1。
