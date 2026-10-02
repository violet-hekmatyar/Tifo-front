# VR14-M1 媒体与互动通知执行记录

## 范围

本模块仅修复 VR14 四个根页面所需的 DEMO 媒体引用，并复核已有 VR11 互动通知数据；不修改 API 契约、数据库结构或推荐排序。

## 执行结果

- 为 DEMO 球队及数据页联赛选择器补齐可访问 PNG 队徽，并将演示球队映射到不同图片。
- 为 DEMO 球员、用户头像和历史演示内容统一补齐有效媒体引用。
- 新增幂等、保护式校验与回滚脚本：
  - `D:\Football-APP\scripts\sql\VR14_M1_ROOT_MEDIA_NOTIFICATION_SEED.sql`
  - `D:\Football-APP\scripts\sql\VR14_M1_ROOT_MEDIA_NOTIFICATION_VALIDATOR.sql`
  - `D:\Football-APP\scripts\sql\VR14_M1_ROOT_MEDIA_NOTIFICATION_ROLLBACK.sql`
  - `D:\Football-APP\scripts\sql\VR14_M1_ROOT_MEDIA_NOTIFICATION_MANIFEST.md`
- Seed 连续执行两次，Validator 连续执行两次，均为 `invalid_count=0`。
- VR11 通知只读复核：总数 8，未读数 5；未执行通知写入或删除。
- 目标 PNG 通过 HTTP 访问，返回 `200` 与 `image/png`。
- 数据页与首页使用到的演示联赛、球队、关注球员、用户头像和内容封面不再引用 Flutter 无法解码的占位 SVG。
- 后端已通过普通 Windows 启动方式重启，健康检查返回 `code=0`。

## 结论

M1 数据与媒体闭环完成，可进入 M2 首页根页面修复。
