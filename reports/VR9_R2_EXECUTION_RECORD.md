# VR9-R2 用户中心像素收口执行记录

日期：2026-09-25

状态：**代码、测试和数据验证完成；等待普通 Windows Terminal 构建 R2 APK；VR9 未关闭；不得进入 VR10。**

## 已完成

- 资料头统计改为头像右侧、昵称下方的三项内联信息组。
- 用户中心资料头局部蒙层调整为深青色 `#143A3B`，不修改全局品牌色。
- 看台卡收紧图标、预览图、内边距和卡间节奏；保留真实实体数据和路由。
- 用户中心内容卡移除首页式“帖子”角标，使用用户中心专用媒体比例；首页默认卡片行为不变。
- 关系页搜索框、行高、按钮和 Tab 分隔线收口；关系按钮不再固定为 `92×40dp`。
- 关系页使用独立滚动控制器保存关注/粉丝 Tab 的滚动位置。
- 新增 VR9-R2 资料头、关系页、用户中心卡片和 360dp 几何断言。

## 验证

- 用户中心原有测试及 VR9-R2 定向测试：57 项通过。
- `flutter analyze`：通过。
- R1 Seed 连续执行两次，结果一致：本人内容 8、公开用户内容 9、媒体 12、球队关注 3、球员关注 3。
- Validator 在两次 Seed 后分别执行并通过：正文块 12、媒体 12、VR9-M1 关系 20，非 DEMO 泄漏为 0。
- R1 Seed/Validator 仅增加保护断言，没有新增业务数据、API 或数据库结构。

## 当前阻塞

R2 新 APK 构建在 Codex 进程和子 PowerShell 中均失败：

```text
java.io.IOException: Unable to establish loopback connection
```

因此尚未使用 R1 APK 采集 R2 证据，也未更新 R2 APK 哈希。必须在普通 Windows Terminal 中执行：

```powershell
$ErrorActionPreference = 'Stop'
Set-Location -LiteralPath 'D:\Football-APP-Front'
& 'D:\Football-APP-Front\scripts\vr9_build_apk.ps1'
```

构建成功后，执行模型继续安装新 APK，采集 10 张 R2 截图、5 张 `375×812dp` 双栏对照图和完整量测表；完成后提交 Plan 模型复验，不自行关闭 VR9。
