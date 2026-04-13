{ lib, pkgs, ... }: {
  # notify.sh とポリシー設定はシンボリックリンクで管理（実行時に書き込み不要なため）
  home.file = {
    ".gemini/hooks/notify.sh" = {
      source = ../config/gemini/hooks/notify.sh;
      executable = true;
    };
    # すべてのポリシーファイルを ~/.gemini/policies/ に配置
    ".gemini/policies" = {
      source = ../config/gemini/policies;
      recursive = true;
    };
  };

  # settings.json は Gemini が認証情報を書き込むため、シンボリックリンクではなく
  # コピーして書き込み可能にする。home-manager switch のたびに dotfiles 側の設定を
  # jq でマージし、認証情報など Gemini が追記したフィールドは保持する。
  home.activation.geminiSettings = lib.hm.dag.entryAfter [ "writeBoundary" ] ''
    SETTINGS_DIR="$HOME/.gemini"
    SETTINGS_FILE="$SETTINGS_DIR/settings.json"
    BASE_SETTINGS="${../config/gemini/settings.json}"

    mkdir -p "$SETTINGS_DIR"

    if [ -f "$SETTINGS_FILE" ]; then
      # 既存ファイルに dotfiles 設定をマージ（dotfiles 側を優先）
      MERGED=$(${pkgs.jq}/bin/jq -s '.[0] * .[1]' "$SETTINGS_FILE" "$BASE_SETTINGS")
      echo "$MERGED" > "$SETTINGS_FILE"
    else
      # 初回: dotfiles 設定をそのままコピー
      cp "$BASE_SETTINGS" "$SETTINGS_FILE"
      chmod 644 "$SETTINGS_FILE"
    fi
  '';
}
