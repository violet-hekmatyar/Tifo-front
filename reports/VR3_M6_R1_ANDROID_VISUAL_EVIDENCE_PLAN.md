# VR3-M6-R1 Android 视觉证据收口计划

状态：**Android 证据已重采；Plan 模型复验未通过，转入 VR3-R2 返修**

依据：

- `reports/VR3_FLAGSHIP_MATCH_DETAIL_VISUAL_PARITY_EXECUTION_PLAN.md`
- `reports/VR3_M0_M5_ACCEPTANCE_2026-09-18.md`
- `reports/VR3_M6_EXECUTION_RECORD.md`

## 1. 唯一目标

使用当前真实 API APK 完成 VR3 的 Android 截图、原型逐图对照和视觉收口。不得进入球队详情、球员详情或其他阶段。

固定 ADB：`C:\Users\hekmatyar\AppData\Local\Android\Sdk\platform-tools\adb.exe`  
固定设备：`emulator-5554`  
固定比赛：`15000000000000060`  
当前 APK SHA-256：`F4CE70E3B3C39CC36E7F5F640742ABF21A917187E03DEAC7E315CDAC1AF895D8`

## 2. 执行步骤

### R1-1 环境与 APK

- 直接使用上述 ADB 绝对路径，不再以 PATH 中找不到 `adb` 判定阻塞；
- 确认 `adb devices -l` 中 `emulator-5554` 为 `device`；
- 启动后端并复核 health、旗舰比赛七类关键接口；
- 对 APK 重新计算完整哈希，使用 `install -r` 安装并启动 `com.southstand.tifo`；
- 若源码或资源有任何修改，必须重新构建、安装并更新哈希，旧截图全部作废。

### R1-2 正式截图

在 `reports/VR3_MATCH_DETAIL_VISUAL_PARITY_EVIDENCE/` 使用同一 APK、真实 API 采集：

1. `01_overview_top.png`：头部、五 Tab、最新资讯；
2. `02_overview_stats_events.png`：简要统计与事件中后段；
3. `03_lineup_pitch.png`：两队各 11 首发的完整球场；
4. `04_lineup_bench_legend.png`：教练、替补、伤停空态和图例；
5. `05_stats.png`：真实分组统计与成对比较条；
6. `06_ranking_entry.png`：当前排名及淘汰树入口；
7. `07_knockout_placeholder_return.png`：正在开发占位及可返回证据；
8. `08_ratings_list.png`：球队筛选和真实评分列表；
9. `09_rating_detail.png`：球员资料、单场统计、评分分布、评论/回复；
10. `10_rating_input.png`：星级、数值、评论文本和发布按钮；
11. `11_width_360dp.png`；
12. `12_font_140.png`。

登录写操作使用临时验收账号或既有测试账号，不直接改库。截图不得出现密码、Token、调试浮层、fixture 数据或个人敏感信息。

### R1-3 尺寸与恢复

- 主证据使用 Pixel 8 常规尺寸、100% 字体；记录 `wm size`、`wm density` 和 `font_scale`；
- 360dp 证据按当前 density 计算目标像素宽度，不把 360px 误写成 360dp；
- 140% 证据使用 `font_scale=1.4`；
- 每项适配截图完成后恢复设备原始 size、density 和 font scale，避免污染后续截图。

### R1-4 原型对照

- 为 7 张比赛详情原型生成 `comparison_01.png`～`comparison_07.png`；
- 总览、阵容、统计和评分三态逐项核对模块顺序、比例、间距、字号、配色、圆角、图片裁切和信息密度；
- `球比赛详情-排名.png` 标注为“淘汰树后端专项排除”，对照当前排名＋入口＋占位，不宣称树形复刻通过；
- `VISUAL_COMPARISON.md` 必须如实登记剩余差异，不能用测试通过或无 overflow 代替视觉结论。

## 3. 发现差异时

- 只修比赛详情模块内、经截图证实的视觉问题；不顺带重构公共组件或其他页面；
- 每轮修复后重新构建 APK，全部 12 张截图和 7 张对照图必须来自最后同一哈希；
- 若发现真实 API 数据缺失，先核对 P1 validator 和现有接口，不新增重复 seed；
- 若需要新增业务字段、真实淘汰树或扩大后端模型，停止并提交阻塞，不自行扩项。

## 4. 最小验证

若未修改生产代码，只需复核：

- APK 哈希、安装启动、真实 API smoke；
- 38 项既有定向测试结果仍对应当前源码；
- 两仓 `git diff --check`。

若修改了生产代码，必须重新运行 38 项 Flutter 定向测试、受影响后端定向测试、`flutter analyze`、两个仓库 `git diff --check`，并重新构建 APK。

## 5. 提交门槛

- 12 张正式截图、7 张实际对照图、执行记录和视觉记录齐全；
- 六张纳入原型达到主体结构和数据状态一致，正常态不出现空阵容、空统计、空评分或字母头像；
- 排名专项边界诚实，淘汰树入口、占位和返回可用；
- 所有证据来自同一当前源码 APK；
- 最终只提交 Plan 模型复验，不自行宣布 VR3 通过。

## 6. 交给执行模型的精简任务

任务：
执行 `D:\Football-APP-Front\reports\VR3_M6_R1_ANDROID_VISUAL_EVIDENCE_PLAN.md`，完成 VR3 Android 视觉门禁。

范围：
- 仅安装当前 APK、采集 12 张实机图、生成 7 张原型对照并修正经截图确认的比赛详情视觉差异。
- 不进入球队/球员详情，不实现真实淘汰树，不修改无关后端或数据。

要求：
- 使用 `C:\Users\hekmatyar\AppData\Local\Android\Sdk\platform-tools\adb.exe` 和 `emulator-5554`，不要依赖 PATH。
- 主证据必须是真实 API、同一最终 APK；360dp 按 density 换算，完成后恢复设备设置。

完成标准：
- 12 张截图、7 张对照图、执行记录和视觉记录齐全；六张纳入原型无阻塞差异。
- 若修改代码，重跑 38 项定向测试、analyze、两仓 diff check 并记录新 APK 完整哈希。

执行：
直接执行，不做全仓扫描。只在截图证实存在差异时修改比赛详情代码，完成后统一验证。

最终仅汇报：
- 是否修改代码及文件
- 12 张截图和 7 张对照路径
- 测试/API/APK 哈希
- 剩余视觉差异或阻塞
