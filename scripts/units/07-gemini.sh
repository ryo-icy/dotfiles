#!/usr/bin/env bash
# Gemini CLI をインストールする
# npm でインストールする
# 単独実行可能

set -euo pipefail

# Nix 管理の npm が PATH にない場合は追加する（単独実行時の対応）
export PATH="$HOME/.nix-profile/bin:/nix/var/nix/profiles/default/bin:$PATH"

if ! command -v npm &>/dev/null; then
  echo "  ERROR: npm が見つかりません。先に 05-home-manager.sh を実行してください"
  exit 1
fi

if command -v gemini &>/dev/null; then
  echo "  Already installed: $(gemini --version 2>/dev/null || echo 'version unknown')"
else
  npm install -g @google/gemini-cli
  echo "  Installed: $(gemini --version 2>/dev/null || echo 'ok')"
fi
