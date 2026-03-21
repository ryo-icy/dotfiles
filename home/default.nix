{ ... }: {
  imports = [
    ./packages.nix
    ./shell.nix
    ./git.nix
    ./starship.nix
    ./ssh.nix
    ./wsl.nix
    ./claude.nix
  ];

  home.username = "ryosh";
  home.homeDirectory = "/home/ryosh";
  # Set once at initial activation. Never change after first `home-manager switch`.
  home.stateVersion = "24.11";

  programs.home-manager.enable = true;
}
