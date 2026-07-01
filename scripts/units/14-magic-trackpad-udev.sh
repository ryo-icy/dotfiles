#!/usr/bin/env bash
# Apple Magic Trackpad の Bluetooth 接続時に libinput-gestures を再起動する udev ルールを配置する
# Bluetooth デバイスはセッション開始後に接続されるため、udev で接続検知して再起動する
# 単独実行可能

set -euo pipefail

RULE_FILE="/etc/udev/rules.d/99-magic-trackpad-gestures.rules"
RULE_CONTENT='ACTION=="add", SUBSYSTEM=="input", ATTRS{name}=="Apple Inc. Magic Trackpad USB-C", TAG+="systemd", ENV{SYSTEMD_USER_UNIT}="magic-trackpad-gestures.service"'

if [[ -f "$RULE_FILE" ]] && grep -qF "$RULE_CONTENT" "$RULE_FILE" 2>/dev/null; then
  echo "  Already installed: $RULE_FILE"
else
  echo "$RULE_CONTENT" | sudo tee "$RULE_FILE" > /dev/null
  sudo udevadm control --reload-rules
  echo "  Installed: $RULE_FILE"
  echo "  NOTE: 次回 Magic Trackpad 接続時から libinput-gestures が自動再起動されます"
fi
