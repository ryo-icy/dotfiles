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
    rust-overlay = {
      url = "github:oxalica/rust-overlay";
      inputs.nixpkgs.follows = "nixpkgs";
    };
    nix-claude-code = {
      url = "github:ryoppippi/nix-claude-code";
      inputs.nixpkgs.follows = "nixpkgs";
    };
  };

  outputs = { self, nixpkgs, home-manager, agent-skills-nix, agent-skills-src, rust-overlay, nix-claude-code, ... }@inputs:
    let
      system = "x86_64-linux";
      pkgs = import nixpkgs {
        inherit system;
        config.allowUnfree = true;
        overlays = [ (import rust-overlay) ];
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

      devShells.${system} = {
        rust = pkgs.mkShell {
          name = "rust-dev-shell";
          TZ = "Asia/Tokyo";
          buildInputs = with pkgs; [
            # Rust stable (Windows cross-compile target included)
            (rust-bin.stable.latest.default.override {
              extensions = [ "rust-src" "rust-analyzer" ];
              targets = [ "x86_64-pc-windows-msvc" ];
            })
            # Windows cross-compile toolchain
            cargo-xwin
            llvm    # llvm-rc (Windows resource compiler for tauri-winres)
            clang   # clang-cl (C cross-compiler for MSVC target)
            lld     # lld-link (linker for MSVC target)
            # Node.js & pnpm
            nodejs_20
            pnpm
            # Tauri build dependencies (Linux host)
            pkg-config
            dbus
            openssl_3
            glib
            gtk3
            libsoup_3
            webkitgtk_4_1
            librsvg
            # タイムゾーンDB（statusline の時刻表示に必要）
            tzdata
            zsh
          ];

          shellHook = ''
            export LD_LIBRARY_PATH=${pkgs.lib.makeLibraryPath (with pkgs; [
              webkitgtk_4_1
              gtk3
              cairo
              gdk-pixbuf
              glib
              dbus
              openssl_3
              librsvg
            ])}:$LD_LIBRARY_PATH
            export XDG_DATA_DIRS=$GSETTINGS_SCHEMAS_PATH
            export TZDIR=${pkgs.tzdata}/share/zoneinfo
            echo "Rust & Tauri development environment loaded!"
            echo "Run 'pnpm tauri dev' to start."
            # インタラクティブシェルの場合（手動で nix develop した時）のみ zsh を起動
            if [[ $- == *i* ]]; then
              exec zsh
            fi
          '';
        };

        python = pkgs.mkShell {
          name = "python-dev-shell";
          TZ = "Asia/Tokyo";
          buildInputs = with pkgs; [
            (python3.withPackages (ps: with ps; [
              pip
              setuptools
              virtualenv
            ]))
            ruff           # 高速な Linter/Formatter (Python のデファクトになりつつある)
            pyright        # 静的型チェック (VSCode との相性が良い)
            uv             # 超高速な Python パッケージマネージャ (pip の代替として推奨)
            zsh
          ];

          shellHook = ''
            export PYTHONBREAKPOINT=ipdb.set_trace
            echo "Python development environment loaded!"
            echo "Python version: $(python --version)"
            echo "Linter/Formatter: ruff"
            # インタラクティブシェルの場合（手動で nix develop した時）のみ zsh を起動
            if [[ $- == *i* ]]; then
              exec zsh
            fi
          '';
        };
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
