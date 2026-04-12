{ ... }: {
  programs.git = {
    enable = true;
    settings = {
      user = {
        name  = "ryo-icy";
        email = "74962200+ryo-icy@users.noreply.github.com";
      };
      # SSH_AUTH_SOCK (npiperelay bridge) により 1Password SSH Agent を使用する
      init.defaultBranch = "main";
      core.editor = "nvim";

      # ghq のクローン先を ~/codes に固定
      ghq.root = "~/codes";

      # delta: git diff ビューア
      core.pager = "delta";
      interactive.diffFilter = "delta --color-only";
      delta = {
        navigate = true;  # n/N でdiffセクション間を移動
        dark = true;
        side-by-side = true;
      };
      merge.conflictStyle = "zdiff3";
    };
  };
}
