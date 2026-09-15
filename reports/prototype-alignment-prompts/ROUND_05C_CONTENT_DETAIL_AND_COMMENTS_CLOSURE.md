# 原型对齐第 05C 轮执行 Prompt：内容详情与评论体系整体收口

## 任务

完成内容社区详情链路的整体原型对齐：收口现有详情、固定互动栏与分享测试，并重做评论列表、回复弹层、评论输入和全部页面状态。

## 原型参考

- `C:\Users\hekmatyar\Desktop\足球APP\帖子详情.png`
- `C:\Users\hekmatyar\Desktop\足球APP\详情分享弹窗.png`
- `C:\Users\hekmatyar\Desktop\足球APP\资讯主页-评论区.png`
- `C:\Users\hekmatyar\Desktop\足球APP\资讯主页-评论区回复.png`
- `C:\Users\hekmatyar\Desktop\足球APP\资讯主页-回复评论区.png`
- `C:\Users\hekmatyar\Desktop\足球APP\资讯主页-回复评论区回复.png`

## 范围

- 可修改内容详情页、`CommentSection`、评论 presentation controller/widget，以及 content/interaction 相关定向测试。
- 允许增加本模块内部复用 Widget、稳定 Key、FocusNode 或页面内协调接口。
- 不修改 Repository/API/domain 契约、本地 mock 数据源、发布页、全局路由、Feed、后端或依赖。

## 详细要求

### 1. 先完成第 05 轮现有测试收口

- 修正 `f05_detail_interaction_widget_test.dart`：点击分享弹层“取消”后必须 `pumpAndSettle()`，确认弹层完全退出后再第二次打开；不得把 ready 分享按钮强制 enabled 或绕过真实点击。
- 验证取消不写 Clipboard；复制准确写入 `/contents/{id}`、关闭弹层并显示“链接已复制”。
- 点赞/收藏成功时逐项验证 LIKE/FAVORITE 的 targetType、targetId、impressionId；inactive 或失败时不得上报。
- loading、failure、notFound 时固定互动栏不显示。
- 评论按钮不能只验证“不报错”：必须证明详情主滚动区发生滚动，并将评论输入区域带入可见范围。

### 2. 评论区视觉与状态

- 按原型调整评论标题、热门/最新排序、评论数量/状态、分割关系和页面留白，复用绿色 Design Token。
- loading、empty、failure/retry、ready、loadingMore、到底状态均需明确且互不伪装；分页继续复用现有 controller 去重逻辑。
- 评论项展示头像、昵称、发布时间、正文、回复、点赞和本人删除入口；长昵称、长正文、空头像、可空回复对象在 412px 和 1.4 倍字体下不得溢出。
- 点赞保持现有 optimistic/失败回滚；删除只对当前用户自己的评论出现，继续使用确认弹窗，取消不得删除。

### 3. 楼中楼与回复弹层

- 评论自带的回复预览按原型使用浅色区域展示，超过预览数量时显示“查看全部 N 条回复”。
- 回复弹层使用圆角、可拖动/安全区适配，顶部保留根评论摘要；覆盖加载、空、错误重试和回复列表。
- 点击某条回复后关闭弹层并回到详情输入区，明确显示“回复 @昵称”；支持取消回复目标。
- `replyToUserId`、parentId 等继续走现有 controller/repository 语义，不自行伪造多级关系。

### 4. 评论输入体验

- 详情底部“评论”操作应滚动到评论输入并请求焦点，而不仅是滚到评论区标题。
- 输入区按原型处理普通评论与回复态，保留 1000 字限制、发送中禁用和明确反馈。
- 空白内容不得提交；提交失败必须保留用户输入和回复目标以便重试；成功后清空输入、退出回复态并触发现有 COMMENT 推荐行为。
- 键盘出现时输入区和发送按钮不能被遮挡；关闭键盘或取消回复后状态一致。

### 5. 不回归约束

- POST/ARTICLE 正文、媒体、ARTICLE block 顺序与 unknown 降级、作者/关联实体跳转、编辑权限、返回流程保持不变。
- 固定底部栏不得遮挡正文和评论；点赞、收藏、评论计数及 active/busy 状态继续来自当前模型和 controller。
- 当前使用本地模拟数据，不硬编码原型中的评论、用户或计数。

## 完成标准

- 详情 → 评论定位/聚焦 → 发布评论或回复 → 成功刷新形成完整闭环。
- 评论排序、分页、点赞、删除、回复预览/弹层、失败保留输入均可观察且状态正确。
- 分享取消/复制、推荐行为成功/失败、非 ready 底栏全部有行为级测试。
- 412px、1.4 倍字体、键盘、安全区、长文本和空数据均无布局异常。

## 最小验证

- `flutter analyze`
- 完整 `test/features/content`
- interaction/comment 相关定向测试
- `f05_publish_return_route_test.dart`
- 不启动模拟器、不 build APK、不跑全仓测试

## 最终仅汇报

- 修改文件
- 详情/分享测试收口
- 评论与回复完成情况
- 输入与状态处理
- 验证结果
- 阻塞/剩余问题

成功标志：
Round 05C content detail and comments closure passed
