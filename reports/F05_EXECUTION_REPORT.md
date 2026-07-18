# F05 内容发布与互动执行报告

> 日期：2026-07-18。人工视觉验收未执行，不伪造结论。

## 基线与契约

- 前端初始状态：main 干净，HEAD `6bacfbb feat: add Flutter main shell and home feed`；后端 main 干净，HEAD `98ca87f`。
- F04 聚合回归：`F04 Flutter main shell home feed check passed`。后端 health/db/redis 均 UP，PID 10000。
- 已读前端主线文档、F04 报告、产品 PDF 第 2/6–9 页，以及后端 content/interaction/file Controller、DTO、VO、Service、SecurityConfig 和四个 smoke。
- 详情真实字段：contentType/contentFormat/title/body/cover/author/mediaList/relationList、统计、liked/favorited、publishTime。
- 差异：当前详情没有 blocks/source/isOfficial；ARTICLE 使用 body+mediaList 降级。关系展示兼容任意类型，但当前发布校验只支持 TEAM/PLAYER/MATCH；本轮无候选接口，发布 relationList 为空。toggle 响应无计数，成功后重读详情。

## 实现

- POST 集中正文与横向多图页码；ARTICLE 长文后顺序媒体；相对 URL 统一解析，失败复用内容占位。
- 内容点赞/收藏防重复、失败保留原状态，成功以重读详情为准。
- 评论支持 hot/latest、根评论分页/去重、三条回复预览、全部回复层、回复根/二级评论、专用点赞、本人删除确认；输入最大 1000。
- 发布只支持 POST_FORMAT：标题最大 255、正文 2000、最多 9 图。`image_picker ^1.2.3` 仅相册、多选去重；允许 jpg/jpeg/png/webp/gif、单图 10MB。
- 上传使用统一 ApiClient multipart：file + CONTENT_IMAGE；逐图 waiting/uploading/success/failure，失败可重试，成功图不重复上传。移除未发布已上传图时尽力 DELETE；清理失败不崩溃。
- 发布成功替换进入 `/contents/:id`；离开草稿确认。首页 indexed stack 未改，返回仍保留 F04 状态；首页计数需下次刷新同步。

## 测试与边界

- F05 Mock/Widget：16 个专项测试通过；默认全量 77 个测试通过，analyze 零问题。覆盖内容点赞/收藏与评论点赞的乐观更新、失败回滚，以及草稿上传文件清理。
- 真实 smoke 已独立通过：ARTICLE 详情、点赞/收藏双 toggle、运行时 PNG、上传、mediaFileIds 发帖、详情媒体、根评论、二级回复、hot/latest/replies、评论点赞双 toggle、删除及删除后不可互动。
- 测试临时本地图片已删除，根评论/回复已删除。后端没有用户帖子删除接口，唯一测试帖子与绑定图片保留，这是已知测试数据/孤儿治理风险；未重置数据库。
- 新增脚本全部通过：`F05 Flutter content and interaction check passed`、`F05 local backend content interaction smoke passed`、`F05 Flutter content publish interaction check passed`。
- APK：`apps/mobile/build/app/outputs/flutter-apk/app-debug.apk`。首次 image_picker Android 构建暴露 C:/D: 跨盘 Kotlin 增量缓存错误，已在前端 Gradle 配置禁用 Kotlin incremental 后构建通过。
- 后端未修改；无生产假数据；未输出 Token/密码/评论正文/本地路径；未执行 Git 写操作。
- 未完成：用户 ARTICLE 发布、富文本/视频/相机/压缩、举报审核、内容删除、MATCH 详情、F06/F07/F08 范围。
- 风险：后端 ARTICLE 无 blocks；绑定帖子/媒体无法由普通用户清理；真实大图与键盘交互需人工验收。
- 人工视觉验收：待用户执行 `F05_UI_REVIEW_CHECKLIST.md`。
- 提交建议：最终聚合及人工验收后提交 `feat: add Flutter content publishing and interaction flow`。

## 发布返回与首页布局补充修正

- 人工发现发布详情返回不可靠、首页未自动刷新，以及 CONTENT 夹在 MATCH 之间；根因和修正见 `F05_PUBLISH_RETURN_FIX_REPORT.md`。
- 发布成功使用 replacement，详情统一顶部/系统返回并发送一次性刷新信号；当前 tab/teamId、主框架实例与滚动控制器保留。
- 首页改为 MATCH → CONTENT → Unknown 展示分区；原始 Feed 列表、接口分页及推荐结果不变。
- 新增分区、跨页、稳定去重、刷新竞态/失败、真实路由栈和大尺寸布局覆盖；全量 88 个测试通过、analyze 零问题、真实 smoke 与 Debug APK 构建通过，最终输出 `F05 Flutter content publish interaction check passed`。
- 人工复验尚未执行，因此人工问题尚不能宣称完全关闭。
