#!/usr/bin/env bash
# Wayland セッションパッケージをインストールする（KDE Plasma Wayland セッション用）
# plasma-workspace-wayland がないと SDDM にセッション選択が表示されない
# 単独実行可能

set -euo pipefail

if dpkg -l plasma-workspace-wayland &>/dev/null 2>&1; then
  echo "  Already installed: plasma-workspace-wayland"
else
  sudo apt-get install -y -qq plasma-workspace-wayland
  echo "  Installed: plasma-workspace-wayland"
fi
