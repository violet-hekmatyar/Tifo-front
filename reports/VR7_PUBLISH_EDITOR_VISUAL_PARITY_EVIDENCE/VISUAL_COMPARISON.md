# VR7-R2 同 APK 原型/实机视觉对照

当前证据 APK SHA-256：`01CE434E7D249F31D12E8D3918FF354634957598BA14AE9CD4DF0A09F251ADE0`

`comparison_01`～`comparison_05` 均由当前 APK 实机截图与对应原型重新合成，左侧为原型，右侧为实机；本文件只记录证据，不自行宣布 VR7 通过。

| 对照图 | 原型 | 当前 APK | 逐图核对点 |
| --- | --- | --- | --- |
| `comparison_01_post_empty.png` | `comparison_01_post_empty_prototype.png` | `01_post_empty.png` | 取消/发布头部、标题/正文留白、80dp 图片添加格、底部模式栏。当前实现保留绿色发布胶囊和紧凑图片格。 |
| `comparison_02_post_filled.png` | `comparison_02_post_filled_prototype.png` | `formal_06_post_both_relations.png` | 同时显示自然中文标题、两行以上中文正文、真实缩略图、`#英超焦点` 和 `热点 · 利雅得胜利宣布中国行延期`；右侧为当前 APK 未后处理实机截图。 |
| `comparison_03_article_empty.png` | `comparison_03_article_empty_prototype.png` | `03_article_empty.png` | 新建文章标题/正文留白、无 `关联 0/10` 大区块、紧凑关系入口和文章模式。 |
| `comparison_04_topic.png` | `comparison_04_topic_prototype.png` | `04_topic_picker.png` | 搜索前缀同时显示搜索图标和绿色 `#`，热门标题、编号、真实讨论数及列表密度保持。 |
| `comparison_05_hot_event.png` | `comparison_05_hot_event_prototype.png` | `05_hot_event_picker.png` | 无默认搜索框、标题后直接进入列表、约 78dp 缩略图、标题及两行摘要。 |

## 正式截图映射

- `formal_01_post_empty.png`：当前 APK 帖子空态；图片添加格已紧接正文提示区域。
- `02_post_filled.png`、`formal_02_post_filled.png`、`formal_06_post_both_relations.png`：同一次 Android 实机填写态采证；自然中文标题为“圣西罗夜场的压迫感从哪里开始”，正文为两行以上自然中文，画面同时显示真实缩略图、话题和热点。
- `formal_03_article_empty.png`：当前 APK 文章空态，无多余“关联 0/10”区块。
- `formal_04_topic_picker.png`：当前 APK 话题选择页，搜索图标与绿色 `#` 同时可见。
- `formal_05_hot_event_picker.png`：当前 APK 热点选择页，无搜索框。
- `formal_07_width_360dp.png`：945px 宽、density 420，`945 × 160 ÷ 420 = 360dp`。
- `formal_08_published_detail_relations.png`：固定内容 `16000000000000201` 的真实详情，实际显示 `# 英超焦点` 与 `# 国家队新一期名单`。
- `formal_09_font_140.png`：font scale 1.4；取消/发布保持单行。
- `APK_HASH.txt`：记录本次证据 APK 路径、哈希和构建时间。

## 当前状态

- 详情 API 为 `HTTP 200 + code=0`，真实关系为 `TOPIC:英超焦点`、`HOT_EVENT:国家队新一期名单`。
- 设备已恢复 `1080x2400`、density `420`、font scale `1.0`。
- VR7-R2-E1 已完成纯采证补正：三张正式填写态截图与 `comparison_02` 已用当前 APK 重采/重制；截图来自真实 Android 输入链路，未修改 APK、生产代码或测试。VR7 仍等待 Plan 模型最终复验，本文件不自行宣布通过。

## R1 数据保护核对

`VR7_M1_PUBLISH_SUBJECT_ROLLBACK.sql` 的保护条件为：

```sql
(r.remark IS NULL OR r.remark NOT LIKE 'VR7-M1-relation-%')
```

因此真实用户关系即使 `remark IS NULL` 也会触发保护式拒绝；本轮未执行回滚，不删除 VR7 目录、关系或既有用户数据。
