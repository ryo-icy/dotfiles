# AGENTS.md

このファイルは AI Agent（Claude Code / Codex / Gemini）がこのリポジトリで作業する際の指示を定義する。

## 言語設定

- **会話**: 常に日本語で行う
- **コード内のコメント**: 日本語で記述する
- **エラーメッセージの説明**: 日本語で行う
- **ドキュメント**: 日本語で生成する

## リポジトリ概要

WSL2 Ubuntu 環境を Nix + home-manager で宣言的に管理する dotfiles リポジトリ。
`flake.lock` による依存固定、`bootstrap.sh` による初期構築、`home-manager switch` による日常更新を前提にしている。

## 現在のアーキテクチャ

```text
flake.nix              # flake input / homeConfiguration / devShell / apps
home/
  default.nix          # ルートモジュール（imports, username, stateVersion）
  packages.nix         # Nix 管理パッケージ
  shell.nix            # zsh 設定、alias、gclone/gcd
  git.nix              # git 設定（delta, ghq.root, nvim）
  starship.nix         # starship 設定
  ssh.nix              # SSH 設定
  wsl.nix              # SSH_AUTH_SOCK, npiperelay ブリッジ、PATH
  claude.nix           # ~/.claude 配下の設定・hook 配置
  gemini.nix           # ~/.gemini 配下の設定・hook・policy 配置
  agent-skills.nix     # agent-skills の配信設定
  nvim.nix             # ~/.config/nvim/init.lua 配置
  yazi.nix             # yazi 設定と zsh 統合
  lazygit.nix          # lazygit と delta の連携
  pkgs/                # カスタムパッケージ (ccusage, difit, mo, rtk)
config/
  claude/
    settings.json
    statusline-command.sh
    hooks/
      notify.sh
      rtk-rewrite.sh
  gemini/
    settings.json
    hooks/
      notify.sh
    policies/
      claude-sync.toml
  agents/
    skills/
      branch/
      commit/
      pr/
      review-plan/
  nvim/
    init.lua
scripts/
  bootstrap.sh
  export-ssh-keys.sh
  export-kubeconfig.sh
  units/
    01-backup.sh
    02-docker.sh
    03-nix.sh
    04-npiperelay.sh
    05-home-manager.sh
    07-gemini.sh
    08-ssh-keys.sh
    09-chsh.sh
    10-kubeconfig.sh
```

## 重要な設計判断

### home.stateVersion

`home/default.nix` の `home.stateVersion` は初回 `home-manager switch` 時点の互換性基準であり、**以後変更しない**。
パッケージ更新用の値ではない。

### Claude Code は Nix 管理

Claude Code は `flake.nix` の `nix-claude-code` input を通して Nix 管理する。
`scripts/units/06-claude.sh` は存在しない。Claude Code の導入と更新は `05-home-manager.sh` で行う。

- `home/packages.nix` で `inputs.nix-claude-code.packages.${pkgs.system}.claude` を参照する
- auto-updater ではなく `flake.lock` 更新でバージョンが進む

### Gemini CLI は Nix 管理外

Gemini CLI は `scripts/units/07-gemini.sh` で `npm install -g --prefix "$HOME/.local"` により `~/.local/bin/` へ入れる。

- WSL2 では Windows 側の `gemini` が PATH に混入するため、存在確認は `command -v` ではなく `~/.local/bin/gemini` を使う
- `~/.gemini/settings.json` は Gemini が認証情報を書き込むため、symlink ではなくマージ方式で管理する

### agent-skills の配信

共通スキルは `config/agents/skills/` に置き、`agent-skills-nix` で配信する。

- source: `flake.nix` の `agent-skills-src = path:./config/agents/skills`
- `home/agent-skills.nix` で `skills.enableAll = true`
- 配信先は Claude / Gemini / antigravity

### Nix 管理のカスタムパッケージ

`home/pkgs/` で nixpkgs 未収録ツールを定義する。

- `ccusage`: Claude API 使用量確認
- `difit`: Git 差分ビューア
- `mo`: Markdown ビューア
- `rtk`: Claude Code トークン削減プロキシ

NPM 系ツールを Nix でビルドする場合の注意:

- Nix サンドボックス内ではネットワークアクセス不可
- `pnpm run build` 全体ではなく bundler を直接呼ぶほうが安定する場合がある
- PNPM の壊れた symlink は `find -xtype l -delete` で掃除が必要なことがある

### npiperelay ブリッジ

Linux ネイティブ `ssh` や `op` から 1Password SSH Agent を使うため、Windows named pipe を `/tmp/ssh-agent-1p.sock` にブリッジする。

- Windows 側: `\\.\pipe\openssh-ssh-agent`
- Linux 側: `/tmp/ssh-agent-1p.sock`
- `home/wsl.nix` が `SSH_AUTH_SOCK` を設定
- `core.sshCommand` は上書きせず、Linux 側の `~/.ssh/config` をそのまま使う

### npm install の配置先

Nix ストアは read-only のため、`npm install -g` はそのままだと失敗する。
グローバル導入時は `--prefix "$HOME/.local"` を使う。

### flake.lock の管理

`flake.lock` はコミットして固定する。

- 全更新: `nix flake update`
- 個別更新: `nix flake update nixpkgs`
- 反映: `home-manager switch --flake ".#ryosh"` または `nix run .#switch`

## 変更時の実務ルール

### ドキュメント更新時

README / AGENTS の両方に同じ事実が書かれている箇所は、片方だけ直さない。
特に次の差分は古くなりやすいので注意する。

- `scripts/units/` の実在ファイル一覧
- Claude Code の管理方式
- `config/agents/skills/` の存在
- `home/gemini.nix` のマージ管理
- `home/pkgs/` のパッケージ一覧

### Home Manager モジュールを追加したとき

最低限、次を同期して更新する。

1. `home/default.nix` の `imports`
2. README の構成説明
3. この `AGENTS.md` のアーキテクチャ節

### スクリプト変更時

`scripts/bootstrap.sh` と `scripts/units/` の順序・役割が変わった場合は、README とこのファイルの両方を更新する。

## 設定変更の手順

```bash
home-manager switch --flake ".#ryosh"
```

または:

```bash
nix run .#switch
```

依存更新を伴う場合:

```bash
nix flake update
git add flake.lock
git commit -m "chore: nix flake update"
home-manager switch --flake ".#ryosh"
```

## SSH 公開鍵と kubeconfig

- SSH 公開鍵は `~/.ssh/imported_keys/` に置き、リポジトリには含めない
- kubeconfig は `~/.kube/config` に置き、リポジトリには含めない
- 秘密鍵は 1Password 管理で、ファイルに保存しない

再エクスポート:

```bash
op signin
bash scripts/export-ssh-keys.sh
bash scripts/export-kubeconfig.sh
```
