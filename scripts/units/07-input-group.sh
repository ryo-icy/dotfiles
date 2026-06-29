#!/usr/bin/env bash
# input グループにユーザーを追加する（タッチパッドジェスチャー用）
# libinput-gestures が /dev/input/event* を読むために必要
# 単独実行可能

set -euo pipefail

if id -nG "$USER" | grep -qw input; then
  echo "  Already in group: input"
else
  sudo usermod -aG input "$USER"
  echo "  Added to group: input"
  echo "  NOTE: input グループの反映には再ログインが必要です"
fi
