#!/usr/bin/env bash
# Nix を Determinate Systems インストーラーでインストールする
# 単独実行可能

set -euo pipefail

if command -v nix &>/dev/null; then
  echo "  Already installed: $(nix --version)"
else
  curl --proto '=https' --tlsv1.2 -sSf \
    https://install.determinate.systems/nix | sh -s -- install --no-confirm

  echo "  Installed: $(nix --version)"
fi

# Nix を現在のシェルセッションで使えるようにする
# （bootstrap.sh からの呼び出し時にも、単独実行時にも必要）
NIX_PROFILE="/nix/var/nix/profiles/default/etc/profile.d/nix-daemon.sh"
# shellcheck disable=SC1090
[[ -f "$NIX_PROFILE" ]] && source "$NIX_PROFILE"
