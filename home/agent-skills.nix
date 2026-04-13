{ ... }: {
  programs.agent-skills = {
    enable = true;
    sources.base = {
      # flake inputs に追加した "agent-skills-src" を指定
      input = "agent-skills-src";
    };

    # すべてのスキルを有効化
    skills.enableAll = true;

    # Claude と Gemini の両方に配信
    targets = {
      claude.enable = true;
      gemini.enable = true;
      antigravity.enable = true;
    };
  };
}
