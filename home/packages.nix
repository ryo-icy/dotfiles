{ pkgs, ... }: {
  home.packages = with pkgs; [
    # シェル・ファイル操作
    eza                # ls の代替（カラー・Git 情報付き）
    bat                # cat の代替（シンタックスハイライト付き）
    fzf                # あいまい検索（コマンド履歴・ファイル検索）
    wsl-open           # WSL ユーティリティ（wsl-open でブラウザ起動など）
    # yazi は home/yazi.nix で programs.yazi として管理（shell integration のため）
    zoxide             # スマートな cd コマンド（頻度・最近の履歴で補完）
    tree               # ディレクトリツリー表示
    ghq                # リポジトリ管理（go get スタイル）

    # データ処理・ユーティリティ
    jq                 # JSON パーサ・クエリツール
    yq                 # YAML/JSON/TOML パーサ・クエリツール（mikefarah/yq）
    (import ./pkgs/ccusage.nix { inherit pkgs; })  # Claude API 使用量確認ツール
    (import ./pkgs/rtk.nix { inherit pkgs; })     # Claude Code トークン削減プロキシ（60-90% 削減）

    # 認証・セキュリティ
    socat              # WSL2 で 1Password SSH エージェントブリッジに必要（wsl.nix 参照）
    _1password-cli     # 1Password CLI（op コマンド）

    # 開発ツール
    neovim             # モダンな Vim 互換テキストエディタ
    delta              # git diff ビューア（シンタックスハイライト・サイドバイサイド）
    # lazygit は home/lazygit.nix で programs.lazygit として管理（delta 連携のため）
    btop               # リソースモニタ（CPU・メモリ・ネットワーク）
    nodejs_24          # Node.js ランタイム（NVM の代替）
    pnpm               # pnpm パッケージマネージャ
    (import ./pkgs/difit.nix { inherit pkgs; })    # Git 差分ビューア
    (import ./pkgs/mo.nix { inherit pkgs; })       # Markdown ビューア（ブラウザで開く）
    gh                 # GitHub CLI
    shellcheck         # シェルスクリプトの静的解析ツール

    # インフラ・クラウド
    kubectl            # Kubernetes クラスタ操作
    argocd             # Argo CD 操作用 CLI
    terraform          # インフラのコードによるプロビジョニングツール
    tflint             # Terraform 静的解析ツール
    google-cloud-sdk   # GCP 操作 CLI（gcloud・gsutil・bq）
    google-clasp       # Google Apps Script ローカル開発 CLI（clasp）
    cloudflared        # Cloudflare Tunnel・Access 用 CLI

    # ネットワーク診断・通信
    wget               # ファイルダウンロード
    nmap               # ネットワークスキャン
    nettools           # ifconfig・netstat など基本ネットワークツール
    dnsutils           # dig・nslookup など DNS 調査ツール
    traceroute         # 経路追跡ツール
  ];
}
