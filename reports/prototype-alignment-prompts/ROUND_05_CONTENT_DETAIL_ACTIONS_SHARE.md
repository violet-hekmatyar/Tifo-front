# 原型对齐第 05 轮执行 Prompt

任务：
参照 `C:\Users\hekmatyar\Desktop\足球APP\帖子详情.png` 和 `详情分享弹窗.png`，完成帖子/文章详情、固定互动栏与可用分享弹层的原型对齐。

范围：
- 只修改 content detail page、详情展示相关 Widget 和必要定向测试。
- 可使用 Flutter 内置 Clipboard，不新增依赖；不修改 Controller/Repository/domain/mock 数据、发布页、评论内部实现、路由定义或后端。

要求：
- POST 与 ARTICLE 共用原型化详情骨架：顶部返回/分享，标题、作者头像/认证、发布时间/阅读数、正文/媒体、关联实体；ARTICLE 继续按 block 顺序渲染并安全降级 unknown block。
- 作者和 TEAM/PLAYER/MATCH 关联仍可进入现有详情；编辑按钮仅对现有作者/管理员条件显示。
- 建立固定底部互动栏，展示评论数、点赞、收藏及当前状态；复用现有 toggleLike/toggleFavorite、busy、失败回滚和推荐行为上报。评论入口定位到现有 CommentSection，本轮不重写评论列表或输入。
- 分享按钮打开原型风格圆角底部弹层；只提供真正可用的“复制链接”和取消，复制当前 `/contents/{id}` 路径并明确反馈成功。不得放置微信等无实现按钮。
- loading/empty/error/retry 保持有效；底部栏不能遮挡正文或评论。412px、1.4 倍字体、长标题、缺头像/媒体/时间、空关联均无溢出。
- 复用 Design Token，不硬编码原型示例数据、不做无关重构。

完成标准：
- POST/ARTICLE 详情结构和信息层级与原型一致，长内容可正常滚动。
- 点赞/收藏、评论定位、作者/关联跳转、编辑权限和返回逻辑不回归。
- 分享弹层可打开、复制并关闭，无死按钮；各页面状态安全。

执行：
直接修改代码，只读取内容详情相关文件。不启动模拟器、不 build APK、不跑全量测试；完成后运行 `flutter analyze`、现有 content 定向测试，并新增详情、互动栏、分享与大字体 Widget 测试。

最终仅汇报：
- 修改文件
- 详情与互动完成结果
- 分享完成结果
- 验证结果
- 阻塞/剩余问题

成功标志：
Round 05 content detail actions and share passed
