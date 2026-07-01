{ pkgs, lib, config, ... }:
let
  # GhosttyのFreedesktop通知をD-Busで監視し、音を鳴らすスクリプト。
  # GhosttyはGTKアプリ（g_application_send_notification）でKNotificationを使わないため
  # .notifyrcでは音が鳴らせず、dbus-monitorで直接捕捉する方式を採用する。
  ghosttyNotifySound = pkgs.writeScript "ghostty-notify-sound" ''
    #!/usr/bin/env python3
    import subprocess

    SOUND = "/usr/share/sounds/Oxygen-Sys-App-Message.ogg"
    PLAYER = "/usr/bin/pw-play"

    proc = subprocess.Popen(
        [
            "/usr/bin/dbus-monitor", "--session",
            "type=method_call,interface='org.freedesktop.Notifications',member='Notify'",
        ],
        stdout=subprocess.PIPE,
        stderr=subprocess.DEVNULL,
        text=True,
        bufsize=1,
    )

    expect_app_name = False

    for line in proc.stdout:
        line = line.rstrip()
        if not line:
            continue
        if "member=Notify" in line:
            expect_app_name = True
        elif expect_app_name:
            if 'string "ghostty"' in line:
                subprocess.Popen(
                    [PLAYER, SOUND],
                    stdout=subprocess.DEVNULL,
                    stderr=subprocess.DEVNULL,
                )
            expect_app_name = False
  '';
in
{
  # 1Password for Linux の SSH agent ソケットを使う。
  # ~/.1password/agent.sock は 1Password デスクトップアプリが自動で作成する。
  home.sessionVariables.SSH_AUTH_SOCK = "$HOME/.1password/agent.sock";

  fonts.fontconfig.enable = true;
  home.packages = with pkgs; [
    hackgen-font
    hackgen-nf-font
    # ジェスチャー: libinput-gesturesで/dev/inputを読み、qdbusでKDEショートカットを呼び出す
    libinput-gestures
  ];

  # Ghostty 本体はシステム側で管理し、設定ファイルだけ home-manager で管理する。
  # Nix ビルドの Ghostty は非 NixOS 環境で OpenGL コンテキスト取得に失敗するため。
  programs.ghostty = {
    enable = true;
    package = null;
    enableZshIntegration = true;
    systemd.enable = false;
    settings = {
      font-family = "HackGen Console NF";
      font-size = 15;
      window-width = 144;
      window-height = 40;
      window-save-state = "never";
      background-opacity = 0.9;
      unfocused-split-opacity = 0.7;
      gtk-single-instance = false;
      # Wayland+KDE では KWin が SSD を提供するため auto だと CSD のタブバーが消える。
      # client を指定して Ghostty 自身の CSD タイトルバー（タブバー含む）を強制表示する。
      window-decoration = "client";
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

  # Plasma 5.27 Wayland では 3本指上スワイプが KWin に未割り当てのため libinput-gestures で捕捉する。
  # wtype/xdotool は KDE Wayland で virtual keyboard protocol 未対応のため動かない。
  # qdbus 経由で kglobalaccel のショートカットを直接呼び出す方式を使う。
  # KWin の SwipeMinFingerCount=4 により 3本指はKWinが処理せず libinput-gestures に完全委任する。
  # これにより 3本指スワイプがスクロールとして誤認識されるのを防ぐ。
  # /dev/input を直接読むため input グループへの加入が必要（07-input-group.sh 参照）。
  xdg.configFile."libinput-gestures.conf".text = ''
    timeout 0
    swipe_threshold 0

    # 3本指上スワイプ: Overview
    gesture swipe up 3 qdbus org.kde.kglobalaccel /component/kwin org.kde.kglobalaccel.Component.invokeShortcut Overview
    # 3本指左右スワイプ: 仮想デスクトップ切替（KWinから引き継ぎ）
    gesture swipe right 3 qdbus org.kde.kglobalaccel /component/kwin org.kde.kglobalaccel.Component.invokeShortcut "Switch One Desktop to the Left"
    gesture swipe left 3 qdbus org.kde.kglobalaccel /component/kwin org.kde.kglobalaccel.Component.invokeShortcut "Switch One Desktop to the Right"
  '';

  systemd.user.services.libinput-gestures = {
    Unit = {
      Description = "Touchpad gesture recognizer (Wayland)";
      After = [ "graphical-session.target" ];
      PartOf = [ "graphical-session.target" ];
    };
    Service = {
      Type = "simple";
      ExecStart = "${pkgs.libinput-gestures}/bin/libinput-gestures";
      Restart = "on-failure";
      RestartSec = "3s";
    };
    Install = {
      WantedBy = [ "graphical-session.target" ];
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

  # karukan ユーザーローカルインストール（~/.local）用に FCITX_ADDON_DIRS を設定する。
  # fcitx5 はグラフィカルセッション開始時に起動されるため、シェルプロファイルではなく
  # environment.d に書く。システムパスを欠くと wayland・classicui 等の標準アドオンが失われる。
  home.activation.fcitx5KarukanAddonDirs = lib.hm.dag.entryAfter [ "writeBoundary" ] ''
    FCITX5_SYS_DIR=""
    if command -v pkg-config >/dev/null 2>&1 && pkg-config --exists Fcitx5Core 2>/dev/null; then
      FCITX5_SYS_DIR=$(pkg-config --variable=libdir Fcitx5Core)/fcitx5
    elif [ -d /usr/lib/x86_64-linux-gnu/fcitx5 ]; then
      FCITX5_SYS_DIR=/usr/lib/x86_64-linux-gnu/fcitx5
    fi
    if [ -n "$FCITX5_SYS_DIR" ]; then
      $DRY_RUN_CMD mkdir -p "$HOME/.config/environment.d"
      if [[ -z "$DRY_RUN_CMD" ]]; then
        printf 'FCITX_ADDON_DIRS=%s/.local/lib/fcitx5:%s\n' "$HOME" "$FCITX5_SYS_DIR" \
          > "$HOME/.config/environment.d/fcitx5-karukan.conf"
      fi
    fi
  '';

  # karukan のシステム辞書を初回のみダウンロードする。
  # dict.bin がない場合のみ取得するため、2 回目以降の switch では何もしない。
  home.activation.karukanDict = lib.hm.dag.entryAfter [ "writeBoundary" ] ''
    DICT_PATH="$HOME/.local/share/karukan-im/dict.bin"
    if [[ -z "$DRY_RUN_CMD" ]] && [ ! -f "$DICT_PATH" ]; then
      $DRY_RUN_CMD mkdir -p "$HOME/.local/share/karukan-im"
      echo "karukan: システム辞書をダウンロードしています..."
      TMP_DIR=$(mktemp -d)
      if wget -q -O "$TMP_DIR/dict.tgz" \
          "https://github.com/togatoga/karukan/releases/download/v0.1.0/dict.tgz"; then
        tar -xzf "$TMP_DIR/dict.tgz" -C "$TMP_DIR"
        cp "$TMP_DIR/dict.bin" "$DICT_PATH"
        echo "karukan: システム辞書のインストールが完了しました。"
      else
        echo "karukan: システム辞書のダウンロードに失敗しました。手動でインストールしてください。" >&2
      fi
      rm -rf "$TMP_DIR"
    fi
  '';

  # fcitx5 の入力メソッドグループ設定（karukan + 日本語キーボード）。
  # profile は fcitx5 が起動時に書き込むため symlink 管理できない。activation で上書きする。
  home.activation.fcitx5Profile = lib.hm.dag.entryAfter [ "writeBoundary" ] ''
    $DRY_RUN_CMD mkdir -p "$HOME/.config/fcitx5"
    if [[ -z "$DRY_RUN_CMD" ]]; then
      cat > "$HOME/.config/fcitx5/profile" << 'FCITX5PROFILE'
[Groups/0]
Name=デフォルト
Default Layout=jp
DefaultIM=karukan

[Groups/0/Items/0]
Name=keyboard-jp
Layout=

[Groups/0/Items/1]
Name=karukan
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

  # Alt+Tab のタスクスイッチャーを画面中央にサムネイルグリッドで表示する。
  # kwinrc は KWin 自身が書き込むため symlink 管理できない。kwriteconfig5 で特定キーだけ設定する。
  home.activation.kwinTabBoxLayout = lib.hm.dag.entryAfter [ "writeBoundary" ] ''
    $DRY_RUN_CMD /usr/bin/kwriteconfig5 --file kwinrc --group TabBox --key LayoutName org.kde.thumbnails
    # 3本指スワイプを KWin ジェスチャーから除外し libinput-gestures に完全委任する。
    # KWin が 3本指を処理しないことで、スワイプがスクロールとして漏れるのを防ぐ。
    $DRY_RUN_CMD /usr/bin/kwriteconfig5 --file kwinrc --group Gestures --key SwipeMinFingerCount 4
  '';

  # タッチパッド設定。kcminit_startup がデバイス準備より早く走るため autostart で kcminit kcm_touchpad を再実行して確実に適用する。
  # - NaturalScroll: 上スワイプで下スクロール（macOS方式）
  # - tapToClick: タップでクリック有効（2本指タップ = 右クリック、3本指タップ = 中クリック）
  # - clickMethodClickfinger: 指の本数でボタンを判定（2本指 = 右クリック）
  home.activation.touchpadSettings = lib.hm.dag.entryAfter [ "writeBoundary" ] ''
    $DRY_RUN_CMD /usr/bin/kwriteconfig5 --file touchpadxlibinputrc --group "SYNA32CF:00 06CB:CECD Touchpad" --key NaturalScroll true
    $DRY_RUN_CMD /usr/bin/kwriteconfig5 --file touchpadxlibinputrc --group "SYNA32CF:00 06CB:CECD Touchpad" --key tapToClick true
    $DRY_RUN_CMD /usr/bin/kwriteconfig5 --file touchpadxlibinputrc --group "SYNA32CF:00 06CB:CECD Touchpad" --key clickMethodAreas false
    $DRY_RUN_CMD /usr/bin/kwriteconfig5 --file touchpadxlibinputrc --group "SYNA32CF:00 06CB:CECD Touchpad" --key clickMethodClickfinger true
  '';

  home.file.".config/autostart/touchpad-init.desktop".text = ''
    [Desktop Entry]
    Type=Application
    Name=Touchpad Init
    Exec=sh -c "sleep 2 && kcminit kcm_touchpad"
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

  # Ghosttyのデスクトップ通知が来たら音を鳴らすサービス。
  # graphical-session.target の起動後に開始し、プロセスが落ちたら自動再起動する。
  systemd.user.services.ghostty-notify-sound = {
    Unit = {
      Description = "Play sound on Ghostty desktop notifications";
      After = [ "graphical-session.target" ];
      PartOf = [ "graphical-session.target" ];
    };
    Service = {
      Type = "simple";
      ExecStart = "${ghosttyNotifySound}";
      Restart = "always";
      RestartSec = "3s";
    };
    Install = {
      WantedBy = [ "graphical-session.target" ];
    };
  };

  # XDG ユーザーディレクトリを英語名に固定する。
  # 日本語ロケールのままだと xdg-user-dirs-update がドキュメント等を日本語名で作成するため明示指定する。
  xdg.configFile."user-dirs.dirs".force = true;
  # xdg-user-dirs-update がログイン時に日本語ロケールで dirs を上書きするのを防ぐ。
  xdg.configFile."user-dirs.locale" = {
    text = "en_US\n";
    force = true;
  };
  xdg.userDirs = {
    enable = true;
    createDirectories = true;
    setSessionVariables = true;
    desktop = "${config.home.homeDirectory}/Desktop";
    documents = "${config.home.homeDirectory}/Documents";
    download = "${config.home.homeDirectory}/Downloads";
    music = "${config.home.homeDirectory}/Music";
    pictures = "${config.home.homeDirectory}/Pictures";
    publicShare = "${config.home.homeDirectory}/Public";
    templates = "${config.home.homeDirectory}/Templates";
    videos = "${config.home.homeDirectory}/Videos";
  };

  # Snap でインストールしたアプリ（Firefox 等）のデスクトップファイルを KDE セッションから参照できるようにする。
  # /etc/profile.d/apps-bin-path.sh が担う処理だが、KDE Plasma グラフィカルセッションでは
  # そのスクリプトが適用されないため plasma-workspace/env で補完する。
  home.file.".config/plasma-workspace/env/snap-xdg.sh" = {
    text = ''
      export XDG_DATA_DIRS="$XDG_DATA_DIRS:/var/lib/snapd/desktop"
    '';
    executable = true;
  };

  # Firefox の GPU アクセラレーションを有効化する。
  # Wayland セッションでは MOZ_ENABLE_WAYLAND=1 でネイティブ Wayland レンダリングを有効にする。
  # LIBVA_DRIVER_NAME=iHD で intel-media-va-driver-non-free を明示指定し VA-API を確実に使わせる。
  home.file.".config/plasma-workspace/env/firefox-gpu.sh" = {
    text = ''
      export MOZ_ENABLE_WAYLAND=1
      export LIBVA_DRIVER_NAME=iHD
    '';
    executable = true;
  };
}
