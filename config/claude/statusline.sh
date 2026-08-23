#!/usr/bin/env bash
# ------------------------------------------------------------------------------
# Claude Code custom statusline
#   context / current(5h) / weekly(7d) の3本のバー + モデル名 + effort + cwd
# 依存: jq
#
# インストール:
#   1) このファイルを ~/.claude/statusline.sh に保存
#   2) chmod +x ~/.claude/statusline.sh
#   3) ~/.claude/settings.json に以下を追記:
#        { "statusLine": { "type": "command",
#                          "command": "~/.claude/statusline.sh",
#                          "padding": 0 } }
# ------------------------------------------------------------------------------

input=$(cat)

# ---- 設定 --------------------------------------------------------------------
BAR_WIDTH=14          # バーのドット数
BADGE_COL=45          # 右側バッジ(モデル名 / effort)を始める桁
FILL="●"              # 使用済みドット
EMPTY="○"             # 空きドット
DETECT_ULTRATHINK=1   # 直近のトランスクリプトから "ultrathink" を推定表示

# ---- 色 (24bit truecolor) ----------------------------------------------------
c_label=$'\033[1;38;5;253m'          # ラベル(太字・白)
c_fill=$'\033[38;2;120;200;130m'     # 緑 (使用済みドット)
c_empty=$'\033[38;5;240m'            # 灰 (空きドット)
c_pct=$'\033[38;5;245m'              # 灰 (%)
c_sep=$'\033[38;5;240m'              # 灰 (区切り |)
c_blue=$'\033[38;2;135;165;235m'     # 青紫 (残トークン / モデル名)
c_purple=$'\033[38;2;180;150;225m'   # 紫 (ultrathink)
c_green=$'\033[38;2;120;200;130m'    # 緑 (effort)
c_dim=$'\033[38;5;245m'              # 灰 (時刻)
c_path=$'\033[38;2;226;140;140m'     # サーモン (パス)
c_reset=$'\033[0m'

# ---- ヘルパ ------------------------------------------------------------------
j() { printf '%s' "$input" | jq -r "$1 // empty"; }

# 3桁区切りカンマ (macOS標準のBash 3.2でも動作)
commas() {
  local number group result=""
  IFS= read -r number
  while ((${#number} > 3)); do
    group=${number: -3}
    result=",${group}${result}"
    number=${number:0:${#number}-3}
  done
  printf '%s%s\n' "$number" "$result"
}

# 0-100 の割合を BAR_WIDTH 個のドットに
bar() {
  local pct=$1 filled i out=""
  filled=$(awk -v p="$pct" -v w="$BAR_WIDTH" 'BEGIN{f=int(p*w/100+0.5); if(f<0)f=0; if(f>w)f=w; print f}')
  for ((i=0; i<BAR_WIDTH; i++)); do
    if ((i < filled)); then out+="${c_fill}${FILL}"; else out+="${c_empty}${EMPTY}"; fi
  done
  printf '%s%s' "$out" "$c_reset"
}

# unix秒 -> strftime。GNU date / BSD(macOS) date 両対応
fmt() {
  local ts=$1 f=$2
  [ -z "$ts" ] && { printf ''; return; }
  if date -d "@$ts" +%Y >/dev/null 2>&1; then date -d "@$ts" +"$f"      # GNU
  else date -r "$ts" +"$f"; fi                                          # BSD
}
# 先頭0を除去して小文字化: "01:00PM"->"1:00pm", "Feb 07,..."->"feb 7,..."
tidy() { tr 'A-Z' 'a-z' | sed 's/^0//; s/ 0/ /g'; }

# ---- 値の取得 ----------------------------------------------------------------
model=$(j '.model.display_name'); [ -z "$model" ] && model="Claude"
cwd=$(j '.workspace.current_dir'); [ -z "$cwd" ] && cwd=$(j '.cwd')
transcript=$(j '.transcript_path')

ctx_pct=$(printf '%s' "$input" | jq -r '.context_window.used_percentage // 0')
ctx_size=$(printf '%s' "$input" | jq -r '.context_window.context_window_size // 200000')
five_pct=$(printf '%s' "$input" | jq -r '.rate_limits.five_hour.used_percentage // 0')
five_ts=$(j '.rate_limits.five_hour.resets_at')
week_pct=$(printf '%s' "$input" | jq -r '.rate_limits.seven_day.used_percentage // 0')
week_ts=$(j '.rate_limits.seven_day.resets_at')

# 表示用に整数へ丸め
ri() { awk -v x="$1" 'BEGIN{printf "%d", x+0.5}'; }
ctx_i=$(ri "$ctx_pct"); five_i=$(ri "$five_pct"); week_i=$(ri "$week_pct")

# 残りトークン(割合ベース=バーと一致させる)
left=$(awk -v s="$ctx_size" -v p="$ctx_pct" 'BEGIN{printf "%d", s*(100-p)/100 + 0.5}' | commas)

# 時刻整形
five_when=$(fmt "$five_ts" "%I:%M%p" | tidy)                 # 1:00pm
week_when=$(fmt "$week_ts" "%b %d, %I:%M%p" | tidy)          # feb 7, 11:00am

# effort: stdin -> 環境変数 -> settings.json -> 既定
effort=$(printf '%s' "$input" | jq -r '.effort.level // .model.reasoning_effort // empty')
[ -z "$effort" ] && effort="${CLAUDE_CODE_EFFORT_LEVEL:-}"
if [ -z "$effort" ] && [ -f "$HOME/.claude/settings.json" ]; then
  effort=$(jq -r '.effortLevel // .effort // empty' "$HOME/.claude/settings.json" 2>/dev/null)
fi
[ -z "$effort" ] && effort="medium"

# ultrathink: 直近のトランスクリプトからの推定(あくまでヒューリスティック)
think=""
if [ "$DETECT_ULTRATHINK" = "1" ] && [ -n "$transcript" ] && [ -f "$transcript" ]; then
  if tail -n 40 "$transcript" 2>/dev/null | grep -qiE 'ultrathink|think (harder|longer|intensely)'; then
    think="ultrathink"
  fi
fi

# ---- 1行を組み立て -----------------------------------------------------------
# 可視レイアウト: [label(9)][bar(W)][ ][pct(4)][ | ][value] ...[badge]
render() {
  local label=$1 pct=$2 value=$3 vcolor=$4 badge=$5
  local lbl pctstr barc plen pad spaces
  lbl=$(printf '%-9s' "$label")
  pctstr=$(printf '%3d%%' "$pct")
  barc=$(bar "$pct")
  plen=$(( 9 + BAR_WIDTH + 1 + 4 + 3 + ${#value} ))
  pad=$(( BADGE_COL - plen )); ((pad < 1)) && pad=1
  spaces=$(printf '%*s' "$pad" '')
  local line="${c_label}${lbl}${c_reset}${barc} ${c_pct}${pctstr}${c_reset} ${c_sep}|${c_reset} ${vcolor}${value}${c_reset}"
  [ -n "$badge" ] && line="${line}${spaces}${badge}"
  printf '%s\n' "$line"
}

# 右側バッジ
badge1="${c_blue}${model}${c_reset}"
[ -n "$think" ] && badge1="${badge1} ${c_purple}${think}${c_reset}"
badge2="${c_green}${effort} effort${c_reset}"

render "context:" "$ctx_i"  "${left} left"  "$c_blue" "$badge1"
render "current:" "$five_i" "${five_when}"  "$c_dim"  "$badge2"
render "weekly:"  "$week_i" "${week_when}"  "$c_dim"  ""
printf '%s%s%s\n' "$c_path" "$cwd" "$c_reset"
