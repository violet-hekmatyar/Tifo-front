# VR8 执行记录

## 范围

本轮仅覆盖搜索空态、选择主队、关注球队、关注球员，以及必要的媒体 URL 修复和响应式证据。未修改后端 Java、API 契约或数据库结构，未进入 VR9。

## 模块结果

- M0：完成原型尺寸/状态映射、真实 options 目标冻结和基线记录。
- M1：12 条目标媒体 URL 通过幂等 Seed、Validator 和保护式 Rollback 规则；6 队、6 人均来自真实 options，复用 P1 三张 PNG。
- M2：真实 `code=0`、无结果搜索在 Android 上显示白色搜索页、绿色搜索插画和“搜索无结果”，结果筛选条隐藏。
- M3：三步引导使用真实 options 和真实队徽/头像；主队单选自动进入球队步骤，球队/球员多选，返回保持，提交后进入首页。
- M4：独立验收账号完成真实登录、偏好提交和 API 回读；标准尺寸、360dp、140% 字体证据完成。360dp 下“上一步”保持单行且按钮可达。
- M5：同一最终 APK 生成正式截图和真实原型/实机并排对照图，设备尺寸恢复为 1080×2400、font scale=1.0。

## 验证

- Flutter 定向测试：63 项，全部通过。
- `flutter analyze`：通过。
- 前端仓库、后端仓库 `git diff --check`：通过。
- `smoke-onboarding.ps1 -Port 8080`：通过；options=6 teams/6 players，preferences、`auth/me` 回读、六队关注和无 token 错误均通过。
- M1 Validator：目标球队 6、目标球员 6；非目标媒体泄漏 0/0；12 行目标 URL 正确。
- Android 媒体：正式 after 截图中显示真实队徽和球员头像，不使用首字母正常态占位。
- APK SHA-256：见 `APK_HASH.txt`。

## 证据

正式文件为 `00_before_*`、`01_*`～`08_*`、`comparison_01_search_empty.png`～`comparison_04_followed_players.png`。过程 XML/登录及中间截图保留在同一目录，正式证据均来自当前最终 APK；密码和 Token 未写入报告。

## 结论

执行模型已完成 VR8 范围内实现与证据收口，现提交 Plan 模型进行独立验收；不自行宣布 VR8 通过，也不进入 VR9。
