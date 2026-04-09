{ pkgs, ... }: {
  home.packages = with pkgs; [
    # シェル・ファイル操作
    eza                # ls の代替（カラー・Git 情報付き）
    bat                # cat の代替（シンタックスハイライト付き）

    # データ処理・ユーティリティ
    jq                 # JSON パーサ・クエリツール
    (import ./pkgs/ccusage.nix { inherit pkgs; })  # Claude API 使用量確認ツール

    # 認証・セキュリティ
    socat              # WSL2 で 1Password SSH エージェントブリッジに必要（wsl.nix 参照）
    _1password-cli     # 1Password CLI（op コマンド）

    # 開発ツール
    nodejs_24          # Node.js ランタイム（NVM の代替）
    (import ./pkgs/difit.nix { inherit pkgs; })    # Git 差分ビューア
    (import ./pkgs/openclaw.nix { inherit pkgs; }) # AI エージェント CLI
    gh                 # GitHub CLI

    # インフラ・クラウド
    kubectl            # Kubernetes クラスタ操作

    # ネットワーク診断・通信
    wget               # ファイルダウンロード
    nmap               # ネットワークスキャン
    nettools           # ifconfig・netstat など基本ネットワークツール
    dnsutils           # dig・nslookup など DNS 調査ツール
    traceroute         # 経路追跡ツール
  ];
}
