# VR8-R1 执行记录

日期：2026-09-23

## 完成项

- 搜索非选择模式改为浅灰填充、无外描边、无右侧提交箭头的紧凑输入框；选择模式的提交动作保留。
- 搜索空态插画缩小并锚定在剩余区域中上部，新增稳定 Key 和相对位置断言。
- 三步首次偏好页补齐原型量级文案、左对齐“搜索结果”、卡片尺寸/间距、真实头像/队徽、无图标“上一步/下一步”和局部系统栏样式。
- 末步按钮文案统一为“下一步”，继续调用原有 preferences 提交逻辑。
- `AppSelectionCard` 只增加可选视觉参数，默认调用行为保持不变。
- VR8 Rollback 改为球队 ID 与专属 crimson/cobalt URL 精确匹配；Validator 名称改为目标行范围内的准确语义；本轮未执行 Seed/Rollback 和任何数据库写入。

## 验证

- VR8 冻结定向集合：68 项通过。
- `flutter analyze`：通过。
- 前端与后端 `git diff --check`：通过。
- 数据库 Validator 只读执行：target_team_count=6、target_player_count=6、team_target_rows_not_in_vr8_targets=0、player_target_rows_not_in_vr8_target=0。
- 搜索空结果 API：HTTP 200，`code=0`，`records=[]`，`total=0`，`pages=0`。
- 三类 VR8 PNG：HTTP 200，`image/png`；未执行写入型 smoke。
- APK 双次构建并安装成功，完整哈希见 `APK_HASH.txt`。
- Android 设备采集了主队、关注球队、关注球员、360dp 和 140% 字体证据，并在采证后恢复标准设备参数。

## 采证边界

当前设备上的验收会话仍处于首次偏好选择页，未重复提交 preferences。搜索空态的本轮几何由同一最终源码的真实 Widget 布局测试和真实空结果 API 覆盖；未通过写入偏好强行切换到已认证首页/搜索路由。此前搜索页实机过程图不作为本轮正式 APK 证据。

## 结果

VR8-R1 代码与验证任务已完成，VR8 仍保持“待 Plan 模型复验”，本执行模型不自行宣布 VR8 关闭，也不进入 VR9。
