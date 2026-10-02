# VR10 设置与账号安全视觉对照（VR10-R3 当前 APK）

## comparison_01_settings.png

- 左栏：`我的-设置.png` 原型原图。
- 右栏：`01_settings.png`，当前 APK 标准设备截图。
- 目标结构：返回入口、居中标题、四项分组入口、分隔线、独立退出登录块。
- 实测：设置页右箭头 0 个；四项图标分别为盾牌、齿轮、通知铃、语言；分隔线从页面约 25dp 延伸至分组右边界；退出块左右约 24dp、上间距约 24dp。
- 平台差异：右栏保留 Android 系统状态栏/导航栏，原型为 iOS 状态栏；不计入业务布局偏差。

## R3 纯净截图与系统栏检查

- 两张右栏均来自 APK `E2C4B823A39D9D8B692FD1113B7226C23D0FC149DA0BE0DFCAC18D260B0736E4` 的原生 `adb exec-out screencap -p` 截图。
- 设置页和账号安全页状态栏时间、网络、电池图标均为深色；页面局部 `SystemUiOverlayStyle` 同时保持浅色导航栏和深色手势条。
- 8 张 R3 正式图四边均未发现 `RGB 171,212,47`；该 RGB 的四边精确像素计数均为 0。
- `comparison_01_settings.png` 与 `comparison_02_account_security.png` 是原型原图 + 当前 APK 原始截图的直接双栏合成，不含旧 comparison 嵌套。

## comparison_02_account_security.png

- 左栏：`我的-设置-账号与安全.png` 原型原图。
- 右栏：`02_account_security.png`，当前 APK 标准设备截图。
- 目标结构：返回入口、居中标题、手机号/修改密码/注销账号三行、分隔线、右侧状态与箭头。
- 实测：账号安全页右箭头 3 个；三行保持单行；标签从分组左侧约 25dp 起；右侧状态与箭头保持靠右；手机号按真实状态显示“未绑定”。
- 平台差异：右栏保留 Android 系统状态栏/导航栏，原型为 iOS 状态栏；不计入业务布局偏差。

## 响应式证据

- `05_360dp_settings.png`、`06_360dp_account_security.png`：实际设备尺寸 945×2400、density 420，换算为 360dp 宽，无可见溢出或遮挡。
- `07_140_percent_settings.png`、`08_140_percent_account_security.png`：实际 font scale 1.4，无可见溢出、遮挡或不可点击控件。
