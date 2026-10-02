# VR11-R2 Android 证据记录

## 同一最终 APK

| 项目 | 值 |
|---|---|
| APK | `apps/mobile/build/app/outputs/flutter-apk/app-debug.apk` |
| 构建时间 | `2026-09-29 11:13:19` |
| 文件大小 | `213,464,310 bytes` |
| SHA-256 | `CE52FD32E46C1A7697EA2AABFE3BC9CF44A2AEA09363AF660C07B0E73A31DE6B` |
| 设备 | `emulator-5554` |
| 标准/恢复参数 | `1080×2400 / density 420 / font scale 1.0` |

## 正式截图

| 文件 | 尺寸 | SHA-256 | 左上角像素 |
|---|---:|---|---|
| `01_messages.png` | 1080×2400 | `A4B6455C1757193519B8CC82687C284D8E1C0C72F509532B71D5FE4506274C8D` | `255,255,255` |
| `02_interactions.png` | 1080×2400 | `153077365938F8F650C3AE04EE39B3D66FBB2348847AA441782A6217709FE395` | `255,255,255` |
| `03_target_navigation.png` | 1080×2400 | `602726C6A08898B48DCAE05BD2AFE6E49091E071708C548516033BEBDD43C316` | `255,255,255` |
| `04_unavailable_feedback.png` | 1080×2400 | `F6EF9D3B0BDB15ABA8DA564F9A42B19B1B5704D960B0FA31B2FF35A1CF94EB33` | `255,255,255` |
| `05_messages_360dp.png` | 945×2400 | `5BABAD017E5CBF529268270F2433B7F480CD85A7BBFC5B473D243BB7E17854CB` | `255,255,255` |
| `06_interactions_360dp.png` | 945×2400 | `ACC946C155AF637E6A3C0B29083E09C4834E6745C68367DC0575C2681A6075B6` | `255,255,255` |
| `07_messages_140pct.png` | 1080×2400 | `FD80A9328B529BD69B09CC7E607AFFBD57A64BBBA7BF6476E21F6A16C43DA9BF` | `255,255,255` |
| `08_interactions_140pct.png` | 1080×2400 | `76C5CD5F5852CDD44724B51E4134DC5BAAF16E463D2AEB64B895417D5645F3E5` | `255,255,255` |

## 对照图

两张 comparison 均为“原型原图 + 当前 APK 原始截图”的直接双栏图，不嵌套旧对照、不加人工边框：

| 文件 | 尺寸 | SHA-256 |
|---|---:|---|
| `comparison_01_messages.png` | 1500×1667 | `DE14404AD9E465E64974142602D090E67EC0883233D6B33B3F4FC51D7E543F5F` |
| `comparison_02_interactions.png` | 1500×1667 | `6B7774B90E0F67A0962C5FBFF2F03278220C8C81BD8C55D42D981BFC3D489992` |

原型原图均为 `750×1624`，保留原始像素；右侧 APK 图按宽度 750 等比缩放。正式截图和对照图角点均未发现人工绿色边框。

## 状态与几何覆盖

- 标准截图与两张对照图使用全部已读稳定态：无入口红点、列表红点、底部未读角标和“全部已读”图标。
- `03_target_navigation.png` 覆盖真实目标内容跳转；`04_unavailable_feedback.png` 覆盖私信搜索的明确未开放反馈。
- `05_messages_360dp.png`、`06_interactions_360dp.png` 来自 `945×2400 / density 420`，换算为 360dp。
- `07_messages_140pct.png`、`08_interactions_140pct.png` 来自 `font scale 1.4`，互动列表无溢出标记。
- R2 几何目标：标题→首页入口中心约 62dp、标题→互动首头像中心约 60dp、连续通知行距约 60dp。
- 采证结束后设备已恢复为 `1080×2400 / density 420 / font scale 1.0`。
