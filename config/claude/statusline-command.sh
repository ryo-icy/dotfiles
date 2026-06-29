#!/bin/sh
# Claude Code statusLine コマンド
# 3行構成のステータスライン:
#   1行目: モデル名 │ ctx ● X% │ git diff 統計 │ ブランチ名
#   2行目: 5時間レートリミット ● X% + リセット時刻
#   3行目: 7日間レートリミット ● X% + リセット日時

COLOR_GREEN="\033[38;2;151;201;195m"
COLOR_RED="\033[38;2;224;108;117m"
COLOR_GRAY="\033[38;2;74;88;92m"
COLOR_RESET="\033[0m"
COLOR_BOLD="\033[1m"

SEP="${COLOR_GRAY} │ ${COLOR_RESET}"

gradient_color() {
  pct="$1"
  if [ -z "$pct" ] || ! [ "$pct" -ge 0 ] 2>/dev/null; then
    printf "\033[38;2;0;200;80m"
    return
  fi
  if [ "$pct" -lt 50 ]; then
    r=$(( pct * 51 / 10 ))
    printf "\033[38;2;%d;200;80m" "$r"
  else
    g=$(( 200 - (pct - 50) * 4 ))
    [ "$g" -lt 0 ] && g=0
    printf "\033[38;2;255;%d;60m" "$g"
  fi
}

format_reset_time() {
  ts="$1"
  fmt="$2"
  if [ -z "$ts" ] || [ "$ts" = "null" ]; then
    printf "%s" "-"
    return
  fi
  TZ="Asia/Tokyo" date -d "@${ts}" +"${fmt}" 2>/dev/null ||
    TZ="Asia/Tokyo" date -r "${ts}" +"${fmt}" 2>/dev/null ||
    date -u -d "@$((ts + 32400))" +"${fmt}" 2>/dev/null ||
    date -u -r "$((ts + 32400))" +"${fmt}" 2>/dev/null ||
    printf "%s" "-"
}

input=$(cat)

# 1行目: モデル名
model=$(printf "%s" "$input" | jq -r '.model.display_name // "Unknown"')

# 1行目: コンテキスト使用率
ctx_used=$(printf "%s" "$input" | jq -r '.context_window.used_percentage // empty')
if [ -n "$ctx_used" ]; then
  ctx_int=$(printf "%.0f" "$ctx_used" 2>/dev/null || echo "0")
  ctx_color=$(gradient_color "$ctx_int")
  ctx_str="ctx ${ctx_color}●${COLOR_RESET} ${COLOR_BOLD}${ctx_int}%${COLOR_RESET}"
else
  ctx_str="${COLOR_GRAY}ctx -${COLOR_RESET}"
fi

# 1行目: git diff 統計と ブランチ名
cwd=$(printf "%s" "$input" | jq -r '.workspace.current_dir // .cwd // ""')
git_diff=""
branch=""
if [ -n "$cwd" ]; then
  diff_stat=$(GIT_OPTIONAL_LOCKS=0 git -C "$cwd" diff --shortstat HEAD 2>/dev/null)
  if [ -n "$diff_stat" ]; then
    ins=$(printf "%s" "$diff_stat" | grep -oE '[0-9]+ insertion' | grep -oE '[0-9]+' || echo "0")
    del=$(printf "%s" "$diff_stat" | grep -oE '[0-9]+ deletion' | grep -oE '[0-9]+' || echo "0")
    [ -z "$ins" ] && ins="0"
    [ -z "$del" ] && del="0"
    git_diff="${COLOR_GREEN}+${ins}${COLOR_RESET}${COLOR_GRAY}/${COLOR_RESET}${COLOR_RED}-${del}${COLOR_RESET}"
  else
    git_diff="${COLOR_GRAY}+0/-0${COLOR_RESET}"
  fi
  branch=$(GIT_OPTIONAL_LOCKS=0 git -C "$cwd" symbolic-ref --short HEAD 2>/dev/null ||
    GIT_OPTIONAL_LOCKS=0 git -C "$cwd" rev-parse --short HEAD 2>/dev/null)
fi

# 1行目を組み立てて出力
line1="${COLOR_BOLD}${model}${COLOR_RESET}${SEP}${ctx_str}"
if [ -n "$git_diff" ]; then
  line1="${line1}${SEP}${git_diff}"
fi
if [ -n "$branch" ]; then
  line1="${line1}${SEP}${COLOR_GRAY}${branch}${COLOR_RESET}"
fi
printf "%b\n" "$line1"

# 2行目: 5時間レートリミット
five_pct=$(printf "%s" "$input" | jq -r '.rate_limits.five_hour.used_percentage // empty')
five_reset=$(printf "%s" "$input" | jq -r '.rate_limits.five_hour.resets_at // empty')
if [ -n "$five_pct" ]; then
  five_int=$(printf "%.0f" "$five_pct" 2>/dev/null || echo "0")
  five_color=$(gradient_color "$five_int")
  five_time=$(format_reset_time "$five_reset" "%H:%M")
  printf "%b\n" "${COLOR_GRAY}5h ${five_color}●${COLOR_RESET} ${COLOR_BOLD}${five_int}%${COLOR_RESET}${COLOR_GRAY} reset:${five_time}${COLOR_RESET}"
else
  printf "%b\n" "${COLOR_GRAY}5h -${COLOR_RESET}"
fi

# 3行目: 7日間レートリミット
week_pct=$(printf "%s" "$input" | jq -r '.rate_limits.seven_day.used_percentage // empty')
week_reset=$(printf "%s" "$input" | jq -r '.rate_limits.seven_day.resets_at // empty')
if [ -n "$week_pct" ]; then
  week_int=$(printf "%.0f" "$week_pct" 2>/dev/null || echo "0")
  week_color=$(gradient_color "$week_int")
  week_time=$(format_reset_time "$week_reset" "%m/%d %H:%M")
  printf "%b\n" "${COLOR_GRAY}7d ${week_color}●${COLOR_RESET} ${COLOR_BOLD}${week_int}%${COLOR_RESET}${COLOR_GRAY} reset:${week_time}${COLOR_RESET}"
else
  printf "%b\n" "${COLOR_GRAY}7d -${COLOR_RESET}"
fi
