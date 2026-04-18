#!/bin/sh
# Claude Code statusLine コマンド
# 3行構成のステータスライン:
#   1行目: モデル名 │ コンテキスト使用率 │ git diff 統計 │ ブランチ名
#   2行目: 5時間レートリミット プログレスバー + リセット時刻
#   3行目: 7日間レートリミット プログレスバー + リセット日時

# カラーコード（ANSI 256色 / 24bit はターミナル依存のため SGR で近似）
# #97C9C3 → cyan (緑寄り), #E5C07B → yellow, #E06C75 → red, #4A585C → gray
COLOR_GREEN="\033[38;2;151;201;195m"
COLOR_YELLOW="\033[38;2;229;192;123m"
COLOR_RED="\033[38;2;224;108;117m"
COLOR_GRAY="\033[38;2;74;88;92m"
COLOR_RESET="\033[0m"

SEP="${COLOR_GRAY} │ ${COLOR_RESET}"

# 使用率に応じた色を返す関数
color_for_pct() {
  pct="$1"
  if [ -z "$pct" ] || [ "$pct" -lt 50 ] 2>/dev/null; then
    printf "%s" "$COLOR_GREEN"
  elif [ "$pct" -lt 80 ] 2>/dev/null; then
    printf "%s" "$COLOR_YELLOW"
  else
    printf "%s" "$COLOR_RED"
  fi
}

# プログレスバーを生成する関数（10セグメント）
progress_bar() {
  pct="$1"
  filled=$(( pct / 10 ))
  [ "$filled" -gt 10 ] && filled=10
  empty=$(( 10 - filled ))
  bar=""
  i=0
  while [ "$i" -lt "$filled" ]; do
    bar="${bar}▰"
    i=$(( i + 1 ))
  done
  i=0
  while [ "$i" -lt "$empty" ]; do
    bar="${bar}▱"
    i=$(( i + 1 ))
  done
  printf "%s" "$bar"
}

# Unix timestamp を Asia/Tokyo の日時文字列に変換する関数
format_reset_time() {
  ts="$1"
  fmt="$2"  # date フォーマット文字列
  if [ -z "$ts" ] || [ "$ts" = "null" ]; then
    printf "%s" "-"
    return
  fi
  TZ="Asia/Tokyo" date -d "@${ts}" +"${fmt}" 2>/dev/null \
    || TZ="Asia/Tokyo" date -r "${ts}" +"${fmt}" 2>/dev/null \
    || date -u -d "@$(( ts + 32400 ))" +"${fmt}" 2>/dev/null \
    || date -u -r "$(( ts + 32400 ))" +"${fmt}" 2>/dev/null \
    || printf "%s" "-"
}

# stdin から JSON を読み込む
input=$(cat)

# 1行目: モデル名
model=$(printf "%s" "$input" | jq -r '.model.display_name // "Unknown"')

# 1行目: コンテキスト使用率
ctx_used=$(printf "%s" "$input" | jq -r '.context_window.used_percentage // empty')
if [ -n "$ctx_used" ]; then
  ctx_int=$(printf "%.0f" "$ctx_used" 2>/dev/null || echo "0")
  ctx_color=$(color_for_pct "$ctx_int")
  ctx_str="${ctx_color}ctx:${ctx_int}%${COLOR_RESET}"
else
  ctx_str="${COLOR_GRAY}ctx:-${COLOR_RESET}"
fi

# 1行目: git diff 統計（追加/削除行数）
cwd=$(printf "%s" "$input" | jq -r '.workspace.current_dir // .cwd // ""')
git_diff=""
if [ -n "$cwd" ]; then
  diff_stat=$(GIT_OPTIONAL_LOCKS=0 git -C "$cwd" diff --shortstat HEAD 2>/dev/null)
  if [ -n "$diff_stat" ]; then
    ins=$(printf "%s" "$diff_stat" | grep -oE '[0-9]+ insertion' | grep -oE '[0-9]+' || echo "0")
    del=$(printf "%s" "$diff_stat" | grep -oE '[0-9]+ deletion'  | grep -oE '[0-9]+' || echo "0")
    [ -z "$ins" ] && ins="0"
    [ -z "$del" ] && del="0"
    git_diff="${COLOR_GREEN}+${ins}${COLOR_RESET}${COLOR_GRAY}/${COLOR_RESET}${COLOR_RED}-${del}${COLOR_RESET}"
  else
    git_diff="${COLOR_GRAY}+0/-0${COLOR_RESET}"
  fi
fi

# 1行目: git ブランチ名
branch=""
if [ -n "$cwd" ]; then
  branch=$(GIT_OPTIONAL_LOCKS=0 git -C "$cwd" symbolic-ref --short HEAD 2>/dev/null \
           || GIT_OPTIONAL_LOCKS=0 git -C "$cwd" rev-parse --short HEAD 2>/dev/null)
fi

# 1行目を組み立てて出力
line1="${COLOR_GREEN}${model}${COLOR_RESET}"
line1="${line1}${SEP}${ctx_str}"
if [ -n "$git_diff" ]; then
  line1="${line1}${SEP}${git_diff}"
fi
if [ -n "$branch" ]; then
  line1="${line1}${SEP}${COLOR_GRAY}${branch}${COLOR_RESET}"
fi
printf "%b\n" "$line1"

# --- 2行目: 5時間レートリミット ---
five_pct=$(printf "%s" "$input" | jq -r '.rate_limits.five_hour.used_percentage // empty')
five_reset=$(printf "%s" "$input" | jq -r '.rate_limits.five_hour.resets_at // empty')

if [ -n "$five_pct" ]; then
  five_int=$(printf "%.0f" "$five_pct" 2>/dev/null || echo "0")
  five_color=$(color_for_pct "$five_int")
  five_bar=$(progress_bar "$five_int")
  five_time=$(format_reset_time "$five_reset" "%H:%M")
  printf "%b" "${COLOR_GRAY}5h ${COLOR_RESET}${five_color}${five_bar} ${five_int}%${COLOR_RESET}${COLOR_GRAY} reset:${five_time}${COLOR_RESET}\n"
else
  printf "%b" "${COLOR_GRAY}5h -${COLOR_RESET}\n"
fi

# --- 3行目: 7日間レートリミット ---
week_pct=$(printf "%s" "$input" | jq -r '.rate_limits.seven_day.used_percentage // empty')
week_reset=$(printf "%s" "$input" | jq -r '.rate_limits.seven_day.resets_at // empty')

if [ -n "$week_pct" ]; then
  week_int=$(printf "%.0f" "$week_pct" 2>/dev/null || echo "0")
  week_color=$(color_for_pct "$week_int")
  week_bar=$(progress_bar "$week_int")
  week_time=$(format_reset_time "$week_reset" "%m/%d %H:%M")
  printf "%b" "${COLOR_GRAY}7d ${COLOR_RESET}${week_color}${week_bar} ${week_int}%${COLOR_RESET}${COLOR_GRAY} reset:${week_time}${COLOR_RESET}\n"
else
  printf "%b" "${COLOR_GRAY}7d -${COLOR_RESET}\n"
fi
