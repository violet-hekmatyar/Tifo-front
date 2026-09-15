# 原型对齐第 02 轮执行 Prompt

任务：
参照 `C:\Users\hekmatyar\Desktop\足球APP\首页.png`，完成首页顶部、推荐/资讯/关注频道和球队快捷筛选区的视觉与交互对齐。

范围：
- 只修改 `home_feed_page.dart` 中的首页顶部、`feed_filter_bar.dart`、`followed_team_bar.dart` 及必要定向测试。
- 不修改 Feed 卡片、瀑布流布局、返回顶部按钮、Controller/Repository/model/mock 数据、路由定义或后端。

要求：
- 顶部保留“南看台”、搜索和发布入口，按原型调整尺寸、间距、圆角和绿色状态；搜索与发布继续使用现有路由和 Key。
- 三个频道使用紧凑胶囊式切换，选中态为绿色，切换行为和加载状态保持现状。
- 球队快捷区横向滚动，包含“全部”和本地 mock 返回的关注球队；队徽、名称省略和选中边框接近原型。
- 点击球队快捷项应选择对应 Feed 筛选，不直接跳转球队详情；“全部”清除球队筛选。复用现有 `selectedTeamId`/`onSelected`，不得另建重复状态。
- 关注球队为空时自然隐藏，不编造球队；窄屏和 1.4 倍字体无溢出。
- 复用第 01 轮 Design Token，不新增依赖、不做无关重构。

完成标准：
- 首页顶部、频道、球队快捷区的结构和视觉层级与原型一致。
- 搜索/发布可跳转，频道和球队选择状态正确，快速切换无旧选中态残留。
- 本轮之外的 Feed 渲染、分页和主导航不回归。

执行：
直接修改代码，只读取本任务相关文件。开发中不启动模拟器、不 build APK、不跑全量测试；完成后只运行 `flutter analyze` 和 `f04_home_feed_widget_test.dart`，并补充本轮必要的 Widget 断言。

最终仅汇报：
- 修改文件
- 完成结果
- 验证结果
- 阻塞/剩余问题

成功标志：
Round 02 home header and filters passed
