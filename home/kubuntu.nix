{ pkgs, lib, ... }: {
  # 1Password for Linux の SSH agent ソケットを使う。
  # ~/.1password/agent.sock は 1Password デスクトップアプリが自動で作成する。
  home.sessionVariables.SSH_AUTH_SOCK = "$HOME/.1password/agent.sock";

  fonts.fontconfig.enable = true;
  home.packages = with pkgs; [
    hackgen-font
    hackgen-nf-font
  ];

  # Ghostty 本体はシステム側で管理し、設定ファイルだけ home-manager で管理する。
  # Nix ビルドの Ghostty は非 NixOS 環境で OpenGL コンテキスト取得に失敗するため。
  # Ghostty 本体はシステム側で管理し、設定ファイルだけ home-manager で管理する。
  # Nix ビルドの Ghostty は非 NixOS 環境で OpenGL コンテキスト取得に失敗するため。
  programs.ghostty = {
    enable = true;
    package = null;
    enableZshIntegration = true;
    systemd.enable = false;
    settings = {
      font-family = "HackGen Console NF";
      font-size = 13;
      window-width = 144;
      window-height = 40;
      window-save-state = "never";
      gtk-single-instance = false;
      keybind = [
        # 選択中ならコピー、なければ通常の Ctrl+C（割り込み）をアプリへ渡す
        "performable:ctrl+c=copy_to_clipboard"
        # Ctrl+V でクリップボードからペースト
        "ctrl+v=paste_from_clipboard"
        # Ctrl+Enter で改行文字を送信（Claude 等での改行挿入）
        "ctrl+enter=text:\\n"
      ];
    };
  };

  # Ghostty の DBusActivatable を無効化する。
  # デフォルトの com.mitchellh.ghostty.desktop は DBusActivatable=true のため、KDE が D-Bus 経由で
  # 起動しようとし GPU ドライバーの環境変数が引き継がれずレンダリングに失敗する。
  home.file.".local/share/applications/com.mitchellh.ghostty.desktop".text = ''
    [Desktop Entry]
    Version=1.0
    Name=Ghostty
    Type=Application
    Comment=A terminal emulator
    TryExec=/usr/bin/ghostty
    Exec=/usr/bin/ghostty
    Icon=com.mitchellh.ghostty
    Categories=System;TerminalEmulator;
    Keywords=terminal;tty;pty;
    StartupNotify=true
    StartupWMClass=com.mitchellh.ghostty
    Terminal=false
    DBusActivatable=false
    X-KDE-Shortcuts=Ctrl+Alt+T

    [Desktop Action new-window]
    Name=New Window
    Exec=/usr/bin/ghostty
  '';

# fcitx5 のホットキー設定を管理する。
  # GUI から変更しても nix store のシンボリックリンクのため保存できないので、dotfiles で変更する。
  xdg.configFile."fcitx5/config".text = ''
    [Hotkey]
    EnumerateWithTriggerKeys=True
    EnumerateForwardKeys=
    EnumerateBackwardKeys=
    EnumerateSkipFirst=False

    [Hotkey/TriggerKeys]
    0=Eisu_toggle
    1=Zenkaku_Hankaku
    2=Hangul

    [Hotkey/AltTriggerKeys]
    0=Shift_L

    [Hotkey/EnumerateGroupForwardKeys]
    0=Super+space

    [Hotkey/EnumerateGroupBackwardKeys]
    0=Shift+Super+space

    [Hotkey/ActivateKeys]
    0=Hangul_Hanja
    1=Hiragana_Katakana

    [Hotkey/DeactivateKeys]
    0=Hangul_Romaja

    [Hotkey/PrevPage]
    0=Up

    [Hotkey/NextPage]
    0=Down

    [Hotkey/PrevCandidate]
    0=Shift+Tab

    [Hotkey/NextCandidate]
    0=Tab

    [Hotkey/TogglePreedit]
    0=Control+Alt+P

    [Behavior]
    ActiveByDefault=False
    ShareInputState=No
    PreeditEnabledByDefault=True
    ShowInputMethodInformation=True
    showInputMethodInformationWhenFocusIn=False
    CompactInputMethodInformation=True
    ShowFirstInputMethodInformation=True
    DefaultPageSize=5
    OverrideXkbOption=False
    CustomXkbOption=
    EnabledAddons=
    DisabledAddons=
    PreloadInputMethod=True
    AllowInputMethodForPassword=False
    ShowPreeditForPassword=False
    AutoSavePeriod=30
  '';

  # fcitx5 の入力メソッドグループ設定（mozc + 日本語キーボード）。
  # profile は fcitx5 が起動時に書き込むため symlink 管理できない。activation で上書きする。
  home.activation.fcitx5Profile = lib.hm.dag.entryAfter [ "writeBoundary" ] ''
    $DRY_RUN_CMD mkdir -p "$HOME/.config/fcitx5"
    if [[ -z "$DRY_RUN_CMD" ]]; then
      cat > "$HOME/.config/fcitx5/profile" << 'FCITX5PROFILE'
[Groups/0]
Name=デフォルト
Default Layout=jp
DefaultIM=mozc

[Groups/0/Items/0]
Name=keyboard-jp
Layout=

[Groups/0/Items/1]
Name=mozc
Layout=

[GroupOrder]
0=デフォルト
FCITX5PROFILE
    fi
  '';

  # KRunner を画面中央に表示する。
  # krunnerrc は KRunner 自身が書き込むため symlink 管理できない。kwriteconfig5 で特定キーだけ設定する。
  home.activation.krunnerFreeFloating = lib.hm.dag.entryAfter [ "writeBoundary" ] ''
    $DRY_RUN_CMD /usr/bin/kwriteconfig5 --file krunnerrc --group General --key FreeFloating true
  '';

  # タッチパッドのナチュラルスクロールを有効化する。
  # touchpadxlibinputrc に NaturalScroll=true を書くが、kcminit_startup がデバイス準備より早く走るため
  # autostart で kcminit kcm_touchpad を再実行して確実に適用する。
  home.activation.touchpadNaturalScroll = lib.hm.dag.entryAfter [ "writeBoundary" ] ''
    $DRY_RUN_CMD /usr/bin/kwriteconfig5 --file touchpadxlibinputrc --group "SYNA32CF:00 06CB:CECD Touchpad" --key NaturalScroll true
  '';

  # デバイスが X11 に登録されるまで最大 10 秒リトライする。
  # Exec= インラインでのシェル構文は systemd がエスケープするため、スクリプトを別ファイルに分離する。
  home.file.".local/bin/touchpad-natural-scroll" = {
    executable = true;
    text = ''
      #!/usr/bin/env bash
      for i in $(seq 10); do
        /usr/bin/xinput set-prop "SYNA32CF:00 06CB:CECD Touchpad" "libinput Natural Scrolling Enabled" 1 2>/dev/null && exit 0
        sleep 1
      done
    '';
  };

  home.file.".config/autostart/touchpad-natural-scroll.desktop".text = ''
    [Desktop Entry]
    Type=Application
    Name=Touchpad Natural Scroll
    Exec=/home/ryosh/.local/bin/touchpad-natural-scroll
    Hidden=false
    NoDisplay=true
    X-KDE-autostart-enabled=true
  '';

  # Ghostty を KDE のデフォルトターミナルに設定する。
  # kdeglobals は KDE 自身が書き込むため symlink 管理できない。kwriteconfig5 で特定キーだけ設定する。
  # TerminalService は Dolphin 等が「ターミナルで開く」時に参照する。
  home.activation.setDefaultTerminal = lib.hm.dag.entryAfter [ "writeBoundary" ] ''
    $DRY_RUN_CMD /usr/bin/kwriteconfig5 --file kdeglobals --group General --key TerminalApplication ghostty
    $DRY_RUN_CMD /usr/bin/kwriteconfig5 --file kdeglobals --group General --key TerminalService com.mitchellh.ghostty.desktop
  '';

  # Snap でインストールしたアプリ（Firefox 等）のデスクトップファイルを KDE セッションから参照できるようにする。
  # /etc/profile.d/apps-bin-path.sh が担う処理だが、KDE Plasma グラフィカルセッションでは
  # そのスクリプトが適用されないため plasma-workspace/env で補完する。
  home.file.".config/plasma-workspace/env/snap-xdg.sh" = {
    text = ''
      export XDG_DATA_DIRS="$XDG_DATA_DIRS:/var/lib/snapd/desktop"
    '';
    executable = true;
  };
}
