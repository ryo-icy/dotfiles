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

# /etc/nix/nix.conf は Determinate Systems が管理・上書きするため変更しない。
# ユーザー設定は nix.custom.conf（!include で読み込まれる）に書き込む。
CURRENT_USER="$(whoami)"
NIX_CUSTOM_CONF="/etc/nix/nix.custom.conf"
DAEMON_RESTARTED=false

# trusted-users に自ユーザーを追加する
# cachix use や flake の nixConfig 内 substituter を有効にするために必要
if grep -qF "trusted-users" "$NIX_CUSTOM_CONF" 2>/dev/null; then
  echo "  trusted-users already configured"
else
  echo "  Configuring trusted-users in ${NIX_CUSTOM_CONF}..."
  echo "trusted-users = root ${CURRENT_USER}" | sudo tee -a "$NIX_CUSTOM_CONF" >/dev/null
  DAEMON_RESTARTED=true
  echo "  Configured"
fi

# cachix (ryo-icy-dotfiles) を substituter としてグローバルに登録する
# flake.nix の nixConfig でも宣言しているが、フラグ外の nix コマンドでも有効にするため追記する
CACHIX_URL="https://ryo-icy-dotfiles.cachix.org"
if grep -qF "$CACHIX_URL" "$NIX_CUSTOM_CONF" 2>/dev/null; then
  echo "  cachix already configured"
else
  echo "  Configuring cachix in ${NIX_CUSTOM_CONF}..."
  printf 'extra-substituters = %s\nextra-trusted-public-keys = ryo-icy-dotfiles.cachix.org-1:b0DWdQSrNhcUcy0WcXH3JuAK4KqA3wGayM9T4YRdpBk=\n' "$CACHIX_URL" \
    | sudo tee -a "$NIX_CUSTOM_CONF" >/dev/null
  DAEMON_RESTARTED=true
  echo "  Configured"
fi

if [[ "$DAEMON_RESTARTED" == "true" ]]; then
  sudo systemctl restart nix-daemon 2>/dev/null || sudo pkill nix-daemon 2>/dev/null || true
fi
