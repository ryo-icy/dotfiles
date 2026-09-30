{ pkgs, ... }:
let
  jsonFormat = pkgs.formats.json { };

  # Grafana MCPサーバーをClaude Codeの「プラグイン」機能経由で宣言的に登録する。
  # `claude mcp add` のような対話的コマンドは実行しない。
  # URL・トークンはNixストアに焼き込まず、`.mcp.json` には変数名の参照だけを書く。
  # 実体はシェル側で1Passwordから `GRAFANA_URL` / `GRAFANA_SERVICE_ACCOUNT_TOKEN` としてexportしておく。
  grafanaMcpMarketplaceJson = jsonFormat.generate "grafana-mcp-marketplace.json" {
    name = "grafana-mcp-marketplace";
    owner.name = "ryosh";
    plugins = [
      {
        name = "grafana-mcp";
        source = "./grafana-mcp";
      }
    ];
  };
  grafanaMcpPluginJson = jsonFormat.generate "grafana-mcp-plugin.json" {
    name = "grafana-mcp";
    description = "Grafana MCP server (grafana/mcp-grafana)";
  };
  grafanaMcpServerJson = jsonFormat.generate "grafana-mcp.mcp.json" {
    mcpServers.grafana = {
      type = "stdio";
      command = "mcp-grafana";
      env = {
        GRAFANA_URL = "\${GRAFANA_URL}";
        GRAFANA_SERVICE_ACCOUNT_TOKEN = "\${GRAFANA_SERVICE_ACCOUNT_TOKEN}";
      };
    };
  };
  grafanaMcpMarketplace = pkgs.runCommand "claude-grafana-mcp-marketplace" { } ''
    install -Dm644 ${grafanaMcpMarketplaceJson} $out/.claude-plugin/marketplace.json
    install -Dm644 ${grafanaMcpPluginJson} $out/grafana-mcp/.claude-plugin/plugin.json
    install -Dm644 ${grafanaMcpServerJson} $out/grafana-mcp/.mcp.json
  '';
in {
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
    ".claude/grafana-mcp-marketplace" = {
      source = grafanaMcpMarketplace;
    };
  };
}
