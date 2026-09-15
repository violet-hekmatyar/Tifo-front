# 原型对齐第 01A 轮收口 Prompt

任务：
修复第 01 轮悬浮底部导航的圆角裁剪和页面底部遮挡风险，使主框架达到可验收状态。

范围：
- 只修改 `apps/mobile/lib/features/main_shell/presentation/main_shell_page.dart` 及主 Shell 必要的定向测试。
- 不修改 Design Token 数值、四个业务页面、Feed、Repository、model、mock 数据或后端。

要求：
- 当前外层 `Container` 有圆角，但内部 `NavigationBar` 会绘制矩形 `Material` 背景；需让白色导航实体按同一圆角真实裁剪，同时保留外部阴影。
- 处理 `extendBody: true` 带来的底部内容遮挡风险。优先采用主 Shell 层的最小方案，保证首页、数据、消息、我的四个分支的最后一项内容和可点击控件不会位于导航后方；不要逐页添加临时 padding。
- 保留四分支状态、再次点击当前 Tab 返回初始位置的现有行为、未读 Badge、SafeArea 和导航 Key。
- 增加主 Shell 定向 Widget 测试，至少覆盖圆角裁剪结构、四 Tab 切换/状态保持，以及窄屏和底部安全区下无异常。
- 不做视觉范围扩张，不新增依赖。

完成标准：
- 导航四角不会被矩形背景盖住，阴影仍显示在圆角容器外。
- 四个主页面底部内容不被悬浮导航遮挡。
- 原有导航行为和未读 Badge 不回归。

执行：
直接修改代码，只读取上述相关文件。开发中不启动模拟器、不 build APK、不跑全量测试；完成后只运行 `flutter analyze`、新增的主 Shell 定向测试和现有 `f04_home_feed_widget_test.dart`。

最终仅汇报：
- 修改文件
- 问题根因与修复结果
- 验证结果
- 阻塞/剩余问题

成功标志：
Round 01A shell acceptance fix passed
