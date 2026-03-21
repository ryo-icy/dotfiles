#!/usr/bin/env bash
# 1Password から SSH 公開鍵をエクスポートする
# export-ssh-keys.sh のラッパー。単独実行可能。

set -euo pipefail

# Nix 管理の op が PATH にない場合は追加する（単独実行時の対応）
export PATH="$HOME/.nix-profile/bin:/nix/var/nix/profiles/default/bin:$PATH"

DOTFILES_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")/../.." && pwd)"

if ! command -v op &>/dev/null; then
  echo "  ERROR: op が見つかりません。先に 05-home-manager.sh を実行してください"
  exit 1
fi

if ! op account list &>/dev/null; then
  echo "  ERROR: op が認証されていません。実行してください: op signin"
  exit 1
fi

bash "$DOTFILES_DIR/scripts/export-ssh-keys.sh"
