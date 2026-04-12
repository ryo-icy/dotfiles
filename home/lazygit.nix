{ ... }: {
  # lazygit: TUI Git クライアント
  # programs.lazygit で管理することで delta との連携設定を宣言的に管理する。
  # lazygit は git の core.pager を使用しないため、独自設定が必要。
  programs.lazygit = {
    enable = true;
    settings = {
      git.pagers = [
        {
          colorArg = "always";
          pager = "delta --dark --paging=never --side-by-side";
        }
      ];
    };
  };
}
