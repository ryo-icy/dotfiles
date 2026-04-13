{ ... }: {
  programs.zsh = {
    enable = true;
    autosuggestion.enable = true;
    syntaxHighlighting.enable = true;

    shellAliases = {
      ls   = "eza --icons --git";
      ll   = "eza --icons --git -l";
      la   = "eza --icons --git -la";
      lt   = "eza --icons --git --tree --level=2";
      # bat is the Nix package binary name (apt installs it as batcat)
      cat  = "bat";

      grep = "grep --color";
      gpull  = "git switch $(git symbolic-ref refs/remotes/origin/HEAD | sed 's|refs/remotes/origin/||') && git pull";
      gclean = "git fetch -p && git branch --merged | grep -v '*' | xargs -r git branch -d";
      greset = "git reset --soft HEAD^";
      greset-all = "git reset --hard HEAD^";
      lg = "lazygit";

      vi   = "nvim";
      vim  = "nvim";

      # ccusage は Nix 管理のバイナリを直接使用（packages.nix 参照）
      ccu  = "ccusage";
      ccum = "ccusage monthly";
      ccus = "ccusage session";

      # WSL2: クリップボードへのコピー（文字コードを CP932 に変換してから clip.exe へ渡す）
      clip = "iconv -t cp932 | clip.exe";

      # npm -g は Nix ストア（read-only）に書き込むため --prefix を必須とする
      update-gemini = "npm install -g @google/gemini-cli --prefix \"$HOME/.local\"";
    };

    # NVM initialization removed — Node.js is managed by Nix (see packages.nix)

    initContent = ''
      # kubectl オートコンプリート
      source <(kubectl completion zsh)

      # GitHub リポジトリを fzf で選択して ghq でクローン（~/codes 以下）
      function gclone() {
        local repo
        repo=$(gh api --paginate /user/repos --jq '.[].ssh_url' | fzf)
        [[ -n "$repo" ]] && ghq get "$repo"
      }

      # ghq 管理のリポジトリを fzf で選択して cd
      function gcd() {
        local dir
        dir=$(ghq list | fzf)
        [[ -n "$dir" ]] && cd "$(ghq root)/$dir"
      }
    '';
  };
}
