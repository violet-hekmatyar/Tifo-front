# VR7 执行记录

## M0：基线、原型测量与契约冻结

日期：2026-09-21

### 基线结果

- Flutter 定向基线：计划指定的 7 个测试文件，共 32 项，全部通过。
- 后端定向基线：`ContentServiceTests` 2 项，全部通过。
- 当前 APK before 证据：`00_before_post_editor.png`。使用现有安装包启动并截图；旧 APK 在当前环境停留于 Flutter 启动画面，未将该画面误判为编辑器验收证据。
- 发布路由已核对：`/publish`、`/publish/post`、`/publish/article`、`/publish/topic`、`/publish/hotspot` 均已存在；帖子发布后的详情跳转及返回链由现有发布返回测试覆盖。

### 原型测量

5 张原型均为 750×1624 PNG，按 3 倍密度换算为约 250×541dp。关键基线如下，后续以最终实机截图复核：

| 状态 | 关键几何基线 |
| --- | --- |
| 帖子空态 | 状态栏约 84px；顶部操作区至约 190px；标题输入左边距约 28px、底部分隔线约 295px；正文提示起点约 y=334px；添加图片格约 x=28、y=427、140×140px；底部关联入口和模式栏固定在安全区上方。 |
| 帖子填写态 | 标题仍为单行分隔输入；正文多行；图片缩略图约 140×140px；话题/热点为底部紧凑绿色标签；不显示 Material 外框或常驻计数器。 |
| 文章空态 | 与帖子共享顶部和输入层级；底部“文章”选中，正文区保持大面积留白。 |
| 话题选择 | 左返回、居中标题；约 20px 圆角搜索框；列表无卡片阴影，行高约 80px；名称在左、讨论数在右。 |
| 热点选择 | 左返回、居中标题；每行约 128px 高；左侧约 128px 方形缩略图，右侧标题与摘要；列表紧凑排列。 |

### 已冻结的契约缺口与范围

- `PublishAuxiliaryPage` 当前读取生产代码 `PublishLocalSource` 静态数据；M2 必须改为真实 API，禁止保留生产 fallback。
- `ContentApi.createPost` 当前固定提交空 `relationList`；M2 必须透传真实 `ContentRelationInput`。
- 后端当前仅校验 `TEAM / PLAYER / MATCH`；M1 需新增 `TOPIC / HOT_EVENT` 目录、查询、关系校验和名称解析。
- 文章已有 `relationList`、blocks、封面和足球对象关联能力，后续必须保持兼容。
- 允许变更范围冻结为：后端 content 发布目录与关系校验、VR7 专用 SQL/Manifest/Validator/Rollback、移动端 content 发布相关 domain/data/controller/page/widget/test、VR7 证据与报告；不触碰 Feed、P1-P3/VR6 数据和其他页面业务。

M0 结论：基线与契约已冻结，进入 M1；本阶段未执行数据库脚本、未修改业务代码。

## M1：真实话题/热点目录与后端关联

### 已完成

- 新增 `content_publish_subject` 实体、Mapper、Service、VO 和 `GET /api/app/publish/subjects`。
- 支持 `TOPIC`、`HOT_EVENT` 类型、名称/摘要关键词、分页上限 50、热度/顺序/ID 排序、软删除过滤和真实有效内容讨论数聚合。
- `ContentService` 已接受并校验 `TOPIC / HOT_EVENT`，并在内容详情中解析真实关系名称；`TEAM / PLAYER / MATCH` 路径保持不变。
- GET 目录接口已按现有公开查询约定加入匿名访问白名单。
- 新增 12 条 VR7 目录数据和 12 条 VR7 关系数据；热点复用既有 P1 PNG，不修改 P1 内容正文、封面、热度或原关系。
- Migration、Seed、Validator 均已执行两次：两次 Seed 均保持 12 条目录/12 条关系，两次 Validator 均通过；真实讨论数均由有效 `content_relation` 聚合为 1。
- 后端定向测试：`ContentServiceTests` 2 项 + `PublishSubjectServiceTests` 2 项，全部通过；Maven 打包编译通过。

### 当前未关闭项

- 尚未完成 HTTP 运行态 smoke：当前 Codex 进程启动新 JAR 时复现既有 Windows Java NIO `PipeImpl → UnixDomainSockets.connect0` 故障，Tomcat 在 Selector.open 前后无法启动。该故障与 VR7 代码和 SQL 无关；旧 8080 进程已停止以释放 JAR 文件锁。
- 因此尚未把 M1 标记完成，也未进入 M2。待普通 Windows Terminal/PowerShell 启动 18081 后，仅需补验 TOPIC/HOT_EVENT 首屏、关键词查询和匿名热点 PNG，再继续 M2。

### 运行态补验结果

使用正确注入 MySQL 密码的独立实例 `18082` 完成：

- TOPIC 首屏：HTTP 200、`code=0`、6 条；HOT_EVENT 首屏：HTTP 200、`code=0`、6 条。
- TOPIC/HOT_EVENT 关键词查询：HTTP 200、`code=0`，各返回 1 条匹配记录。
- 非法类型：HTTP 200、`code=40001`，符合项目统一错误外壳。
- 内容 `16000000000000201` 详情：HTTP 200、`code=0`，真实回读 `TOPIC:16500000000000701:英超焦点` 与 `HOT_EVENT:16500000000000715:国家队新一期名单`。
- `player-flagship.png`、`cover-stadium.png`：均 HTTP 200、`image/png`。

M1 结论：**完成**。18081 旧实例因未注入 MySQL 密码仍不可用于验收，但不影响已验证的 18082 正确配置实例；不进入 M1 返工。

## M2：Flutter 契约接入与草稿状态

状态：**完成，进入 M3。**

### 已完成

- 新增移动端主题/热点 domain、API、repository 和分页 controller；选择目录支持真实列表、关键词、分页去重、空态、失败和重试。
- 删除生产环境静态 `PublishLocalSource`，选择页不再依赖本地目录。
- 帖子创建透传主题与热点 `relationList`；文章编辑器保留 TEAM/PLAYER/MATCH 关系，并追加 TOPIC/HOT_EVENT 关系。
- 文章详情加载会区分足球对象关系与主题/热点关系，既有 Blocks、封面和文章关系能力保持不变。

### 验证

- `flutter analyze`：通过。
- M2 定向测试：API、文章关系、发布选择页和目录 controller 共 15 项通过。
- VR7/M0 相关发布、文章、评论定向测试通过。
- 18082 真实 API 已验证 TOPIC/HOT_EVENT 列表、关键词、非法类型、内容详情关系及匿名 PNG。
- 生产代码无 `PublishLocalSource` 引用。

## M3-M5：编辑器与选择页结构复刻

状态：**完成，进入 M6。**

### 已完成

- 帖子空态/填写态改为原型同层级的白色编辑壳：取消、绿色实心发布、无边框标题/正文、方形图片添加格、底部话题/热点入口和帖子/文章切换。
- 新建文章使用轻量标题与正文 block 初始态；既有文章编辑仍保留封面、Blocks、排序、足球关联和媒体清理能力。
- 主题页改为真实 API 驱动的全屏列表，支持搜索、空态、失败重试、分页和选中返回；热点页显示真实 PNG、标题和摘要。
- 文章和帖子均可从底部入口选择主题/热点，并在草稿状态中保留、替换和删除。

### 验证

- `flutter analyze`：通过。
- 新增/更新发布 UI、选择器、文章关系和响应式测试；当前 VR7 相关 Flutter 测试均通过。
- 选择器不再显示旧的深色 AppBar、“完成”按钮或生产静态目录。

## M6：联调、响应式与同 APK 证据

状态：**代码与 API 联调完成；APK/Android 证据待外部普通 Windows Terminal 完成构建。**

### 已完成

- VR7 定向 Flutter 回归共 51 项通过，包含帖子、文章、目录 controller、API、选择页、文章 Blocks/关系和既有评论链路。
- `flutter analyze`：通过；前后端 `git diff --check`：通过。
- 18082 真实 API 联调通过：验收用户真实创建带图片、TOPIC、HOT_EVENT 的帖子和文章；两个详情接口均回读两条新关系。
- ADB 已确认存在，设备 `emulator-5554` 在线。

### M6 初始阻塞（已由续验解除）

- Codex 进程内执行最终 `flutter build apk --debug --no-pub --dart-define=APP_ENV=development --dart-define=API_BASE_URL=http://10.0.2.2:18082` 时，Gradle 报既有 Windows Java `Unable to establish loopback connection`；直接 PowerShell/cmd 子进程重试结果相同。
- 因此尚未安装“当前 VR7 源码”APK，也未生成正式 9 张 Android 截图、5 张原型对照图和 360dp/140% 实机证据。本阶段不使用旧 APK 或旧截图替代。
- M6 不标记完成，VR7 不提交通过结论；待普通 Windows Terminal 成功构建后继续安装、截图和 Plan 模型复验。

### M6 续验结果（同一 APK）

日期：2026-09-21

- 已通过普通 Windows 用户任务完成 APK 构建并安装到 `emulator-5554`。
- APK：`apps/mobile/build/app/outputs/flutter-apk/app-debug.apk`。
- M6 基线 APK SHA-256：`BA71D3BB07570B6984F492502EE0A934D02B224D662A1E50FEF50540C4DA1A46`；R1 收口 APK 以末尾 R1 记录为准。
- 已使用同一 APK 完成帖子空态、帖子填写/图片、文章空态、话题选择、热点选择、双关联、发布后详情 及 360dp/140% 字体截图。
- 真实帖子发布成功并进入详情；详情保留图片、作者、正文和互动栏。帖子草稿中同时显示 `#英超焦点` 与 `热点 · 利雅得胜利宣布中国行延期`。
- 360dp 实际参数：`945 × 160 ÷ 420 = 360dp`；140% 字体截图完成后已恢复 `1080x2400`、density `420`、font scale `1.0`。
- 5 张原型文件已复制到证据目录并建立逐图映射；见 `VISUAL_COMPARISON.md`。
- 当前 Flutter 相关定向测试 51 项、最新文章/发布补充测试 8 项均通过；`flutter analyze` 通过；前后端 `git diff --check` 通过。

M6 状态：**证据已提交，等待 Plan 模型复验；不在本记录中自行宣布 VR7 通过。**

## VR7-R1 限定返修收口记录

日期：2026-09-21

- R1-A：Rollback 已改为保护 `(r.remark IS NULL OR r.remark NOT LIKE 'VR7-M1-relation-%')`；本轮只做 SQL 静态核对，未执行回滚。
- R1-B：帖子图片格和缩略图收紧为 80dp；Android 选图使用缓存的 `readAsBytes()` Future，当前 APK 截图已实际显示真实缩略图；取消按钮在 140% 字体下保持单行。
- R1-C：新建文章移除正文 `关联 0/10` 区块，热点默认页移除搜索框并将缩略图收紧至 78dp；话题/热点真实 API 和选择能力保留。
- R1-D：重采 `01`～`08`、`formal_06`、360dp 和 140% 字体证据；生成 `comparison_01`～`05` 真实左右对照合成图。
- APK SHA-256：`0B2F70F3CCC03B51A731A721C4C7C048B6DB745798E3232670E5DA9B04BA211E`。
- 定向测试：23 项通过（F12、F11、F05、F17）；`flutter analyze` 通过；前后端 `git diff --check` 通过。
- 设备状态：`emulator-5554`；完成后恢复标准尺寸、density 420、font scale 1.0。

R1 状态：**已完成实现与证据提交，等待 Plan 模型复验；本记录不自行宣布 VR7 通过。**

## VR7-R2 最终收口执行记录

日期：2026-09-22

### 代码与测试

- 帖子空态正文在无内容时使用单行最小高度，图片添加格回到正文提示后的紧凑位置；有内容时仍保留自然增长。
- 话题搜索前缀补为搜索图标与绿色 `#` 的紧凑组合；热点页未增加搜索框。
- R2 冻结的 7 个基线文件、`f17_publish_subject_test.dart` 及补充内容测试共 53 项通过；其中冻结基线 38 项、补充内容测试 15 项。
- `flutter analyze` 通过；前后端 `git diff --check` 通过。

### APK 与证据

- 通过独立 Windows 任务重新构建并安装同一 APK，设备为 `emulator-5554`。
- APK SHA-256：`01CE434E7D249F31D12E8D3918FF354634957598BA14AE9CD4DF0A09F251ADE0`。
- 已重采帖子空态、文章空态、360dp、140% 字体、话题选择和热点选择；已重制 5 张真实原型/实机对照图。
- `formal_06_post_both_relations.png` 已改为帖子编辑器画面，实际可见真实缩略图、话题和热点；`08_published_detail_relations.png` 已改为固定内容详情并实际显示 `# 英超焦点`、`# 国家队新一期名单`。
- 设备参数已恢复：`1080x2400`、density `420`、font scale `1.0`。

### R2 初始待补正项

R2 初始复验时 Android 输入法无法稳定提交自然中文标题/正文，因此当时没有使用旧英文测试文案或后处理图片；该缺口已由下方 E1 纯采证任务补齐。未修改后端、数据库、API、Seed、详情布局或其他页面。

## VR7-R2-E1 中文证据补正记录

日期：2026-09-22

- 本轮仅执行证据补正，没有修改 Dart、Java、SQL、配置、API、Seed、测试或生产数据；没有重建 APK。
- 使用固定 APK `01CE434E7D249F31D12E8D3918FF354634957598BA14AE9CD4DF0A09F251ADE0`，本地 APK SHA-256 复核一致。
- 在真实 Android 编辑器中通过系统剪贴板的可见 Paste 菜单录入中文标题和正文；不是英文测试文案、拼音未上屏文本、预填充代码或图片后处理。
- 中文标题：`圣西罗夜场的压迫感从哪里开始`。
- 中文正文：`这场比赛的关键不只是最后一脚射门，而是球队如何在边路形成连续压迫，值得赛后慢慢复盘。`。
- 录入后同屏确认真实缩略图、`#英超焦点`、`热点 · 利雅得胜利宣布中国行延期`、帖子模式和自然中文正文均可见。
- 按计划重采：`02_post_filled.png`、`formal_02_post_filled.png`、`formal_06_post_both_relations.png`；三张均为 1080×2400 Android 原始截图，SHA-256 均为 `6AADDD7257AC9E0D267AB83B8CBA6F2E1DA1E6B021A98B243AD47FFD10FF1302`。
- 按计划重制：`comparison_02_post_filled.png`；左侧使用既有原型，右侧使用新的 `formal_06_post_both_relations.png`，未在实机截图上覆盖文字或图像。
- 设备参数复核并恢复为 `1080×2400`、density `420`、font scale `1.0`。
- 已通过本地截图人工复核；既有 53 项测试、`flutter analyze`、API smoke 和响应式结果按 E1 计划沿用。

E1 状态：**证据补正完成，提交 Plan 模型最终复验；不自行宣布 VR7 通过，也不进入 VR8。**
