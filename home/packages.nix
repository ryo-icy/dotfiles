{ pkgs, ... }: {
  home.packages = with pkgs; [
    (import ./ccusage.nix { inherit pkgs; })
    eza
    bat
    socat              # required for 1Password SSH agent bridge in wsl.nix
    nodejs_22          # replaces NVM
    _1password-cli     # provides 'op' binary
    jq                 # export-ssh-keys.sh で JSON パースに使用
    kubectl            # Kubernetes クラスタ操作

    # ネットワークトラブルシューティング
    nmap               # ポートスキャン・ネットワーク探索
    nettools           # ifconfig, netstat, route など
    dnsutils           # dig, nslookup
    traceroute         # ルート追跡
    wget               # HTTP ダウンロード
    # claude CLI is NOT managed here — its auto-updater requires a writable path
  ];
}
