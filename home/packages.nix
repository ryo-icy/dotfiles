{ pkgs, ... }: {
  home.packages = with pkgs; [
    eza
    bat
    socat              # required for 1Password SSH agent bridge in wsl.nix
    nodejs_22          # replaces NVM
    _1password-cli     # provides 'op' binary
    # claude CLI is NOT managed here — its auto-updater requires a writable path
  ];
}
