#!/usr/bin/env bash
# Nix を Determinate Systems インストーラーでインストールする
# 単独実行可能

set -euo pipefail

if command -v nix &>/dev/null || [ -e /nix/var/nix/profiles/default/bin/nix ]; then
  echo "  Already installed"
else
  echo "  Installing Nix (Determinate Systems installer)..."
  if [ "${CI:-}" = "true" ]; then
    curl --proto '=https' --tlsv1.2 -sSf -L https://install.determinate.systems/nix |
      sh -s -- install linux --no-confirm --init none
  else
    curl --proto '=https' --tlsv1.2 -sSf -L https://install.determinate.systems/nix |
      sh -s -- install --no-confirm
  fi
  echo "  Installed"
fi

# Nix を現在のシェルセッションで使えるようにする
# （bootstrap.sh からの呼び出し時にも、単独実行時にも必要）
NIX_PROFILE="/nix/var/nix/profiles/default/etc/profile.d/nix-daemon.sh"
# shellcheck disable=SC1090
[[ -f "$NIX_PROFILE" ]] && source "$NIX_PROFILE"

# trusted-users に自ユーザーを追加する
# cachix use や flake の nixConfig 内 substituter を有効にするために必要
CURRENT_USER="$(whoami)"
if grep -qF "trusted-users" /etc/nix/nix.conf 2>/dev/null; then
  echo "  trusted-users already configured"
else
  echo "  Configuring trusted-users in /etc/nix/nix.conf..."
  echo "trusted-users = root ${CURRENT_USER}" | sudo tee -a /etc/nix/nix.conf >/dev/null
  sudo pkill nix-daemon 2>/dev/null || true
  echo "  Configured"
fi
