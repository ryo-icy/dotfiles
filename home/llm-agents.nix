{ llm-agents, ... }: {
  home.packages = [
    llm-agents.claude-code
    llm-agents.antigravity-cli
    llm-agents.codex
    llm-agents.copilot-cli
    llm-agents.ccusage
  ];
}
