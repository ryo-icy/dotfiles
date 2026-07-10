{ isWSL ? true, ... }: {
  imports = [
    ./packages.nix
    ./llm-agents.nix
    ./shell.nix
    ./git.nix
    ./starship.nix
    ./ssh.nix
    (if isWSL then ./wsl.nix else ./kubuntu.nix)
    ./claude.nix
    ./antigravity.nix
    ./agent-skills.nix
    ./nvim.nix
    ./yazi.nix
    ./lazygit.nix
    ./tmux.nix
    ./hister.nix
  ];

  home.username = "ryosh";
  home.homeDirectory = "/home/ryosh";
  # Set once at initial activation. Never change after first `home-manager switch`.
  home.stateVersion = "24.11";

  home.sessionPath = [
    "$HOME/.local/bin"
  ];

  home.sessionVariables = {
    TZ = "Asia/Tokyo";
  };

  programs.home-manager.enable = true;
}
