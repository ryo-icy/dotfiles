#!/usr/bin/env bash
# Docker Engine を apt でインストールする
# 単独実行可能

set -euo pipefail

if command -v docker &>/dev/null; then
  echo "  Already installed: $(docker --version)"
else
  sudo apt-get update -qq
  sudo apt-get install -y -qq ca-certificates curl gnupg

  # Docker の公式 GPG キーを追加
  sudo install -m 0755 -d /etc/apt/keyrings
  curl -fsSL https://download.docker.com/linux/ubuntu/gpg |
    sudo gpg --dearmor -o /etc/apt/keyrings/docker.gpg
  sudo chmod a+r /etc/apt/keyrings/docker.gpg

  # Docker のリポジトリを apt ソースに追加
  # shellcheck disable=SC1091
  echo \
    "deb [arch=$(dpkg --print-architecture) signed-by=/etc/apt/keyrings/docker.gpg] \
    https://download.docker.com/linux/ubuntu \
    $(. /etc/os-release && echo "$VERSION_CODENAME") stable" |
    sudo tee /etc/apt/sources.list.d/docker.list >/dev/null

  sudo apt-get update -qq
  sudo apt-get install -y -qq \
    docker-ce docker-ce-cli containerd.io \
    docker-buildx-plugin docker-compose-plugin

  # sudo なしで docker を使えるようにする
  sudo usermod -aG docker "$USER"

  echo "  Installed: $(docker --version)"
  echo "  NOTE: docker グループの反映には再ログインが必要です"
fi

# デーモンが起動していない場合は起動を試みる
if ! docker info &>/dev/null 2>&1; then
  echo "  docker デーモンを起動します..."
  sudo service docker start || echo "  WARNING: docker デーモンの起動に失敗しました"
fi
