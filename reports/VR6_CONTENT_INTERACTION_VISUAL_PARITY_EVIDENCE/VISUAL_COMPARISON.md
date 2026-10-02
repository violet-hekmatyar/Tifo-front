# VR6 逐图视觉对照记录

固定对象：`16000000000000201`（圣西罗夜场的压迫感从哪里开始）  
APK：`D:\Football-APP-Front\apps\mobile\build\app\outputs\flutter-apk\app-debug.apk`  
SHA-256：`78B8B35E1D9888F7B2C41F952A47B4896CEACDCA6985D02845AB21DDCF059A51`

| 对照图 | 原型 | 当前 APK 证据 | 对照范围 |
| --- | --- | --- | --- |
| `comparison_01.png` | 帖子详情 | `01_detail_top.png` + `02_detail_lower.png` | 南看台头部、作者关注、标题、轮播主视觉、正文、关联对象与底栏 |
| `comparison_02.png` | 详情分享弹窗 | `03_share_sheet.png` | 圆角底部层、分享标题、关闭、真实可用动作网格 |
| `comparison_03.png` | 资讯主页-评论区 | `04_comments.png` | 独立全屏评论头部、真实根评论、回复预览、底部输入胶囊；详情页不露底 |
| `comparison_04.png` | 资讯主页-评论区回复 | `05_comment_composer.png` | 根评论输入层、键盘、发送动作与纯文本限制 |
| `comparison_05.png` | 资讯主页-回复评论区 | `06_replies.png` | 回复标题、根评论摘要、真实回复列表与回复入口 |
| `comparison_06.png` | 资讯主页-回复评论区回复 | `07_reply_composer.png` | 指定用户回复目标、正文摘要、输入层与键盘 |

补充响应式证据：

- `08_width_360dp.png`：设备宽度 `945px`、density `420`，换算 `945 × 160 ÷ 420 = 360dp`。
- `09_font_140.png`：标准设备下 `font_scale=1.4`；详情标题、正文、标签和底栏均保持在屏内。
- `responsive_360dp_layers.png`：同一固定内容下的分享、评论、根评论输入、回复列表和指定回复输入五层 360dp 证据。
- `responsive_font_140_layers.png`：同一固定内容下的分享、评论、根评论输入、回复列表和指定回复输入五层 140% 字体证据。
- 正式 `01_detail_top.png` 使用 `demo_user_02` 浏览作者 `南看台小旗手`，作者关系通过现有 profile/follow 契约取得，未关注按钮为绿色实心“关注”状态。

VR6-R2 证据补正：正式 `01`～`09`、两张响应式联系表和六张对照图均以本次 APK 为准；设备已恢复 `1080×2400 / density 420 / font_scale 1.0`。关注读取使用 profile，未关注状态通过成对 DELETE/GET 复核后采证，未改后端或数据库。

VR6-R2-E1 证据补正：`r2e1_360_*` 与 `r2e1_140_*` 分别记录分享、评论、根评论输入、回复和指定回复输入五层；两张响应式联系表按相同顺序重制。`comparison_01`～`comparison_06` 已由当前正式 `01`～`07` 截图重新合成，均对应 APK `78B8B35E1D9888F7B2C41F952A47B4896CEACDCA6985D02845AB21DDCF059A51`。

契约边界：分享网格只实现复制路径、复制标题和系统分享；没有伪造微信/朋友圈/小红书/抖音/QQ动作。评论只实现文本输入和真实 `parentId/rootId/replyToUserId` 关系，没有评论图片或 @ 选择器。
