{ lib, pkgs, ... }: {
  # notify.sh はシンボリックリンクで管理（実行時に書き込み不要なため）
  # Antigravity CLI は ~/.gemini/ を設定ディレクトリとして継承している
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

  # settings.json は Antigravity が認証情報を書き込むため、シンボリックリンクではなく
  # コピーして書き込み可能にする。home-manager switch のたびに dotfiles 側の設定を
  # jq でマージし、認証情報など Antigravity が追記したフィールドは保持する。
  home.activation.antigravitySettings = lib.hm.dag.entryAfter [ "writeBoundary" ] ''
    SETTINGS_DIR="$HOME/.gemini"
    SETTINGS_FILE="$SETTINGS_DIR/settings.json"
    BASE_SETTINGS="${../config/gemini/settings.json}"

    mkdir -p "$SETTINGS_DIR"

    if [ -f "$SETTINGS_FILE" ]; then
      # 既存ファイルに dotfiles 設定をマージ（dotfiles 側を優先）
      # tmp 経由でアトミックに書き込み、中断時のファイル破損を防ぐ
      _tmp=$(mktemp "$SETTINGS_DIR/.settings.json.XXXXXX")
      ${pkgs.jq}/bin/jq -s '.[0] * .[1]' "$SETTINGS_FILE" "$BASE_SETTINGS" > "$_tmp" \
        && mv "$_tmp" "$SETTINGS_FILE" \
        || rm -f "$_tmp"
    else
      # 初回: dotfiles 設定をそのままコピー
      cp "$BASE_SETTINGS" "$SETTINGS_FILE"
      chmod 644 "$SETTINGS_FILE"
    fi
  '';
}
