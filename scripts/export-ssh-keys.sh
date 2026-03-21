#!/usr/bin/env bash
# Export SSH public keys from 1Password to ~/.ssh/imported_keys/
#
# Exports all SSH Key items tagged with TAG (default: "dotfiles").
# The exported filename is derived from the 1Password item title:
#   title -> lowercase, spaces replaced with hyphens -> <title>.pub
#
# Usage:
#   ./scripts/export-ssh-keys.sh              # uses "dotfiles" tag
#   ./scripts/export-ssh-keys.sh my-tag       # uses custom tag
#   ./scripts/export-ssh-keys.sh ""           # exports ALL SSH Key items (no tag filter)
#
# Prerequisites:
#   - op CLI installed (available after home-manager switch)
#   - Authenticated: op signin
#   - 1Password items tagged with TAG and of category "SSH Key"
#
# SSH config (home/ssh.nix) references keys by item title, e.g.:
#   "github.com" item  ->  ~/.ssh/imported_keys/github.com.pub
#   "rouzinkai" item   ->  ~/.ssh/imported_keys/rouzinkai.pub

set -euo pipefail

TAG="${1-dotfiles}"
KEYS_DIR="$HOME/.ssh/imported_keys"

mkdir -p "$KEYS_DIR"
chmod 700 "$KEYS_DIR"

if ! op account list &>/dev/null; then
  echo "ERROR: 'op' not authenticated. Run: op signin"
  exit 1
fi

if [[ -n "$TAG" ]]; then
  echo "Exporting SSH public keys with tag: '$TAG'"
  items=$(op item list --categories "SSH Key" --tags "$TAG" --format json)
else
  echo "Exporting ALL SSH public keys (no tag filter)"
  items=$(op item list --categories "SSH Key" --format json)
fi

count=$(echo "$items" | jq length)

if [[ "$count" -eq 0 ]]; then
  echo "WARNING: No SSH Key items found."
  if [[ -n "$TAG" ]]; then
    echo "  Tag '$TAG' matched nothing. Check with:"
    echo "    op item list --categories 'SSH Key'"
  fi
  exit 1
fi

echo "Found $count item(s). Exporting..."

echo "$items" | jq -c '.[]' | while read -r item; do
  item_id=$(echo "$item" | jq -r '.id')
  item_name=$(echo "$item" | jq -r '.title' | tr '[:upper:]' '[:lower:]' | tr ' ' '-')
  dest="$KEYS_DIR/${item_name}.pub"

  pubkey=$(op item get "$item_id" --fields "public key" 2>/dev/null || true)

  if [[ -z "$pubkey" ]]; then
    echo "  SKIP: $item_name (no 'public key' field — check item type is 'SSH Key')"
    continue
  fi

  echo "$pubkey" > "$dest"
  chmod 644 "$dest"
  echo "  Exported: $dest"
done

echo ""
echo "Keys in $KEYS_DIR:"
ls -la "$KEYS_DIR"
