#!/usr/bin/env bash
# 既存の dotfile を home-manager switch 前にバックアップする
# 単独実行可能

set -euo pipefail

BACKUP_DIR="$HOME/.dotfiles-backup-$(date +%Y%m%d-%H%M%S)"
mkdir -p "$BACKUP_DIR"

backed_up=0
for f in ~/.zshrc ~/.gitconfig ~/.config/starship.toml ~/.ssh/config; do
  # シンボリックリンク（home-manager 管理済み）は対象外
  if [[ -f "$f" ]] && [[ ! -L "$f" ]]; then
    cp "$f" "$BACKUP_DIR/"
    echo "  Backed up: $f"
    backed_up=$((backed_up + 1))
  fi
done

if [[ "$backed_up" -eq 0 ]]; then
  echo "  バックアップ対象なし（既に home-manager 管理済みか、ファイルが存在しない）"
  rmdir "$BACKUP_DIR"
else
  echo "  Backup location: $BACKUP_DIR"
fi
