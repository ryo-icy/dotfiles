{ ... }: {
  home.file = {
    ".gemini/settings.json".source = ../config/gemini/settings.json;
    ".gemini/hooks/notify.sh" = {
      source = ../config/gemini/hooks/notify.sh;
      executable = true;
    };
  };
}
