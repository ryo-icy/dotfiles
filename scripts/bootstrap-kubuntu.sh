#!/usr/bin/env bash
# 新規 Kubuntu マシンの初回セットアップ
# 各ユニットスクリプトを順番に実行するオーケストレーター
#
# 使い方: bash scripts/bootstrap-kubuntu.sh
# root では実行しないこと
#
# 各ユニットは単独でも実行可能:
#   bash scripts/units/02-docker.sh    # Docker だけ再インストール など

set -euo pipefail

UNITS_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")/units" && pwd)"

echo "=== Bootstrap: Nix + home-manager for Kubuntu ==="
echo ""

# Pre-flight チェック
if [[ "$(whoami)" == "root" ]]; then
  echo "ERROR: root では実行しないでください"
  exit 1
fi

# home-manager の flake ターゲットを Kubuntu 用に設定
# 05-home-manager.sh はこの変数を参照する
export HM_CONFIG="ryosh-kubuntu"

# 各ユニットを順番に実行する（04-npiperelay.sh は WSL2 専用のためスキップ）
units=(
  "01-backup.sh"
  "02-docker.sh"
  "03-nix.sh"
  "05-home-manager.sh"
  "07-input-group.sh"
  "08-ssh-keys.sh"
  "09-chsh.sh"
  "10-kubeconfig.sh"
  "11-intel-vaapi.sh"
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
echo "  1. シェルを再起動:              exec zsh"
echo "  2. 1Password SSH Agent 確認:    ssh-add -l"
echo "     ※ 1Password for Linux デスクトップアプリで SSH Agent を有効にしてください"
echo "     ※ 設定 → デベロッパー → SSH Agent にチェックを入れること"
echo "  3. Docker 確認:                 docker run hello-world"
echo "  4. Claude Code 確認:            claude --version"
echo "  5. Antigravity CLI 確認:        agy --version"
echo "  6. 鍵エクスポートが失敗した場合: op signin && bash scripts/units/08-ssh-keys.sh"
