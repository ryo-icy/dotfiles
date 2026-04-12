{ ... }: {
  # yazi: ターミナルファイルマネージャ
  # enableZshIntegration = true により `yy` ラッパー関数が生成される。
  # `yy` で起動すると、yazi 終了時に移動先ディレクトリへ自動 cd される。
  programs.yazi = {
    enable = true;
    enableZshIntegration = true;
    settings = {
      manager = {
        show_hidden = true;
        linemode = "size";       # ファイルサイズを一覧に表示
        sort_dir_first = true;   # ディレクトリを上部にまとめる
      };
      opener.edit = [
        { run = ''nvim "$@"''; block = true; }
      ];
    };
    keymap = {
      manager.prepend_keymap = [
        {
          on = ["z"];
          # zoxide のインタラクティブ選択後、ya emit-to で yazi 内を cd
          run = ''shell --interactive 'dir=$(zoxide query -i) && ya emit-to "$YAZI_ID" cd --str "$dir"' '';
          desc = "zoxide でディレクトリジャンプ";
        }
      ];
    };
  };
}
