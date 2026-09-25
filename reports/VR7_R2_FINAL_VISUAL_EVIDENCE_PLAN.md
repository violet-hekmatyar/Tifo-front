# VR7-R2 发布编辑器最终视觉与证据收口计划

状态：**已完成并通过 Plan 最终复验；VR7 已关闭**  
依据：`reports/VR7_R1_REVIEW_2026-09-22.md`  
目标：在不修改后端、数据库和 API 契约的前提下，关闭帖子空态纵向几何、话题搜索前缀、关键截图和完整定向回归四项遗留。

## 1. 范围冻结

允许修改：

- `apps/mobile/lib/features/content/presentation/pages/publish_post_page.dart`
- `apps/mobile/lib/features/content/presentation/pages/publish_auxiliary_page.dart`
- 两个页面直接相关的 Widget/几何/响应式测试
- VR7 执行记录、视觉对照和证据目录

禁止修改：

- 后端 Java、数据库表、Migration、Seed、Validator、Rollback 和现有数据
- 内容详情生产布局、Feed、首页及其他页面族
- 已冻结的 TOPIC/HOT_EVENT API、发布请求和关系回读契约
- 图片格 76～84dp、文章空态、热点列表和现有真实交互

## 2. 顺序模块

### R2-A：帖子空态与填写态几何收口

1. 压缩空草稿正文区的固定最小高度，使图片添加格在标准设备上紧接正文提示区域，不再落到页面中部；已有文字时仍自然增长并可滚动。
2. 保持图片格约 76～84dp、真实缩略图、右上角删除按钮、第二个添加格和底部图片工具不变。
3. 增加几何断言：空态图片格位于正文提示之后且间距不超过一个常规模块间距；不得只断言控件存在。
4. 填写态测试使用自然中文标题和至少两行正文，覆盖缩略图、话题、热点同时存在时无重叠和不可达控件。

完成门槛：帖子空态的首屏纵向节奏接近原型，填写态具备原型相当的信息密度，标准、360dp 和 140% 字体均无 overflow。

### R2-B：话题搜索前缀小修

1. 将话题搜索框前缀调整为紧凑的“搜索图标 + 绿色 `#`”组合；不得增加新输入框或改变现有搜索行为。
2. 保持热门标题、编号、讨论数、列表密度、API 数据及错误/重试逻辑不变。
3. 增加 Widget 断言，确认搜索图标与话题 `#` 同时存在，热点页仍没有搜索框。

完成门槛：话题页的搜索语义和原型一致，热点页不回归。

### R2-C：纠正正式证据

从本轮最终源码重新构建并安装一个 APK，记录完整 SHA-256。以下 9 张正式截图和 5 张 comparison 必须全部来自该 APK：

- `01_post_empty.png`
- `02_post_filled.png`：自然中文标题/正文、真实缩略图、话题和热点同时可见
- `03_article_empty.png`
- `04_topic_picker.png`
- `05_hot_event_picker.png`
- `06_width_360dp.png`
- `07_font_140.png`
- `08_published_detail_relations.png`：在真实发布详情向下滚动，画面必须实际看到 TOPIC/HOT_EVENT 两个关系标签
- `formal_06_post_both_relations.png`：必须是帖子编辑器，不得再截成首页；画面同时看到缩略图、话题和热点

重新生成 `comparison_01`～`comparison_05`。`VISUAL_COMPARISON.md` 必须逐图记录结构、纵向起点、图片比例、字体/颜色、剩余差异和结论，且文件描述必须与实际画面一致。

若详情接口有两条关系但详情页滚动后仍不显示，先停止并报告真实响应和客户端解析结果；不得伪造标签、改接口或用文字说明冒充截图。

完成门槛：不存在错页、错名、旧 APK、英文测试文案或画面不可见却由报告宣称可见的证据。

### R2-D：完整最小回归与提交复验

必须运行原计划 7 个基线测试文件：

- `f12_publish_composer_widget_test.dart`
- `f11_article_flow_widget_test.dart`
- `article_editor_controller_test.dart`
- `f05_publish_return_route_test.dart`
- `f05_controllers_test.dart`
- `f11_content_api_test.dart`
- `f11_article_body_test.dart`

并运行：

- `f17_publish_subject_test.dart`
- 本轮修改的几何与响应式测试

总通过数不得低于 51 项，执行记录需列出命令、文件及各自数量。另执行：

1. `flutter analyze`；
2. 真实 API 只读 smoke：TOPIC、HOT_EVENT、验收内容详情均 `HTTP 200 + code=0`，详情确有两条关系；
3. 前后端 `git diff --check`；
4. 核对 9 张正式图、5 张 comparison 和 `APK_HASH.txt` 的 APK 哈希一致；
5. 实际确认 360dp 与 140% 字体交互后恢复设备参数。

不重新 Seed，不重复创建验收内容，不执行 Rollback。

## 3. VR7 最终完成定义

以下条件必须全部满足：

- 帖子空态图片格纵向位置与原型接近；
- 帖子填写态使用自然中文，真实缩略图和双关联可见；
- 话题搜索前缀同时包含搜索图标与绿色 `#`；
- `formal_06` 是真实编辑器双关联画面；
- `08` 实际拍到详情关系标签；
- 9 张正式图和 5 张 comparison 来自同一最终 APK；
- 不少于 51 项定向测试、analyze、API smoke 和两仓 diff 全部通过；
- 后端、数据库、API、Seed 和非 VR7 页面无改动。

完成后只提交 Plan 模型复验，不自行宣布 VR7 通过，也不进入 VR8。

## 4. 交给执行模型的精简提示词

严格执行 `D:\Football-APP-Front\reports\VR7_R2_FINAL_VISUAL_EVIDENCE_PLAN.md`。只做四件事：压缩帖子空态正文留白并补几何测试；把话题搜索前缀补成“搜索图标 + 绿色 #”；用同一新 APK 纠正 9 张正式图和 5 张对照图；运行原 7 个基线文件、F17 及本轮测试，总数不得低于 51。`formal_06` 必须是同时显示缩略图/话题/热点的帖子编辑器，`08` 必须滚动到真实详情关系标签。禁止修改后端、数据库、API、Seed、内容详情生产布局或其他页面；不重复造数据、不执行 Rollback。完成后仅提交 Plan 复验，不进入 VR8。

## 5. Plan 复验结论（2026-09-22）

R2-A、R2-B、53 项测试、详情关系截图及其他同 APK 证据有效。唯一剩余项为双关联编辑器的自然中文标题/正文填写态；后续唯一执行入口为 `reports/VR7_R2_E1_CHINESE_EVIDENCE_PLAN.md`，不得继续修改生产代码。
