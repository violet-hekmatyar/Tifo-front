# VR8-R2-E1 视觉与对照记录

## 几何结果

| 项目 | 原型目标 | 当前实现/测试 | 结果 |
| --- | ---: | ---: | --- |
| 搜索框高度 | 39.36dp | 40dp | 通过，误差约 1.6% |
| 搜索框相对 AppBar 顶部 | 内容相对锚点 | 8dp | 严格测试通过 |
| 空态插画 | 57.6dp | 58dp | 通过，误差约 0.7% |
| 空态组相对白态视图顶部 | 约 213.3dp | 严格 ±8% | 通过 |
| 主队首卡相对白面板顶部 | 48.48dp | 约 49dp | 通过，误差约 1.1% |
| 选择卡视觉卡体 | 60.96dp | 约 61dp | 通过 |
| 卡间节奏 | 38.88dp | 39dp | 通过 |

E1 的状态栏混入绝对 Y 失败已改为 AppBar、白面板和空态视图相对坐标；没有修改已处于容差内的头部或首卡锚点。

## 直接双栏对照

固定 APK：`AA726522D8A9AFC6FD6CBA3A9EAC609E521D18E00DABE6C2FF74A991228798F9`

| 对照图 | 左侧原型原图 | 右侧当前 APK 原始截图 | 对照规则 | 结果 |
| --- | --- | --- | --- | --- |
| `comparison_01_search_empty.png` | `C:\Users\hekmatyar\Desktop\足球APP\搜索结果空.png` | `00_search_empty.png` | 等宽缩放，保持比例 | 已重制 |
| `comparison_02_main_team.png` | `C:\Users\hekmatyar\Desktop\足球APP\选择主队.png` | `01_main_team.png` | 等宽缩放，保持比例 | 已重制 |
| `comparison_03_followed_teams.png` | `C:\Users\hekmatyar\Desktop\足球APP\选择球队.png` | `02_followed_teams.png` | 等宽缩放，保持比例 | 已重制 |
| `comparison_04_followed_players.png` | `C:\Users\hekmatyar\Desktop\足球APP\选择球员.png` | `03_followed_players.png` | 等宽缩放，保持比例 | 已重制 |

每张图只有“原型 Prototype”和“当前 APK Current APK”两栏；未把旧 comparison 或其他合成图作为输入，未裁剪核心内容。

## 证据文件

- `00_search_empty.png`：完成 onboarding 账号从正常全局搜索路由进入，真实空结果状态。
- `01_main_team.png`、`02_followed_teams.png`、`03_followed_players.png`：同一固定 APK 的标准宽度实机图。
- `04_360dp_players.png`：同一 APK、945×2400、density 420，对应 360dp。
- `05_140_percent_players.png`：同一 APK、font scale 1.4，未见溢出或遮挡。
- `debug/`：仅保存登录过程、调试截图和 XML，不作为正式证据。

## 结论口径

本记录完成 E1 的证据补正，不改变 VR8-R2 已通过的几何结果。最终是否关闭 VR8，交由 Plan 模型复验。
