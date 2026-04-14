{ ... }: {
  # home-manager automatically injects `eval "$(starship init zsh)"` into
  # the generated ~/.zshrc when programs.zsh.enable is also true.
  programs.starship = {
    enable = true;
    settings = {
      format = "[░▒](#a3aed2)$username[ ](bg:#769ff0 fg:#a3aed2)$directory[ ](fg:#769ff0 bg:#394260)$git_branch$git_status$nix_shell[ ](fg:#394260)\n$character";

      nix_shell = {
        symbol = " ";
        style = "bg:#394260";
        format = "[[ $symbol$state( \\($name\\)) ](fg:#769ff0 bg:#394260)]($style)";
        impure_msg = "";
      };

      username = {
        show_always = true;
        style_user  = "bg:#a3aed2";
        style_root  = "bg:#a3aed2";
        format      = "[ $user ]($style)";
        disabled    = false;
      };

      directory = {
        style             = "fg:#e3e5e5 bg:#769ff0";
        format            = "[ $path ]($style)";
        truncation_length = 3;
        truncation_symbol = "…/";
        substitutions = {
          "Documents" = "󰈙 ";
          "Downloads" = " ";
          "Music"     = " ";
          "Pictures"  = " ";
        };
      };

      git_branch = {
        symbol = "";
        style  = "bg:#394260";
        format = "[[ $symbol $branch ](fg:#769ff0 bg:#394260)]($style)";
      };

      git_status = {
        style  = "bg:#394260";
        format = "[[($all_status$ahead_behind )](fg:#769ff0 bg:#394260)]($style)";
      };
    };
  };
}
