#!/usr/bin/env bash
# karukan (fcitx5 アドオン) をユーザーローカルにビルド・インストールする
# GPT-2 ベースのニューラルかな漢字変換エンジン。nixpkgs 未収録のため手動ビルド。
# インストール先: ~/.local/lib/fcitx5/ (FCITX_ADDON_DIRS は home-manager 側で設定済み)
# 単独実行可能

set -euo pipefail

INSTALL_MARKER="$HOME/.local/lib/fcitx5"

if compgen -G "$INSTALL_MARKER/libkarukan*.so" > /dev/null 2>&1; then
  echo "  Already installed: karukan fcitx5 addon"
  exit 0
fi

# Rust (cargo) の確認
if ! command -v cargo &>/dev/null; then
  echo "  ERROR: cargo が見つかりません。先に Rust をインストールしてください:" >&2
  echo "    mise use -g rust@latest" >&2
  exit 1
fi

# fcitx5 ビルド依存
echo "  Installing fcitx5 build dependencies..."
sudo apt-get install -y -qq \
  fcitx5-modules-dev libfcitx5core-dev libfcitx5config-dev \
  libfcitx5utils-dev extra-cmake-modules cmake gcc g++ \
  clang libclang-dev libssl-dev libxkbcommon-dev

# ビルド
TMPDIR="$(mktemp -d)"
trap 'rm -rf "$TMPDIR"' EXIT

echo "  Cloning karukan..."
git clone --depth 1 --quiet https://github.com/togatoga/karukan "$TMPDIR/karukan"

echo "  Building karukan fcitx5 addon..."
cmake -B "$TMPDIR/build" \
  -S "$TMPDIR/karukan/karukan-fcitx5/fcitx5-addon" \
  -DCMAKE_INSTALL_PREFIX="$HOME/.local" \
  -DCMAKE_BUILD_TYPE=Release \
  > /dev/null

cmake --build "$TMPDIR/build" -j"$(nproc)" > /dev/null

cmake --install "$TMPDIR/build" > /dev/null

echo "  Installed: karukan fcitx5 addon -> ~/.local/lib/fcitx5/"
