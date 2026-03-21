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

NPM_PREFIX="$HOME/.local"
export PATH="$NPM_PREFIX/bin:$PATH"

if [[ -f "$NPM_PREFIX/bin/gemini" ]]; then
  echo "  Already installed: $("$NPM_PREFIX/bin/gemini" --version 2>/dev/null || echo 'version unknown')"
else
  npm install -g --prefix "$NPM_PREFIX" @google/gemini-cli
  echo "  Installed: $("$NPM_PREFIX/bin/gemini" --version 2>/dev/null || echo 'ok')"
fi
