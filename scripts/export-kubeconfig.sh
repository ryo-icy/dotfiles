#!/usr/bin/env bash
# 1Password から kubeconfig をエクスポートする
#
# 1Password の "kubeconfig" ドキュメントを ~/.kube/config に書き出す。
# アイテム名は引数で変更可能（デフォルト: "kubeconfig"）。
#
# Usage:
#   ./scripts/export-kubeconfig.sh              # "kubeconfig" アイテムを使用
#   ./scripts/export-kubeconfig.sh my-kube      # カスタムアイテム名を使用
#
# Prerequisites:
#   - op CLI installed (available after home-manager switch)
#   - Authenticated: op signin
#   - 1Password にドキュメントタイプで kubeconfig を保存済み

set -euo pipefail

ITEM_NAME="${1:-kubeconfig}"
KUBE_DIR="$HOME/.kube"
KUBE_CONFIG="$KUBE_DIR/config"

mkdir -p "$KUBE_DIR"
chmod 700 "$KUBE_DIR"

if ! op account list &>/dev/null; then
  echo "ERROR: 'op' not authenticated. Run: op signin"
  exit 1
fi

echo "Exporting kubeconfig from 1Password item: '$ITEM_NAME'"

if ! op item get "$ITEM_NAME" &>/dev/null; then
  echo "ERROR: 1Password に '$ITEM_NAME' アイテムが見つかりません"
  echo "  ドキュメントタイプで保存し、アイテム名を確認してください:"
  echo "    op item list --categories Document"
  exit 1
fi

op document get "$ITEM_NAME" --output "$KUBE_CONFIG"
chmod 600 "$KUBE_CONFIG"

echo "  Exported: $KUBE_CONFIG"
