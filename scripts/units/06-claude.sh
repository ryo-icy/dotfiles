#!/usr/bin/env bash
# Claude CLI をインストールする
# auto-updater があるため Nix では管理しない。公式ネイティブインストーラーでインストールする。
# 単独実行可能

set -euo pipefail

CLAUDE_BIN="$HOME/.local/bin/claude"

if [[ -f "$CLAUDE_BIN" ]]; then
  echo "  Already installed: $("$CLAUDE_BIN" --version 2>/dev/null || echo 'version unknown')"
else
  curl -fsSL https://claude.ai/install.sh | bash
  echo "  Installed"
fi
