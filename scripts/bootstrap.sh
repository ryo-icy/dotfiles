#!/usr/bin/env bash
# 新規 WSL2 Ubuntu マシンの初回セットアップ
# 各ユニットスクリプトを順番に実行するオーケストレーター
#
# 使い方: bash scripts/bootstrap.sh
# root では実行しないこと
#
# 各ユニットは単独でも実行可能:
#   bash scripts/units/02-docker.sh    # Docker だけ再インストール
#   bash scripts/units/06-claude.sh    # Claude CLI だけ更新 など

set -euo pipefail

UNITS_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")/units" && pwd)"

echo "=== Bootstrap: Nix + home-manager for WSL2 ==="
echo ""

# Pre-flight チェック
if [[ "$(whoami)" == "root" ]]; then
  echo "ERROR: root では実行しないでください"
  exit 1
fi
if ! grep -qi "microsoft" /proc/version 2>/dev/null; then
  echo "WARNING: WSL2 として検出されませんでした。続行します。"
fi

# 各ユニットを順番に実行する
units=(
  "01-backup.sh"
  "02-docker.sh"
  "03-nix.sh"
  "04-npiperelay.sh"
  "05-home-manager.sh"
  "06-claude.sh"
  "07-gemini.sh"
  "08-ssh-keys.sh"
)

total=${#units[@]}
for i in "${!units[@]}"; do
  unit="${units[$i]}"
  step=$((i + 1))
  echo "[${step}/${total}] ${unit%.sh} ..."
  bash "$UNITS_DIR/$unit"
  echo ""
done

echo "=== Bootstrap complete! ==="
echo ""
echo "次のステップ:"
echo "  1. シェルを再起動:         exec zsh"
echo "  2. 1Password Agent 確認:   ssh-add.exe -l"
echo "  3. Docker 確認:            docker run hello-world"
echo "  4. Claude CLI 確認:        claude --version"
echo "  5. Gemini CLI 確認:        gemini --version"
echo "  6. 鍵エクスポートが失敗した場合: op signin && bash scripts/units/08-ssh-keys.sh"
