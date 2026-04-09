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
    };
  };
}
