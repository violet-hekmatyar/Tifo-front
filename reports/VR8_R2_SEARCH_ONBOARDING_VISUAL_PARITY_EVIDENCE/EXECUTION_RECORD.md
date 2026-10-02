# VR8-R2-E1 执行记录

日期：2026-09-23

## E1 证据收口结果

- 固定 APK 未重建，SHA-256 与 `APK_HASH.txt` 中的计划值一致。
- 使用已有完成 onboarding 的 DEMO 账号通过正常登录流程建立会话；未创建账号、未提交 preferences、未执行写入型业务请求。
- `GET /api/auth/me`：HTTP 200，`code=0`；账号 ID 10002，`onboardingCompleted=true`，`mainTeamId=30001`。
- `GET /api/app/onboarding/options`：HTTP 200，`code=0`；球队选项 1 条，球员选项 1 条。
- 真实搜索关键词仅用于产生确定空态，搜索接口返回 HTTP 200、`code=0`、`records=0`、`total=0`；正式截图为 `00_search_empty.png`。
- 四张 comparison 已使用桌面原型原始 PNG 与当前 APK 原始单屏 PNG 重新生成，均为严格两栏，不使用旧合成图作为输入。
- 调试图、登录过程图和 XML 已移入 `debug/`，不属于正式证据。
- 设备已恢复为 1080×2400、density 420、font scale 1.0。

## 沿用的 R2 基线

- VR8-R2 冻结集合、VR8 新增几何/交互测试、VR7 共享回归及发布返回回归合计 70 项通过（本轮未重复运行）。
- `flutter analyze`：通过。
- 前后端 `git diff --check`：通过。
- Android 已用同一 APK 采集主队、关注球队、关注球员、360dp 和 140% 字体证据；本轮追加真实搜索空态。

## 冻结声明

- 本轮未修改生产代码、测试、后端、数据库、SQL、Seed、API 契约或 APK。
- VR8 仍等待 Plan 模型复验；执行模型不自行宣布 VR8 通过，也不进入 VR9。
