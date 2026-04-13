{
  description = "ryo-icy dotfiles";

  inputs = {
    nixpkgs.url = "github:NixOS/nixpkgs/nixos-unstable";
    home-manager = {
      url = "github:nix-community/home-manager";
      inputs.nixpkgs.follows = "nixpkgs";
    };
    agent-skills-nix = {
      url = "github:Kyure-A/agent-skills-nix";
      inputs.nixpkgs.follows = "nixpkgs";
    };
    agent-skills-src = {
      url = "path:./config/agents/skills";
      flake = false;
    };
  };

  outputs = { self, nixpkgs, home-manager, agent-skills-nix, agent-skills-src, ... }@inputs:
    let
      system = "x86_64-linux";
      pkgs = import nixpkgs {
        inherit system;
        config.allowUnfree = true;
      };
    in {
      homeConfigurations."ryosh" = home-manager.lib.homeManagerConfiguration {
        inherit pkgs;
        extraSpecialArgs = { inherit inputs; };
        modules = [
          ./home/default.nix
          agent-skills-nix.homeManagerModules.default
        ];
      };

      apps.${system} = {
        update = {
          type = "app";
          program = toString (pkgs.writeShellScript "flake-update" ''
            set -e
            echo "Updating flake.lock..."
            nix flake update
            echo "Done! Run 'nix run .#switch' to apply changes."
          '');
        };
        switch = {
          type = "app";
          program = toString (pkgs.writeShellScript "home-manager-switch" ''
            set -e
            echo "Building and switching to Home Manager configuration..."
            nix run nixpkgs#home-manager -- switch --flake .#ryosh
            echo "Done!"
          '');
        };
      };
    };
}
