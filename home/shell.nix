{ ... }: {
  programs.zsh = {
    enable = true;
    autosuggestion.enable = true;
    syntaxHighlighting.enable = true;

    shellAliases = {
      ls   = "eza --icons --git";
      ll   = "eza --icons --git -l";
      # bat is the Nix package binary name (apt installs it as batcat)
      cat  = "bat";
      # ccusage は Nix 管理のバイナリを直接使用（packages.nix 参照）
      ccu  = "ccusage";
      ccum = "ccusage monthly";
      ccus = "ccusage session";
    };

    # NVM initialization removed — Node.js is managed by Nix (see packages.nix)

    initContent = ''
      # kubectl オートコンプリート
      source <(kubectl completion zsh)
    '';
  };
}
