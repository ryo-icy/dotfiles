{ pkgs, inputs, ... }: {
  home.packages = with pkgs; [
    # シェル・ファイル操作
    eza
    bat
    fzf
    wsl-open
    # yazi は shell integration の都合で home/yazi.nix 側で管理する。
    zoxide
    tree
    ghq

    # データ処理・ユーティリティ
    jq
    yq
    (import ./pkgs/ccusage.nix { inherit pkgs; })
    (import ./pkgs/rtk.nix { inherit pkgs; })

    # 認証・セキュリティ
    # socat は WSL2 で 1Password SSH Agent をブリッジするために使う。
    socat
    _1password-cli

    # 開発ツール
    # Claude Code は nix-claude-code input 経由で導入する。
    inputs.nix-claude-code.packages.${pkgs.system}.claude
    codex
    github-copilot-cli
    # prek はグローバル配布せず、各リポジトリで `prek install` して使う。
    prek
    oxfmt
    just
    neovim
    delta
    # lazygit は delta 連携の都合で home/lazygit.nix 側で管理する。
    btop
    nodejs_24
    pnpm
    mise
    (import ./pkgs/difit.nix { inherit pkgs; })
    (import ./pkgs/mo.nix { inherit pkgs; })
    gh
    shellcheck

    # インフラ・クラウド
    kubectl
    argocd
    terraform
    tflint
    google-cloud-sdk
    google-clasp
    cloudflared

    # ネットワーク診断・通信
    wget
    nmap
    nettools
    dnsutils
    traceroute
  ];
}
