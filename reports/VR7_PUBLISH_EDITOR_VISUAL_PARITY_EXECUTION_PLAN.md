# VR7 发布编辑器与话题/热点选择一比一视觉复刻执行计划

状态：**M0～M6、R1、R2、E1 全部完成；VR7 已通过 Plan 最终复验**  
前置条件：VR6 已通过 Plan 最终复验  
唯一目标：以真实后端目录数据和真实发布请求，完成帖子/文章编辑器及话题/热点事件选择页 5 张原型的逐图复刻；消除当前“本地静态可选、发布时不入库”的假交互。

## 1. 本阶段原型范围

视觉基准仅为 `C:\Users\hekmatyar\Desktop\足球APP` 下列文件：

| 原型 | 对应状态 |
| --- | --- |
| `资讯主页-发布-帖子.png` | 帖子编辑初始态 |
| `资讯主页-发布-帖子(1).png` | 标题、正文、图片、话题和热点均已填写 |
| `资讯主页-发布-文章.png` | 文章编辑初始态 |
| `选择话题.png` | 话题搜索及热门列表 |
| `选择热点事件.png` | 热点事件列表及选择 |

`选择球队.png`、`选择球员.png` 和 `选择主队.png` 属于首次关注/主队引导，不是发布关系选择器，本阶段不处理。

本阶段还明确排除：独立 `搜索结果空.png`、内容详情/评论返修、首页、球队/球员/比赛详情、用户中心、登录协议弹层、设置、消息、手机号验证码、一键手机号登录、微信登录、私信、聊天、IM、WebSocket、Push 和完整淘汰树。不得顺手进入下一页面族。

## 2. 已确认现状与必须修复的契约缺口

执行模型不得把现状误判为已完成：

- `PublishAuxiliaryPage` 当前读取 `PublishLocalSource` 的静态话题/热点；它们不是 API 数据。
- `PublishPostPage` 虽能显示选中项，但 `PublishPostController.publish` 和 `ContentApi.createPost` 始终提交空 `relationList`。
- 后端 `ContentService` 目前只校验 `TEAM / PLAYER / MATCH`，不存在话题或热点事件目录模型、列表接口和名称解析。
- 文章请求已有通用 `relationList`，但创建页的现有关系状态只面向球队、球员和比赛。
- 当前帖子和文章编辑器是通用 Material 表单，头部、输入层级、图片格、关联入口和底部模式切换均未达到原型结构。

因此 VR7 必须同时完成最小后端目录能力、前端真实接入和视觉复刻。不得保留生产环境本地静态 fallback，也不得让选中标签只存在于页面内存。

## 3. 冻结的最小后端与数据方案

### 3.1 数据模型

新增一个项目自有、可复用的目录表 `content_publish_subject`，只表达两类对象：

- `TOPIC`：话题；
- `HOT_EVENT`：热点事件。

建议字段限定为：`id`、`subject_type`、`name`、`summary`、`cover_url`、`hot_score`、`sort_order`、`status`、`is_deleted`、`remark`、`create_time`、`update_time`。建立 `(subject_type, name)` 唯一约束及类型/状态/排序索引。不新建专用关联表，继续复用 `content_relation` 存储 `TOPIC / HOT_EVENT` 关系。

“讨论数”必须由有效 `content_relation` 的真实关联内容数聚合，不能写死几千、几万人等伪计数。热点封面复用 P1 已可匿名访问的 PNG 即可，不要求新增图片素材。

### 3.2 列表契约

只新增一个查询能力：

`GET /api/app/publish/subjects?type=TOPIC|HOT_EVENT&keyword=&pageNum=1&pageSize=20`

返回现有 `Result<PageResult<...>>` 外壳，每条仅包含：

- `subjectId`
- `subjectType`
- `name`
- `summary`
- `coverUrl`
- `discussionCount`

默认按 `hot_score DESC, sort_order ASC, id ASC`；关键词仅匹配名称/摘要；`pageSize` 上限 50。非法类型返回现有参数错误码。不要另造推荐、创建话题、热点详情或管理端接口。

### 3.3 发布契约扩展

- 扩展既有 `CreatePostRequest.relationList`、`ArticleRequest.relationList` 的校验，使其接受 `TOPIC / HOT_EVENT`，同时保持 `TEAM / PLAYER / MATCH` 行为不变。
- `TOPIC / HOT_EVENT` 必须验证目录对象存在、ACTIVE 且未删除；继续按 `type:id` 去重。
- 内容详情的 `relationName` 必须能解析两类新对象；发布后读取详情时可证明关联真实入库。
- 不改变帖子/文章响应结构、Feed 排序、候选上限、推荐逻辑或既有足球关系语义。

### 3.4 安全脚本与演示数据

后端仓库新增且只新增以下 VR7 数据产物：

- `scripts/sql/VR7_M1_PUBLISH_SUBJECT_MIGRATION.sql`
- `scripts/sql/VR7_M1_PUBLISH_SUBJECT_SEED.sql`
- `scripts/sql/VR7_M1_PUBLISH_SUBJECT_VALIDATOR.sql`
- `scripts/sql/VR7_M1_PUBLISH_SUBJECT_ROLLBACK.sql`
- `scripts/sql/VR7_M1_PUBLISH_SUBJECT_MANIFEST.md`

规则：

- Migration 只做 `CREATE TABLE IF NOT EXISTS` 等向后兼容 DDL，并同步更新 `scripts/sql/schema.sql` 的全新安装定义；禁止执行整个 `schema.sql`。
- Seed 至少准备 6 个自然足球话题和 6 个热点事件，使用独立 VR7 ID 段及 `VR7-M1-...` remark；热点图片复用 P1 PNG。
- 可给 P1-M3 的 DEMO 内容新增 VR7 专属 relation 行形成真实讨论数，但不得修改内容正文、封面、热度或既有 relation 行。
- 执行前检查表、ID 段、自然键和 remark 所有权；冲突时整体更换 VR7 段并记录 Manifest，禁止覆盖。
- Seed 与 Validator 各连续执行两次；第二次不得增加行。Validator 覆盖类型数量、图片 URL、关系目标、去重、聚合讨论数和非 VR7 数据泄漏为 0。
- 更新 `scripts/sql/validate-demo-data.sql`，让全库校验认识两个新关系类型；不得放宽对无效关系的检查。
- Rollback 只删除 VR7 关系和无人引用的 VR7 目录行；发现非 VR7 关系引用时必须拒绝删除，不得级联删除内容。为兼容后续发布内容，正常回滚不 DROP 新表。

## 4. 顺序执行模块

必须按 M0 → M6 顺序闭环。每个模块完成生产实现和直接验证后才能进入下一模块。

### VR7-M0：基线、原型测量与契约冻结

1. 运行以下 7 个现有测试文件并记录真实基线，当前静态统计为 **32 项**：
   - `f12_publish_composer_widget_test.dart`
   - `f11_article_flow_widget_test.dart`
   - `article_editor_controller_test.dart`
   - `f05_publish_return_route_test.dart`
   - `f05_controllers_test.dart`
   - `f11_content_api_test.dart`
   - `f11_article_body_test.dart`
2. 运行后端 `ContentServiceTests`，并记录话题/热点接口尚不存在的基线事实。
3. 测量 5 张原型的状态栏、头部、左右边距、标题线、正文起点、图片格、选择行、底部工具栏、Tab、搜索框和列表行几何。
4. 用当前 APK 保存帖子编辑器 before 截图；确认发布入口和返回链。

完成门槛：5 个状态映射、现有契约缺口和允许变更文件范围均已写入执行记录，未开始盲目改 UI。

### VR7-M1：真实话题/热点目录与后端关联

- 按第 3 节实现目录表、Mapper/Service/Controller/VO、列表查询、关系校验和名称解析。
- 新增定向后端测试，至少覆盖：两种类型分页/搜索/排序、非法类型、软删除过滤、真实讨论数、POST/ARTICLE 关联成功、无效 ID 拒绝、去重和既有三种关系不回归。
- 执行 Migration、Seed、Validator 双跑；验证热点 PNG 为匿名 `200 + image/png`。

完成门槛：真实 API 能稳定返回足够填满首屏的数据，发布服务能保存并回读两种新关系；无 P1～P3 数据覆盖。

### VR7-M2：Flutter 契约接入与草稿状态

- 新增发布目录 domain/API/repository/controller，严格解析第 3.2 节字段；支持 loading、failure、retry、empty、keyword 和分页去重。
- 移除生产代码对 `PublishLocalSource` 的依赖；测试 fixture 只能存在于测试目录。
- `ContentApi.createPost`、repository 和 controller 接受真实 `ContentRelationInput`，不得再固定提交空数组。
- 帖子和新建文章草稿均保存一个话题和一个热点事件；删除标签、放弃草稿、模式切换、发布 busy/失败都要保持一致。
- 文章现有球队/球员/比赛关系、文章编辑回读和 blocks 契约必须保留；不要用只适合搜索实体的 `SearchEntity` 强行承载新目录类型，可抽取小型通用草稿关系模型。
- 选择器 API 失败时显示重试，不回退静态数据；发布失败保留文字、图片和两个选择项。

完成门槛：POST 与 ARTICLE 请求体都能带真实 `TOPIC / HOT_EVENT`，详情回读名称一致，旧关系与文章编辑测试不回归。

### VR7-M3：帖子编辑器两态复刻

- 白色页面和深色状态栏；头部左侧“取消”、右侧绿色实心“发布”，移除居中的“发布帖子”通用标题。
- 标题使用原型的单行细分隔线和“请输入文章标题（20字内）”；新建内容按可见字符限制 20，错误就地提示。后端原有上限保持兼容，不收窄服务端契约。
- 正文为无边框大面积输入区，提示“请输入帖子内容”，不显示 Material label、外框或常驻计数器。
- 图片区使用原型方形缩略图和虚线/浅灰添加格；支持 0～9 张、删除、上传进度、失败重试和不同宽高裁切，不拉伸。
- 正文下方使用紧凑的 `# 添加话题` 和“关联热点事件”入口；选中后改为绿色可删除标签，文字过长须截断而非撑破布局。
- 底部保留真实可用的图片入口、帖子/文章模式切换和安全区。原型中的表情、@ 等当前契约不支持的按钮不得伪造为可用功能。
- 空态与填写态均须在同一最终实现中产生，禁止为截图写死文案、图片或选择项。

完成门槛：两张帖子原型分别有结构/几何测试，选择、图片、失败保留、取消确认和发布跳转均有效。

### VR7-M4：新建文章编辑初始态复刻

- `/publish/article` 的新建态使用与帖子一致的轻量编辑壳，底部“文章”选中；初始画面必须接近 `资讯主页-发布-文章.png`，不再首屏堆叠“摘要、封面、文章段落、关联内容”等管理表单。
- 大正文输入映射为 ARTICLE 的 TEXT block；添加图片映射为 IMAGE block，并延续现有上传所有权、清理和 `ARTICLE_BLOCKS` 请求。
- 话题/热点同样写入 ARTICLE `relationList`。摘要可由正文安全派生或留空；首张文章图片可作为封面，但不得复制上传或发明 URL。
- 编辑既有文章时继续保留封面、多个 blocks、顺序、既有关系回读及管理员复制媒体等能力；若需要保留高级编辑控件，应放在编辑态或明确的次级入口，不能破坏新建初始态原型。
- 帖子/文章切换有草稿时继续确认，确认放弃后清理临时文件；无草稿直接切换。

完成门槛：文章初始态有几何证据，真实创建请求仍为合法 ARTICLE，F11 文章查看、编辑、媒体和返回流程不回归。

### VR7-M5：话题与热点事件选择页复刻

共同结构：白色全屏页、左侧返回、居中标题、浅灰圆角搜索框、无卡片阴影的紧凑列表；点击有效行立即返回并更新编辑器，不保留现有深色 AppBar 和“完成”按钮结构。

话题页：

- 标题为“选择话题”，搜索提示为“搜索话题”；
- 使用真实热门顺序和真实讨论数，前几项可按原型突出序号/热度，但不得伪造计数；
- 行内名称、摘要/讨论数和选中状态层级接近原型。

热点页：

- 标题为“热点事件”，搜索提示为“搜索热点事件”；
- 每行显示真实 PNG 缩略图、标题、摘要和真实讨论数，图片可复用；
- 长标题、缺图和图片失败有稳定降级，但正式正常态证据必须显示图片。

两页均覆盖 300ms 左右防抖、请求竞态丢弃旧结果、分页到底、无结果、失败重试、返回不选择以及重新选择替换旧值。

完成门槛：两张选择器原型分别有当前 APK 证据，数据来自真实 API，返回后发布请求确实携带所选 ID。

### VR7-M6：联调、响应式与同 APK 证据

- 使用专用验收账号完成一次真实 POST 和一次真实 ARTICLE 发布；标题使用唯一 VR7 前缀，先在“我的发布”查重，已有则不重复制造数据。
- 至少一个结果包含图片、TOPIC 和 HOT_EVENT；详情接口必须回读两条关系及名称，图片可访问。
- Pixel 8 标准尺寸、360dp、140% 字体下实际完成：打开编辑器 → 输入 → 选图 → 选择话题 → 选择热点 → 返回 → 切换模式/发布。不得只做静态 Widget 存在断言。
- 从最终源码构建并安装 APK；所有正式截图来自同一 APK，结束后恢复设备尺寸、density 和 font scale。

完成门槛：第 5 节全部通过，并生成第 7 节证据；执行模型只提交 Plan 模型复验，不自行关闭 VR7。

## 5. 强制验收矩阵

| 编号 | 必须验证 |
| --- | --- |
| VR7-01 | 帖子空态头部、标题线、正文、关联入口、底栏和安全区几何 |
| VR7-02 | 帖子填写态图片格、标签、长文本、删除与滚动几何 |
| VR7-03 | 新建文章初始态及帖子/文章切换、草稿确认和临时文件清理 |
| VR7-04 | 话题列表真实 API、搜索、防抖、竞态、分页、空态、错误和重试 |
| VR7-05 | 热点列表真实图片、摘要、讨论数及媒体失败降级 |
| VR7-06 | POST 请求写入 TOPIC/HOT_EVENT，详情回读 ID、类型和名称一致 |
| VR7-07 | ARTICLE 请求及既有文章编辑/blocks/封面/关系能力不回归 |
| VR7-08 | 0～9 图、上传失败重试、发布失败保留和重复提交防护 |
| VR7-09 | 取消、系统返回、选择器返回和发布后详情/返回链正确 |
| VR7-10 | 标准、360dp、140% 字体下编辑器、键盘、选择页均无 overflow/遮挡 |
| VR7-11 | 目录 Migration/Seed 幂等、关系目标有效、回滚保护及非目标泄漏为 0 |
| VR7-12 | 现有 TEAM/PLAYER/MATCH、内容详情、文章编辑与 Feed 行为不变 |

几何测试必须断言关键位置、尺寸、层级或可视范围，不得只查找文字。不得通过放大测试视口、降低字体、删除旧断言或使用正式 fixture 截图绕过问题。

## 6. 最小最终验证

1. M0 的 7 个 Flutter 文件，加上 VR7 新增的 API/controller/几何/交互测试；最终数量必须高于基线 32 项。
2. 后端只跑目录查询、`ContentService`、内容 Controller/Service 直接相关测试；无需全量回归。
3. `flutter analyze`。
4. 真实 API smoke：TOPIC 首屏、HOT_EVENT 首屏、两类关键词搜索、POST 发布及详情、ARTICLE 发布及详情；业务响应均为 `HTTP 200 + code=0`。
5. 至少 2 张热点封面为 `200 + image/png`；匿名媒体访问不依赖登录 Token。
6. Migration/Seed/Validator 双跑；静态复核 Rollback 只处理 VR7 所有权数据。正式证据数据库保留 VR7 Seed 和唯一验收内容，不执行最终回滚。
7. 前端与后端 `git diff --check`；记录最终 APK 完整 SHA-256。

## 7. 正式视觉证据

新建 `reports/VR7_PUBLISH_EDITOR_VISUAL_PARITY_EVIDENCE`，至少包含：

- `00_before_post_editor.png`
- `01_post_empty.png`
- `02_post_filled.png`
- `03_article_empty.png`
- `04_topic_picker.png`
- `05_hot_event_picker.png`
- `06_width_360dp.png`
- `07_font_140.png`
- `08_published_detail_relations.png`
- `comparison_01.png` 至 `comparison_05.png`
- `VISUAL_COMPARISON.md`
- `EXECUTION_RECORD.md`

5 张 comparison 必须逐一使用对应原型，不得重复拿同一张实机图代替不同状态。报告逐图记录结构、比例、间距、字体、颜色、圆角、图片裁切、键盘/底栏层级和允许的契约差异；正式正常态只能使用真实 API 与最终 APK。

## 8. 保护项与停止条件

- 不修改 Feed 排序、首页布局、P1～P3 Seed、VR6 评论数据、足球详情和用户中心。
- 不删除或覆盖现有用户内容；不执行 `TRUNCATE`、全表重建或整库 `schema.sql`。
- 不加入无法工作的表情、@、创建话题、第三方同步或热点详情入口。
- 若最小目录契约无法按第 3 节实现，立即停止在 M1 并报告具体阻塞；不得退回本地静态列表后继续宣称完成。
- 任何一张原型未形成同 APK 对照、真实关系未入库或 ARTICLE 旧能力回归，VR7 均不得通过，也不得进入 VR8。

## 9. 交给执行模型的精简提示词

任务：严格执行 `D:\Football-APP-Front\reports\VR7_PUBLISH_EDITOR_VISUAL_PARITY_EXECUTION_PLAN.md`，按 M0→M6 完成发布编辑器、话题选择和热点事件选择 5 张原型的一比一复刻。

范围：只处理发布目录最小后端/数据库能力、POST/ARTICLE 真实关系提交、帖子两态、文章新建初始态及两个选择页；禁止进入独立搜索、首次球队/球员选择、用户中心、登录、消息和其他页面族。

关键要求：移除生产 `PublishLocalSource`；话题/热点必须来自真实 API 并以 `TOPIC/HOT_EVENT` 写入 `content_relation`，详情可回读；保留 TEAM/PLAYER/MATCH 和既有 ARTICLE blocks/编辑能力。数据库脚本须独立、幂等、可校验、保护式回滚且不覆盖 P1～P3 数据。

完成标准：VR7-01～12 全部有直接测试；相关 Flutter 测试高于 32 项，定向后端测试、analyze、真实 API/PNG、双跑数据校验、两仓 diff 和最终 APK 通过；同一 APK 生成 9 张正式截图、5 张原型对照及执行记录。完成后只提交 Plan 模型复验，不自行宣布 VR7 通过或进入 VR8。

## 10. Plan 复验结论（2026-09-21）

M1/M2 的真实目录、数据和发布关系链路有效；R2/E1 已关闭帖子空态几何、话题搜索前缀、详情关系截图、完整回归和自然中文填写态证据。VR7 已最终通过，详见 `reports/VR7_FINAL_ACCEPTANCE_2026-09-22.md`。
