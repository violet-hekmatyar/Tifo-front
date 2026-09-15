# 原型对齐第 03D 轮收口 Prompt

任务：
修正 CONTENT 瀑布流几何测试的测试环境恢复错误，完成第 03 轮收口。

范围：
- 只能修改 `apps/mobile/test/features/feed/f04_home_feed_widget_test.dart`。
- 禁止修改任何生产代码或其他测试。

要求：
- 在 `content masonry keeps independent columns and full-width gaps` 测试中，当前连续注册了两次 `resetPhysicalSize`；将其中正确的一处改为 `resetDevicePixelRatio`。
- 最终该测试必须分别注册一次 `resetPhysicalSize` 和一次 `resetDevicePixelRatio`，不得调整几何断言或测试数据。

完成标准：
- 测试视口尺寸和像素比都能在结束后恢复。
- 完整 `f04_home_feed_widget_test.dart` 14 项全部通过。

执行：
只做上述一处测试修正，然后运行该测试文件；不运行全量测试、不启动模拟器、不 build APK。

最终仅汇报：
- 修改文件
- 修正结果
- 测试结果

成功标志：
Round 03D test teardown fix passed
