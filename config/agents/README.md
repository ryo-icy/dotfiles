# README.md

このディレクトリは、各 AI エージェントに配信する共通スキルを管理する。

## 目的

- 実体のスキルは `config/agents/skills/` に置く
- 配信設定は `home/agent-skills.nix` で管理する
- `agent-skills-nix` により複数エージェント向けの skills ディレクトリへ同期する

## 編集対象

### スキル本体を更新したいとき

- `config/agents/skills/<skill-name>/SKILL.md` を編集する
- 新しいスキルを追加する場合は `config/agents/skills/<skill-name>/SKILL.md` を新規作成する
- `home/agent-skills.nix` では `skills.enableAll = true;` のため、追加したスキルは自動で配信対象になる

### 配信先を更新したいとき

- `home/agent-skills.nix` の `programs.agent-skills.targets` を編集する
- upstream は `github:Kyure-A/agent-skills-nix`
- target 名や既定パスは upstream README の `Default target paths` を確認する

## 現在の配信先

このリポジトリでは現在、以下を有効化している。

- `agents`
- `codex`
- `claude`
- `copilot`
- `gemini`
- `antigravity`

## 既定パスの目安

upstream README ベースの既定パス:

- `agents`: `$HOME/.agents/skills`
- `codex`: `${CODEX_HOME:-$HOME/.codex}/skills`
- `claude`: `${CLAUDE_CONFIG_DIR:-$HOME/.claude}/skills`
- `copilot`: `$HOME/.copilot/skills`
- `gemini`: `$HOME/.gemini/skills`
- `antigravity`: `$HOME/.gemini/antigravity/skills`

補足:

- Codex はバージョンや設定によって `~/.agents/skills` 系と `~/.codex/skills` 系の両方がありうるため、このリポジトリでは `agents` と `codex` を両方有効化している

## 反映方法

スキル追加・更新後は以下で反映する。

```bash
home-manager switch --flake ".#ryosh"
```

または:

```bash
nix run .#switch
```

## 更新時の注意

- `config/agents/skills/` の構成を変えたら、必要に応じてルートの `README.md` と `AGENTS.md` も更新する
- `home/agent-skills.nix` の target を変えたら、このファイルの「現在の配信先」と「既定パスの目安」も更新する
- upstream の target 名を推測で追加しない。必ず `agent-skills-nix` README を確認する
