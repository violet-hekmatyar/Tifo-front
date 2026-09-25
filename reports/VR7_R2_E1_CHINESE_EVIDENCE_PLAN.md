# VR7-R2-E1 中文填写态证据补正计划

状态：**已完成并通过 Plan 最终复验；VR7 已关闭**  
依据：`reports/VR7_R2_REVIEW_2026-09-22.md`  
固定 APK SHA-256：`01CE434E7D249F31D12E8D3918FF354634957598BA14AE9CD4DF0A09F251ADE0`

## 1. 唯一目标

在当前已安装 APK 的帖子编辑器中，通过真实 Android 输入界面录入自然中文标题和正文，并在同一画面保留真实缩略图、话题和热点，补齐帖子填写态的最终视觉证据。

本轮不是代码返修，不解决 ADB 通用中文输入问题，也不重新执行 VR7 功能开发。

## 2. 范围冻结

允许操作：

- 使用模拟器或实体设备的中文输入法、硬件键盘、系统剪贴板或人工点击候选词录入中文；
- 更新下列 3 张正式截图、1 张对照图及两份证据说明；
- 对报告文件执行 `git diff --check`。

禁止操作：

- 修改任何 Dart、Java、SQL、配置、API、Seed、测试或生产数据；
- 重建 APK、安装不同哈希 APK、增加测试专用入口或预填充代码；
- 使用英文、拼音未上屏文本、图片后处理、覆盖文字、调试 overlay 或 fixture 截图冒充真实输入；
- 重新发布内容、重复 Seed、执行 Rollback 或进入 VR8。

## 3. 执行步骤

### E1-A：真实录入中文

1. 核对设备安装包与固定 APK 哈希一致。
2. 打开帖子编辑器，真实选中一张图片、一个话题和一个热点。
3. 通过 Android 可见输入链路录入：
   - 不超过 20 个中文字符的自然足球标题；
   - 至少两行、语义自然的中文正文。
4. 收起键盘，确认画面同时可见：中文标题、中文正文、真实缩略图、话题标签、热点标签和底部帖子模式。
5. 若当前模拟器输入法无法完成，可换用具备中文输入法的 Android 设备采证，但必须安装完全相同哈希的 APK；不得改应用代码绕过。

### E1-B：替换正式证据

使用同一真实编辑器状态重新生成：

- `02_post_filled.png`
- `formal_02_post_filled.png`
- `formal_06_post_both_relations.png`

三张图可以来自同一次填写状态，但必须是未后处理的 Android 截图，并实际显示全部六项内容。不得覆盖其他已经通过的正式截图。

### E1-C：只重制受影响对照

用新的 `formal_06_post_both_relations.png` 与原型重新生成：

- `comparison_02_post_filled.png`

`comparison_01`、`03`、`04`、`05` 不受本次采证影响，无须重制。更新：

- `VR7_PUBLISH_EDITOR_VISUAL_PARITY_EVIDENCE/VISUAL_COMPARISON.md`
- `VR7_PUBLISH_EDITOR_VISUAL_PARITY_EVIDENCE/EXECUTION_RECORD.md`

报告必须如实写明输入方式、截图时间、APK 完整哈希，以及标题/正文、缩略图和双关联均在画面可见。

## 4. 最小验证

1. 再次计算本地 APK SHA-256，必须仍为固定值。
2. 人工逐图打开 3 张正式截图与 `comparison_02`，确认中文不是键盘候选、提示文字或后处理覆盖。
3. 确认 3 张正式截图确实来自帖子编辑器，并同时显示真实缩略图、话题和热点。
4. 前端 `git diff --check` 通过；确认本轮没有生产代码、测试、后端或数据库文件变动。
5. 若更改过设备参数，恢复 `1080×2400 / density 420 / font scale 1.0`。

由于本轮禁止代码变更，已通过的 53 项测试、`flutter analyze`、API smoke 和响应式验证直接沿用，无须重复运行。若发生任何生产文件变化，则 E1 立即失效，必须停止并重新提交 Plan 评估。

## 5. 完成定义

以下条件全部满足后，才可提交 VR7 最终复验：

- 中文标题和至少两行自然中文正文真实录入；
- 同屏可见真实缩略图、话题和热点；
- 3 张正式图及 `comparison_02` 已更新且画面/说明一致；
- APK 哈希未改变；
- 未修改生产代码、测试、后端、数据库和 API；
- 未用图片后处理或测试 fixture 制造证据。

完成后只提交 Plan 模型最终复验，不自行宣布 VR7 通过或进入 VR8。

## 6. 交给执行模型的精简提示词

严格执行 `D:\Football-APP-Front\reports\VR7_R2_E1_CHINESE_EVIDENCE_PLAN.md`。不要改代码、测试、后端、数据库，不重建 APK。使用当前哈希 `01CE434E7D249F31D12E8D3918FF354634957598BA14AE9CD4DF0A09F251ADE0` 的已安装 APK，通过真实 Android 中文输入链路录入不超过 20 字的自然标题和至少两行中文正文，并保持真实缩略图、话题、热点同屏可见。只重采 `02_post_filled.png`、`formal_02_post_filled.png`、`formal_06_post_both_relations.png`，重制 `comparison_02_post_filled.png`，更新执行与对照记录。不得使用英文、图片后处理、fixture 或预填充代码。完成后仅提交 Plan 最终复验，不进入 VR8。
