{ ... }: {
  programs.git = {
    enable = true;
    userName  = "ryo-icy";
    userEmail = "74962200+ryo-icy@users.noreply.github.com";
    extraConfig = {
      # SSH_AUTH_SOCK (npiperelay bridge) により 1Password SSH Agent を使用する
      init.defaultBranch = "main";
    };
  };
}
