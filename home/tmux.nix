{ pkgs, ... }: {
  programs.tmux = {
    enable = true;
    mouse = true;
    keyMode = "vi";
    terminal = "tmux-256color";
    # neovim との相性上、エスケープタイムを短くする
    escapeTime = 10;
    historyLimit = 10000;

    plugins = with pkgs.tmuxPlugins; [
      sensible
      yank
      resurrect
    ];

    extraConfig = ''
      # True color
      set-option -sa terminal-overrides ",xterm-256color:RGB"

      # | / - でペイン分割（現在のパスを引き継ぐ）
      bind | split-window -h -c "#{pane_current_path}"
      bind - split-window -v -c "#{pane_current_path}"

      # vim ライクなペイン移動
      bind h select-pane -L
      bind j select-pane -D
      bind k select-pane -U
      bind l select-pane -R
    '';
  };
}
