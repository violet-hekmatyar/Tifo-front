# VR10-R2-E1 Android 证据执行记录

日期：2026-09-28

## APK 与设备

- APK：`apps/mobile/build/app/outputs/flutter-apk/app-debug.apk`
- 构建时间：`2026-09-28 14:56:29`
- 大小：`213458745` 字节
- SHA-256：`B972383FA04EA751884C1227B6D2640F0CC539CDA5E82A3AC57EEB219ECE66A8`
- 设备：`emulator-5554`，安装后设备内 APK SHA-256 与构建产物一致
- 最终恢复参数：1080×2400、density 420、font scale 1.0

## 真实 API 与交互

- 使用已有 DEMO 账号正常登录，未创建账号、未写入数据库。
- `GET /api/auth/me`：HTTP 200、`code=0`，`onboardingCompleted=true`。
- 账号安全页按真实返回展示手机号状态“未绑定”，未显示完整手机号。
- 已验证设置入口、账号与安全进入/返回、修改密码“暂未开放”和退出确认取消。
- 未执行真正退出、密码修改、注销账号或任何敏感写操作。

## 正式证据

| 文件 | SHA-256 |
|---|---|
| `01_settings.png` | `0526E42A1655B62376888454600063D1328BEFCFBDBB24299D60AC10DADA74F3` |
| `02_account_security.png` | `9A4DB4F67F252455BA4C2091C5CA5783D57D601B7CC0047D9105C100FF0133BA` |
| `03_unavailable_feedback.png` | `482D5D238308D9A2AB452A3F280CC1244AB87EE0F6EDBB2653A06B26FE9B8E76` |
| `04_logout_confirm.png` | `0BB3AA1EDB453C213EF6B3C975429D93FB68A0757D9D738C75EAEFB6B8E73023` |
| `05_360dp_settings.png` | `35B6B818F976984F44A97207858A1D721992F43F0626674838185778866D6B25` |
| `06_360dp_account_security.png` | `C7FDDD04C1E9A1DA9D7CD72469C81F4E1BF632723FDB150AA82A914A5DA5B477` |
| `07_140_percent_settings.png` | `0CF0D72ADFFCDEA620949ECAC258D52560E1CD19CC0AAD9B6BD54FA2C06C0A04` |
| `08_140_percent_account_security.png` | `0B23B6D28A70996D42CEF7FA4B725D37E05139F3613806A6F8C72FA0A6745144` |

## 直接双栏对照

- `comparison_01_settings.png`
- `comparison_02_account_security.png`

两张对照图均由对应原型原图与当前 APK 的标准原始截图直接组成，不使用旧 APK、旧截图或嵌套 comparison。

## VR10-R3 系统栏与纯净证据收口（2026-09-28）

### 源码与 APK

- 设置主页和账号安全页增加局部 `AnnotatedRegion<SystemUiOverlayStyle>`；状态栏和导航栏使用浅色背景、深色图标，不使用全局 `SystemChrome`。
- F19 新增两项局部系统栏断言；设置、认证和路由定向测试共 23 项通过，`flutter analyze --no-pub` 通过。
- 普通 Windows Terminal 从当前源码生成新 APK，构建时间：`2026-09-28 16:13:36`。
- APK 大小：`213456777` 字节。
- APK SHA-256：`E2C4B823A39D9D8B692FD1113B7226C23D0FC149DA0BE0DFCAC18D260B0736E4`。
- 该哈希不同于 R2-E1 的 `B972...66A8`，并已安装到 `emulator-5554`。

### 设备与采集链路

- ADB：`C:\Users\hekmatyar\AppData\Local\Android\Sdk\platform-tools\adb.exe`。
- 截图全部使用 Android 原生 `adb exec-out screencap -p` 原始像素生成；未裁剪、涂色或嵌套旧截图。
- 采集前确认未启用布局边界、触摸点、指针位置、检查器或放大叠加层。
- 设备最终恢复为：1080×2400、density 420、font scale 1.0。

### R3 正式截图哈希与边缘检查

| 文件 | 尺寸 | SHA-256 | `171,212,47` 四边精确像素 |
|---|---:|---|---:|
| `01_settings.png` | 1080×2400 | `3EDFA46D792508FEB0799C316F63D023C689B688149C16E021BAC169130B7218` | 0 |
| `02_account_security.png` | 1080×2400 | `9ADC36344F69370923B650E999839EE2C974470512D2310EB1762B8C8C6803CB` | 0 |
| `03_unavailable_feedback.png` | 1080×2400 | `57AD1F345E8D8E98158843B3EFA3071E2CE5382801E60764C177493F8814F2B4` | 0 |
| `04_logout_confirm.png` | 1080×2400 | `005B2C285A1EA757679187BA96FB19121CA3C209E3D10F1DA5B64F384FB8833F` | 0 |
| `05_360dp_settings.png` | 945×2400 | `A66AEEABF1300DC2A94C9C2CDEFF99140C9DDEA7D1321413D4201D6028A9EAF0` | 0 |
| `06_360dp_account_security.png` | 945×2400 | `A600473619B76CCCB3D40C3B5F7F653D3A8683B50BB0BFBE27DDFE5CD9E0C307` | 0 |
| `07_140_percent_settings.png` | 1080×2400 | `EF1995531BF71BEA014E2D5AA200D32FB60A2C85418514BDED6D7A05163B53CC` | 0 |
| `08_140_percent_account_security.png` | 1080×2400 | `C273AA5CDF4829CE65617DEDC8477F784C94438A64E3068B57B49830607EC113` | 0 |

- `01`、`02`、`05`、`06`、`07`、`08` 四角均为页面背景色 `245,247,246`。
- `03` 底部角点为 Snackbar 的深色背景，`04` 四角为退出确认遮罩；二者均无目标亮绿色外框。
- 两张对照图已使用 R3 当前 APK 原始截图重制：`comparison_01_settings.png`、`comparison_02_account_security.png`。

### 真实交互复核

- 已沿用已有 DEMO 登录态；`GET /api/auth/me` 保持 HTTP 200、`code=0`，页面显示“未绑定”，未记录密码或 token。
- 已重采设置主页、账号安全、修改密码“暂未开放”、退出确认、360dp 和 140% 字体证据；未执行真正退出、密码修改、注销或数据库写操作。
- VR10-R3 现已提交 Plan 模型进行最终证据复验；执行模型不自行关闭 VR10 或进入 VR11。
