#!/usr/bin/env bash
# デフォルトシェルを zsh に変更する
# 単独実行可能

set -euo pipefail

# Nix 管理の zsh が PATH にない場合は追加する（単独実行時の対応）
export PATH="$HOME/.nix-profile/bin:/nix/var/nix/profiles/default/bin:$PATH"

ZSH_PATH="$(command -v zsh)"

if [[ -z "$ZSH_PATH" ]]; then
  echo "  ERROR: zsh が見つかりません。先に 05-home-manager.sh を実行してください"
  exit 1
fi

# /etc/shells に zsh が登録されていなければ追加する（chsh の要件）
if ! grep -qF "$ZSH_PATH" /etc/shells; then
  echo "  /etc/shells に $ZSH_PATH を追加します..."
  echo "$ZSH_PATH" | sudo tee -a /etc/shells >/dev/null
fi

CURRENT_SHELL="$(getent passwd "$USER" | cut -d: -f7)"
if [[ "$CURRENT_SHELL" == "$ZSH_PATH" ]]; then
  echo "  Already default: $ZSH_PATH"
else
  chsh -s "$ZSH_PATH"
  echo "  Default shell changed to: $ZSH_PATH"
fi
