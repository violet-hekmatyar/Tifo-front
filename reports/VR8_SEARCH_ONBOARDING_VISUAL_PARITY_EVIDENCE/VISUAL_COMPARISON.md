# VR8 视觉对照记录

| 对照图 | 原型 | 当前 APK 实机 | 记录 |
| --- | --- | --- | --- |
| `comparison_01_search_empty.png` | 搜索结果空 | `01_search_empty.png` | 白色头部、居中搜索标题、圆角搜索框、绿色搜索插画和空态文字；真实无结果请求后隐藏筛选。 |
| `comparison_02_main_team.png` | 选择主队 | `02_main_team.png` | 绿色纹理沉浸头部、说明、搜索框、白色圆角结果面板、6 个真实队徽和固定下一步。 |
| `comparison_03_followed_teams.png` | 选择球队 | `03_followed_teams.png` | 选中主队显示红色实心爱心，球队步骤显示上一步/下一步和真实队徽。 |
| `comparison_04_followed_players.png` | 选择球员 | `04_followed_players.png` | 球员步骤显示真实头像、球队/位置副标题、灰色空心爱心和完成首次设置操作区。 |

## 响应式补证

- `06_width_360dp.png`：945×2400 物理像素，420 density 换算为 360dp；列表、底部按钮和“上一步”均可见，无溢出。
- `07_font_140.png`：标准宽度、font scale 1.4；标题、说明、卡片文字和操作区无遮挡或溢出。
- `05_selection_persisted_after_back.png`：从球员步骤返回球队步骤后，主队红色选中状态保持。
- `08_completed_home.png`：完成偏好提交后真实首页回读，顶部主队入口显示已选球队。
