#!/usr/bin/env bash
# Intel VA-API ドライバをインストールする（Firefox GPU アクセラレーション用）
# Intel Iris Xe (Alder Lake 以降) で hardware video decoding を有効化するために必要
# 単独実行可能

set -euo pipefail

if dpkg -l intel-media-va-driver-non-free &>/dev/null 2>&1; then
  echo "  Already installed: intel-media-va-driver-non-free"
else
  sudo apt-get install -y -qq intel-media-va-driver-non-free vainfo
  echo "  Installed: intel-media-va-driver-non-free vainfo"
fi
