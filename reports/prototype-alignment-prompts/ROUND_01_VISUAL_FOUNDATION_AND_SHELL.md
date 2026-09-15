# 原型对齐第 01 轮执行 Prompt

任务：
完成 Flutter 客户端全局视觉基础和主框架对齐：建立原型所需的绿色语义色、页面背景、卡片、文字、圆角、阴影与间距 Token，并将四项主导航改为原型中的悬浮胶囊样式。

原型参考：
- `C:\Users\hekmatyar\Desktop\足球APP\首页.png`
- `C:\Users\hekmatyar\Desktop\足球APP\数据-西甲-积分榜.png`
- `C:\Users\hekmatyar\Desktop\足球APP\消息.png`
- `C:\Users\hekmatyar\Desktop\足球APP\我的-首页.png`

范围：
- 只修改 Flutter Design System、Theme、主 Shell 和主导航必要的定向测试。
- 允许为这些公共组件增加小型复用 Widget。
- 不修改首页 Feed、数据榜、消息、用户中心的页面内容，不修改 Repository/model/mock 数据，不修改后端。

要求：
- 复用现有路由与四个主页面，切换和选中状态不得回归。
- 主导航需处理底部安全区，视觉接近原型的白色悬浮圆角容器、绿色选中态和未选中态。
- Token 使用语义命名，禁止在业务页面散落重复色值；保留球队/球员酒红色和比赛深色上下文主题的扩展空间，但本轮不改详情页。
- 当前仍使用本地模拟数据；本轮不得接入或修改真实接口。
- 不做无关重构、不新增依赖、不处理手机号或微信登录。

完成标准：
- 四个主入口可正常切换，选中状态正确，页面状态不因切换丢失。
- 主框架背景和底部导航在常用手机宽度、大字体及安全区下无溢出或遮挡。
- 后续页面可以复用新的颜色、间距、圆角、卡片和文字 Token。

执行：
直接修改代码。只读取本任务必要文件，不做全仓扫描。开发中不启动模拟器、不 build APK、不跑全量测试；完成后只运行 `flutter analyze` 和主 Shell/Design System 定向测试。

最终仅汇报：
- 修改文件
- 完成结果
- 验证结果
- 阻塞/剩余问题

成功标志：
Round 01 visual foundation and shell passed
