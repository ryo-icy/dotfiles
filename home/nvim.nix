{ ... }: {
  home.file.".config/nvim/init.lua" = {
    source = ../config/nvim/init.lua;
    force = true;
  };
}
