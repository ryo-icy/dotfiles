# dotfiles

WSL2 Ubuntu 環境を Nix + home-manager で宣言的に管理する dotfiles リポジトリ。
`flake.lock` で依存を固定し、`scripts/bootstrap.sh` と `home-manager switch` で同じ環境を再現する。

## 概要

- シェル、Git、SSH、Neovim、Yazi、Lazygit を home-manager で管理
- Claude Code は `nix-claude-code` 経由で Nix 管理
- Gemini CLI は `~/.local/bin/` に npm で導入
- 1Password SSH Agent を `npiperelay.exe + socat` で WSL2 にブリッジ
- エージェント用スキルは `agent-skills-nix` で Claude / Gemini (via agents) / Codex / Copilot に配信

## 構成

```text
dotfiles/
├── flake.nix                  # flake input / homeConfiguration / devShell / apps
├── home/
│   ├── default.nix            # home-manager ルートモジュール
│   ├── packages.nix           # Nix 管理パッケージ一覧
│   ├── shell.nix              # zsh 設定、エイリアス、gclone/gcd
│   ├── git.nix                # git 設定（delta, ghq.root, nvim）
│   ├── starship.nix           # starship プロンプト
│   ├── ssh.nix                # SSH 設定
│   ├── wsl.nix                # WSL2 固有設定、SSH_AUTH_SOCK ブリッジ
│   ├── claude.nix             # ~/.claude 配下の設定・hook 配置
│   ├── gemini.nix             # ~/.gemini 配下の設定・hook・policy 配置
│   ├── agent-skills.nix       # agent-skills 配信設定
│   ├── nvim.nix               # ~/.config/nvim/init.lua 配置
│   ├── yazi.nix               # yazi 設定と zsh 統合
│   ├── lazygit.nix            # lazygit と delta の連携設定
│   └── pkgs/                  # カスタムパッケージ (ccusage, difit, mo, rtk)
├── config/
│   ├── claude/
│   │   ├── settings.json
│   │   ├── statusline-command.sh
│   │   └── hooks/
│   │       ├── notify.sh
│   │       └── rtk-rewrite.sh
│   ├── gemini/
│   │   ├── settings.json
│   │   ├── hooks/notify.sh
│   │   └── policies/claude-sync.toml
│   ├── agents/
│   │   └── skills/            # branch / commit / pr / review-plan
│   └── nvim/init.lua
└── scripts/
    ├── bootstrap.sh
    ├── export-ssh-keys.sh
    ├── export-kubeconfig.sh
    └── units/
        ├── 01-backup.sh
        ├── 02-docker.sh
        ├── 03-nix.sh
        ├── 04-npiperelay.sh
        ├── 05-home-manager.sh
        ├── 07-gemini.sh
        ├── 08-ssh-keys.sh
        ├── 09-chsh.sh
        └── 10-kubeconfig.sh
```

## 管理対象

| 対象 | 管理方法 |
|---|---|
| `~/.zshrc` | `home/shell.nix` + `home/wsl.nix` |
| `~/.gitconfig` | `home/git.nix` |
| `~/.config/starship.toml` | `home/starship.nix` |
| `~/.ssh/config` | `home/ssh.nix` |
| `~/.claude/*` | `home/claude.nix` |
| `~/.gemini/hooks/*`, `~/.gemini/policies/*` | `home/gemini.nix` |
| `~/.gemini/settings.json` | `home/gemini.nix` がベース設定をマージ |
| agent skills | `home/agent-skills.nix` + `config/agents/skills/` |
| `~/.config/nvim/init.lua` | `home/nvim.nix` |
| yazi 設定 | `home/yazi.nix` |
| lazygit 設定 | `home/lazygit.nix` |
| Claude Code, Codex, Copilot CLI, kubectl など | `home/packages.nix` |
| `ccusage`, `difit`, `mo`, `rtk` | `home/pkgs/*.nix` |

## Nix 管理外

| ツール/データ | 配置先 | 理由 |
|---|---|---|
| Gemini CLI | `~/.local/bin/gemini` | npm の最新版を使うため |
| Docker Engine | apt | systemd / cgroup など OS レベル設定が必要 |
| `npiperelay.exe` | `~/.local/bin/npiperelay.exe` | Windows named pipe を WSL2 に中継するため |
| `~/.ssh/imported_keys/` | ホームディレクトリ | 1Password から都度エクスポートするため |
| `~/.kube/config` | ホームディレクトリ | シークレットをリポジトリに含めないため |
| SSH 秘密鍵 | 1Password | ファイル保存しない運用のため |

## セットアップ

### 新規マシン

```bash
git clone git@github.com:ryo-icy/dotfiles.git ~/codes/dotfiles
cd ~/codes/dotfiles
bash scripts/bootstrap.sh
```

`bootstrap.sh` は次を順に実行する。

1. 既存 dotfiles をバックアップ
2. Docker Engine をインストール
3. Nix をインストール
4. `npiperelay.exe` を配置
5. `home-manager switch` を実行
6. Gemini CLI を `~/.local/bin/` にインストール
7. 1Password から SSH 公開鍵をエクスポート
8. デフォルトシェルを zsh に変更
9. 1Password から kubeconfig をエクスポート

Claude Code は `05-home-manager.sh` の中で Nix 管理パッケージとして導入される。

### 既存マシンで設定を反映

```bash
cd ~/codes/dotfiles
home-manager switch --flake ".#ryosh"
```

または:

```bash
nix run .#switch
```

### 特定ユニットだけ再実行

```bash
bash scripts/units/05-home-manager.sh
bash scripts/units/07-gemini.sh
bash scripts/units/08-ssh-keys.sh
bash scripts/units/10-kubeconfig.sh
```

## 更新運用

### Home Manager の状態バージョン

`home/default.nix` の `home.stateVersion` は初回アクティベーション時点の互換性基準であり、以後変更しない。

### flake.lock

`flake.lock` はリポジトリにコミットして固定する。

```bash
nix flake update
git add flake.lock
git commit -m "chore: nix flake update"
home-manager switch --flake ".#ryosh"
```

特定 input だけ更新する場合:

```bash
nix flake update nixpkgs
```

### Gemini CLI の更新

```bash
update-gemini
# または
bash scripts/units/07-gemini.sh
```

## 1Password 連携

### SSH Agent ブリッジ

Windows 側の `\\.\pipe\openssh-ssh-agent` を `npiperelay.exe + socat` で `/tmp/ssh-agent-1p.sock` に中継し、Linux ネイティブの `ssh` や `op` から使う。

```text
1Password (Windows)
  └─ \\.\pipe\openssh-ssh-agent
       └─ npiperelay.exe + socat
            └─ /tmp/ssh-agent-1p.sock
```

`home/wsl.nix` が `SSH_AUTH_SOCK=/tmp/ssh-agent-1p.sock` を設定するため、`core.sshCommand` を上書きせずに Linux 側の `~/.ssh/config` をそのまま使える。

### SSH 公開鍵のエクスポート

```bash
op signin
bash scripts/export-ssh-keys.sh
bash scripts/export-ssh-keys.sh my-tag
bash scripts/export-ssh-keys.sh ""
```

出力先は `~/.ssh/imported_keys/`。1Password の SSH Key アイテム名をベースに `<name>.pub` を生成する。

### kubeconfig のエクスポート

```bash
op signin
bash scripts/export-kubeconfig.sh
bash scripts/export-kubeconfig.sh my-kubeconfig
```

1Password の Document アイテムを `~/.kube/config` に書き出す。

## エージェント設定

- Claude Code の設定は `config/claude/settings.json`
- Claude 用 hook は `notify.sh` と `rtk-rewrite.sh`
- Gemini の設定は `config/gemini/settings.json`
- Gemini の `settings.json` は symlink ではなくマージ方式で管理する
- 共通スキルは `config/agents/skills/` に置き、`agent-skills-nix` で配信する
- 配信先は Claude / Gemini (via agents) / Codex / Copilot

## カスタムパッケージ

`home/pkgs/` では nixpkgs 未収録ツールを個別に定義する。

- `ccusage`: Claude API 使用量確認ツール
- `difit`: Git 差分ビューア
- `mo`: Markdown ビューア
- `rtk`: Claude Code のトークン削減プロキシ

NPM 系ツールを Nix でビルドする場合は、Nix サンドボックスのネットワーク制限と PNPM の壊れた symlink に注意する。

## 便利コマンド

- `gclone`: GitHub リポジトリを fzf で選んで `ghq get`
- `gcd`: `ghq list` から選んで移動
- `yy`: yazi 終了時に移動先へ `cd`
- `lg`: lazygit
- `ccu`, `ccum`, `ccus`: `ccusage` ショートカット

## 検証

```bash
home-manager switch --flake ".#ryosh"

claude --version
codex --version
gemini --version
docker --version

type gclone gcd yy
ls -la ~/.claude ~/.gemini ~/.config/nvim
SSH_AUTH_SOCK=/tmp/ssh-agent-1p.sock ssh-add -l
```
