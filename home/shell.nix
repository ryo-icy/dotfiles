{ ... }: {
  programs.zsh = {
    enable = true;
    autosuggestion.enable = true;
    syntaxHighlighting.enable = true;

    shellAliases = {
      ls   = "eza --icons --git";
      ll   = "eza --icons --git -l";
      la   = "eza --icons --git -la";
      # bat is the Nix package binary name (apt installs it as batcat)
      cat  = "bat";

      grep = "grep --color";
      gpull  = "git switch $(git symbolic-ref refs/remotes/origin/HEAD | sed 's|refs/remotes/origin/||') && git pull";
      gclean = "git fetch -p && git branch --merged | grep -v '*' | xargs -r git branch -d";
      greset = "git reset --soft HEAD^";
      greset-all = "git reset --hard HEAD^";

      # ccusage は Nix 管理のバイナリを直接使用（packages.nix 参照）
      ccu  = "ccusage";
      ccum = "ccusage monthly";
      ccus = "ccusage session";

      # npm -g は Nix ストア（read-only）に書き込むため --prefix を必須とする
      update-gemini = "npm install -g @google/gemini-cli --prefix \"$HOME/.local\"";
    };

    # NVM initialization removed — Node.js is managed by Nix (see packages.nix)

    initContent = ''
      # kubectl オートコンプリート
      source <(kubectl completion zsh)
    '';
  };
}
