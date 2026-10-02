# VR6-R2-E1 测试与同 APK 证据补正计划

状态：**已完成并通过 Plan 最终复验；VR6 已关闭**  
唯一目标：使用现有最终 APK 补齐 360dp 测试链和两组正确联系表，重制当前 APK 对照图，关闭 VR6。

## 1. 严格范围

- `apps/mobile/test/features/content/f05_detail_interaction_widget_test.dart`
- `reports/VR6_CONTENT_INTERACTION_VISUAL_PARITY_EVIDENCE/**`
- VR6-R2 计划与执行记录状态

禁止修改任何生产 Dart、依赖、后端、数据库、Seed、API、正式数据或其他阶段文件。现有 APK 不重建，哈希必须保持 `78B8B35E1D9888F7B2C41F952A47B4896CEACDCA6985D02845AB21DDCF059A51`。

## 2. 测试补正

1. 在 360dp 用例进入回复层后，实际点击 `content_replies_input_capsule`，确认指定回复标题、输入框和发送动作可见，检查无异常，然后按层级返回详情。
2. 将根评论全屏断言改为覆盖完整逻辑视口（允许系统安全区合理误差），同时验证详情 `南看台` 头部在评论页不可见、返回后重新可见。
3. 保留 140% 已有完整链路、关注集成和其他断言，不拆分空测试、不降低字号、不扩大视口。

执行原 VR6 六个测试文件；34 项可保持不变，但所有收紧后的断言必须通过。随后执行 `flutter analyze` 和前后端 `git diff --check`。

## 3. 同 APK 证据补正

使用当前已安装的同哈希 APK，在 `debug/` 新采以下 10 张源图：

- `r2e1_360_share/comments/comment_composer/replies/reply_composer.png`
- `r2e1_140_share/comments/comment_composer/replies/reply_composer.png`

要求每张来自真实 API 固定内容，画面名称和实际状态一一对应，无重复图或详情页冒充分享层。

重新生成：

- `responsive_360dp_layers.png`：严格按分享→评论→根评论输入→回复列表→指定回复输入排列；
- `responsive_font_140_layers.png`：同样五层排列；
- `comparison_01.png`～`comparison_06.png`：全部从当前正式 `01`～`07` 截图重新合成，确保文件时间和记录对应当前 APK。

更新 `EXECUTION_RECORD.md` 与 `VISUAL_COMPARISON.md`，记录新源图名称、APK 哈希及设备恢复值。无需重采 `01`～`09`，无需重复 API/Seed/Validator。

完成后只提交 Plan 模型最终复验，不自行宣布 VR6 通过，不进入下一阶段。

## 4. 交给执行模型的精简提示词

任务：执行 `reports/VR6_R2_E1_TEST_EVIDENCE_CLOSURE_PLAN.md`，只补齐 VR6 测试与证据，不改生产代码。

范围：收紧 F05：360dp 必须实际打开指定回复输入并完成返回链；评论页须断言覆盖完整逻辑视口。使用现有哈希 `78B8...59A51` APK 新采 360dp/140% 各五层源图，联系表严格包含分享、评论、根输入、回复、指定回复输入；用当前 `01`～`07` 重制 6 张 comparison。禁止修改前端生产代码、后端、数据库、Seed 或 API，禁止重建 APK。

完成标准：VR6 六文件 34 项（或实际数量）、analyze、两仓 diff 通过；APK 哈希不变；两张联系表无缺图/重复图，6 张 comparison 均对应当前 APK。完成后仅提交最终复验。
