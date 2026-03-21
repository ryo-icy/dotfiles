#!/usr/bin/env bash
# 1Password から kubeconfig をエクスポートする
# export-kubeconfig.sh のラッパー。単独実行可能。

set -euo pipefail

# Nix 管理の op が PATH にない場合は追加する（単独実行時の対応）
export PATH="$HOME/.nix-profile/bin:/nix/var/nix/profiles/default/bin:$PATH"

DOTFILES_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")/../.." && pwd)"

if ! command -v op &>/dev/null; then
  echo "  ERROR: op が見つかりません。先に 05-home-manager.sh を実行してください"
  exit 1
fi

if ! op whoami &>/dev/null; then
  echo "  1Password CLI にサインインします..."
  eval "$(op signin)"
fi

bash "$DOTFILES_DIR/scripts/export-kubeconfig.sh"
