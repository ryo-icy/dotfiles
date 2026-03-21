#!/usr/bin/env bash
# home-manager switch を実行する
# home-manager が所有する予定のファイルを先に削除してから switch する
# 単独実行可能

set -euo pipefail

# Nix が PATH にない場合は追加する（単独実行時の対応）
NIX_PROFILE="/nix/var/nix/profiles/default/etc/profile.d/nix-daemon.sh"
# shellcheck disable=SC1090
[[ -f "$NIX_PROFILE" ]] && source "$NIX_PROFILE"

if ! command -v nix &>/dev/null; then
  echo "  ERROR: nix が見つかりません。先に 03-nix.sh を実行してください"
  exit 1
fi

# dotfiles リポジトリのルートを特定する
DOTFILES_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")/../.." && pwd)"
HM_CONFIG="ryosh"

# home-manager は自分が所有していないファイルを上書きしないため、事前に削除する
# （バックアップは 01-backup.sh で済んでいる前提）
for f in ~/.zshrc ~/.gitconfig ~/.config/starship.toml ~/.ssh/config; do
  if [[ -f "$f" ]] && [[ ! -L "$f" ]]; then
    rm -f "$f"
    echo "  Removed: $f"
  fi
done

nix run home-manager/master -- switch \
  --flake "${DOTFILES_DIR}#${HM_CONFIG}" \
  --extra-experimental-features "nix-command flakes"

echo "  home-manager switch complete."
