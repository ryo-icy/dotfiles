{ ... }: {
  home.file = {
    ".gemini/settings.json" = {
      source = ../config/gemini/settings.json;
      force = true;
    };
    ".gemini/hooks/notify.sh" = {
      source = ../config/gemini/hooks/notify.sh;
      executable = true;
    };
  };
}
