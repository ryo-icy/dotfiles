{ lib, ... }:
let
  skillsDir = ../config/claude/skills;
  # .gitkeep を除いてスキルファイルを列挙する
  skillFiles = builtins.filter
    (name: name != ".gitkeep")
    (builtins.attrNames (builtins.readDir skillsDir));
in {
  home.file = lib.listToAttrs (map (name: {
    name = ".claude/skills/${name}";
    value = { source = "${skillsDir}/${name}"; };
  }) skillFiles) // {
    ".claude/settings.json".source = ../config/claude/settings.json;
    ".claude/statusline-command.sh" = {
      source = ../config/claude/statusline-command.sh;
      executable = true;
    };
    ".claude/hooks/notify.sh" = {
      source = ../config/claude/hooks/notify.sh;
      executable = true;
    };
  };
}
