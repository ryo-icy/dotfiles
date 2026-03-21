#!/usr/bin/env bash
# npiperelay.exe をダウンロードする
# 1Password SSH Agent の Windows named pipe を Unix ソケットにブリッジするために使用する
# 単独実行可能

set -euo pipefail

NPIPE_VERSION="v0.1.0"
NPIPE_URL="https://github.com/jstarks/npiperelay/releases/download/${NPIPE_VERSION}/npiperelay_windows_amd64.zip"
NPIPE_DEST="$HOME/bin/npiperelay.exe"

mkdir -p "$HOME/bin"

if [[ -f "$NPIPE_DEST" ]]; then
  echo "  Already present: $NPIPE_DEST"
  exit 0
fi

if ! command -v unzip &>/dev/null; then
  echo "  ERROR: unzip が見つかりません。インストールしてください: sudo apt install unzip"
  exit 1
fi

curl -fsSL "$NPIPE_URL" -o /tmp/npiperelay.zip
unzip -jo /tmp/npiperelay.zip "npiperelay.exe" -d "$HOME/bin/"
rm /tmp/npiperelay.zip

echo "  Installed: $NPIPE_DEST"
