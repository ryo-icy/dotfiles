{ ... }: {
  programs.zsh = {
    enable = true;
    autosuggestion.enable = true;
    syntaxHighlighting.enable = true;

    shellAliases = {
      ls  = "eza --icons --git";
      ll  = "eza --icons --git -l";
      # bat is the Nix package binary name (apt installs it as batcat)
      cat = "bat";
    };

    # NVM initialization removed — Node.js is managed by Nix (see packages.nix)
  };
}
