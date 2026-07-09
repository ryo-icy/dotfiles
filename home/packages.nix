{ pkgs, lib, isWSL ? true, ... }: {
  home.packages = with pkgs; [
    # シェル・ファイル操作
    eza
    bat
    fzf
    # yazi は shell integration の都合で home/yazi.nix 側で管理する。
    zoxide
    tree
    ripgrep

    # データ処理・ユーティリティ
    jq
    yq
    (import ./pkgs/rtk.nix { inherit pkgs; })

    # 認証・セキュリティ
    _1password-cli
    cachix

    # 開発ツール
    # LLM エージェントは home/llm-agents.nix で管理する。
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
    (import ./pkgs/leaf.nix { inherit pkgs; })
    (import ./pkgs/herdr.nix { inherit pkgs; })
    (import ./pkgs/hunk.nix { inherit pkgs; })
    gh
    ghq
    shellcheck

    # インフラ・クラウド
    kubectl
    argocd
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
  ]
  # WSL2: Windows ファイル/URL を既定アプリで開く、1Password SSH ブリッジ用
  ++ lib.optionals isWSL [ wsl-open socat ]
  # Kubuntu: X11/Wayland 両対応クリップボード操作
  ++ lib.optionals (!isWSL) [ wl-clipboard xclip ];
}
