{ ... }: {
  programs.agent-skills = {
    enable = true;
    sources.base = {
      # flake inputs に追加した "agent-skills-src" を指定
      input = "agent-skills-src";
    };

    # すべてのスキルを有効化
    skills.enableAll = true;

    # Claude / Gemini / Codex / GitHub Copilot 向けに配信
    # upstream: https://github.com/Kyure-A/agent-skills-nix
    targets = {
      # Codex 系: upstream には共通 `agents` と `codex` の両方がある
      # 現行 Codex は ~/.agents/skills を使う系統もあるため両方有効化する
      agents.enable = true;
      codex.enable = true;
      claude.enable = true;
      copilot.enable = true;
      gemini.enable = false; # ~/.agents/skills と競合するため無効化
      antigravity.enable = false; # 同上
    };
  };
}
