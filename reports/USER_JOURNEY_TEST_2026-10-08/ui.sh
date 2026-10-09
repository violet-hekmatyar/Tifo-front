#!/usr/bin/env bash
# UI 交互小工具：基于 Flutter 语义树 (uiautomator dump) 精确定位元素
export PATH="$PATH:/c/Users/hekmatyar/AppData/Local/Android/Sdk/platform-tools"
export MSYS_NO_PATHCONV=1
SHOTS="D:/Football-APP-Front/reports/USER_JOURNEY_TEST_2026-10-08/shots"

ui_dump() {
  adb shell uiautomator dump /sdcard/ui.xml >/dev/null 2>&1
  adb exec-out cat /sdcard/ui.xml > /tmp/ui.xml 2>/dev/null
}

# ui_find <substr>  -> "cx cy"   (第一个匹配元素的中心点)
ui_find() {
  tr '<' '\n' < /tmp/ui.xml | grep 'content-desc' | grep -F "$1" \
    | sed -E 's/.*bounds="\[([0-9]+),([0-9]+)\]\[([0-9]+),([0-9]+)\]".*/\1 \2 \3 \4/' \
    | awk 'NF==4{printf "%d %d\n", ($1+$3)/2, ($2+$4)/2; exit}'
}

# ui_tap <substr>
ui_tap() {
  local c; c=$(ui_find "$1")
  if [ -z "$c" ]; then echo "NOT_FOUND: $1"; return 1; fi
  adb shell input tap $c; echo "tap($c) <- $1"
}

# ui_list  -> 所有可点击元素的中心点（排查用）
ui_list() {
  tr '<' '\n' < /tmp/ui.xml | grep 'content-desc' \
    | sed -E 's/.*content-desc="([^"]*)".*clickable="([^"]*)".*bounds="\[([0-9]+),([0-9]+)\]\[([0-9]+),([0-9]+)\]".*/\2|\1|\3 \4 \5 \6/' \
    | awk -F'|' '{split($3,b," "); cx=(b[1]+b[3])/2; cy=(b[2]+b[4])/2; printf "[%s] %-40s (%d,%d)\n", $1, substr($2,1,40), cx, cy}'
}

# ui_shot <name>
ui_shot() { adb exec-out screencap -p > "$SHOTS/$1.png"; echo "shot: $1"; }

# ui_type <text>  —— 输入 ASCII
ui_type() { adb shell input text "$1"; sleep 0.6; }

# ui_back —— 隐藏键盘（先确认键盘可见再调用）
ui_back() { adb shell input keyevent 4; sleep 0.8; }

# ui_ime  -> shown|hidden
ui_ime() {
  if adb shell dumpsys input_method 2>/dev/null | grep -q "mInputShown=true"; then echo shown; else echo hidden; fi
}
