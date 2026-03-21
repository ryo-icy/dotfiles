#!/usr/bin/env bash
# Claude CLI をインストールする
# auto-updater があるため Nix では管理しない。npm でインストールする。
# 単独実行可能

set -euo pipefail

# Nix 管理の npm が PATH にない場合は追加する（単独実行時の対応）
export PATH="$HOME/.nix-profile/bin:/nix/var/nix/profiles/default/bin:$PATH"

if ! command -v npm &>/dev/null; then
  echo "  ERROR: npm が見つかりません。先に 05-home-manager.sh を実行してください"
  exit 1
fi

if command -v claude &>/dev/null; then
  echo "  Already installed: $(claude --version 2>/dev/null || echo 'version unknown')"
else
  npm install -g @anthropic-ai/claude-code
  echo "  Installed: $(claude --version 2>/dev/null || echo 'ok')"
fi
