{ ... }: {
  home.file = {
    ".claude/settings.json" = {
      source = ../config/claude/settings.json;
      force = true;
    };
    ".claude/statusline-command.sh" = {
      source = ../config/claude/statusline-command.sh;
      executable = true;
    };
    ".claude/hooks/notify.sh" = {
      source = ../config/claude/hooks/notify.sh;
      executable = true;
    };
    ".claude/hooks/rtk-rewrite.sh" = {
      source = ../config/claude/hooks/rtk-rewrite.sh;
      executable = true;
    };
  };
}
