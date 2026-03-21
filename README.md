# dotfiles

WSL2 Ubuntu 環境を宣言的に管理する dotfiles リポジトリ。
Nix + home-manager を使用し、新しいマシンでも `bootstrap.sh` 一発で環境を再現できる。

## 構成

```
dotfiles/
├── flake.nix                  # Nix フレーク定義
├── home/
│   ├── default.nix            # home-manager ルート設定
│   ├── packages.nix           # 管理パッケージ一覧
│   ├── shell.nix              # Zsh 設定（プラグイン・エイリアス・補完）
│   ├── starship.nix           # Starship プロンプト設定
│   ├── git.nix                # Git 設定
│   ├── ssh.nix                # SSH クライアント設定
│   └── wsl.nix                # WSL2 固有設定（SSH Agent ブリッジ等）
└── scripts/
    ├── bootstrap.sh              # 全ユニットを順番に実行するオーケストレーター
    ├── export-ssh-keys.sh        # 1Password から SSH 公開鍵をエクスポート
    ├── export-kubeconfig.sh      # 1Password から kubeconfig をエクスポート
    └── units/                    # 各ユニットは単独でも実行可能
        ├── 01-backup.sh          # 既存 dotfile のバックアップ
        ├── 02-docker.sh          # Docker Engine のインストール
        ├── 03-nix.sh             # Nix のインストール
        ├── 04-npiperelay.sh      # npiperelay.exe のダウンロード
        ├── 05-home-manager.sh    # home-manager switch の実行
        ├── 06-claude.sh          # Claude CLI のインストール
        ├── 07-gemini.sh          # Gemini CLI のインストール
        ├── 08-ssh-keys.sh        # SSH 公開鍵のエクスポート
        ├── 09-chsh.sh            # デフォルトシェルを zsh に変更
        └── 10-kubeconfig.sh      # kubeconfig のエクスポート
```

## 管理対象

| 設定ファイル | モジュール |
|---|---|
| `~/.zshrc` | `home/shell.nix` + `home/wsl.nix` |
| `~/.gitconfig` | `home/git.nix` |
| `~/.config/starship.toml` | `home/starship.nix` |
| `~/.ssh/config` | `home/ssh.nix` |

**Nix 管理外**（bootstrap.sh でインストール）:
- Claude CLI — npm (`@anthropic-ai/claude-code`)、auto-updater のため Nix 管理外
- Gemini CLI — npm (`@google/gemini-cli`)
- Docker Engine — apt、システムレベルの設定が必要なため Nix 管理外
- `~/.ssh/imported_keys/` — SSH 公開鍵（1Password からエクスポート、リポジトリ外）
- `~/.kube/config` — kubeconfig（1Password からエクスポート、リポジトリ外）
- 秘密鍵 — 1Password で管理、ファイルには保存しない

## セットアップ

### 新規マシン（Nix 未インストール）

```bash
git clone git@github.com:ryo-icy/dotfiles.git ~/codes/dotfiles
cd ~/codes/dotfiles
bash scripts/bootstrap.sh
```

bootstrap.sh が行うこと:
1. 既存 dotfile をバックアップ（`~/.dotfiles-backup-<timestamp>/`）
2. Docker Engine をインストール（apt）、docker グループにユーザーを追加
3. Nix をインストール（[Determinate Systems インストーラー](https://github.com/DeterminateSystems/nix-installer)）
4. `npiperelay.exe` をダウンロード（`~/.local/bin/`、1Password SSH Agent ブリッジ用）
5. home-manager switch を実行
6. Claude CLI をインストール（`~/.local/bin/`）
7. Gemini CLI をインストール（`~/.local/bin/`）
8. 1Password から SSH 公開鍵をエクスポート
9. デフォルトシェルを zsh に変更
10. 1Password から kubeconfig をエクスポート

### 既存マシン（設定を更新する場合）

```bash
cd ~/codes/dotfiles
home-manager switch --flake ".#ryosh"
```

### 特定のユニットだけ再実行

各ユニットスクリプトは単独でも実行できる。

```bash
# Docker だけ再インストール
bash scripts/units/02-docker.sh

# home-manager の設定を反映
bash scripts/units/05-home-manager.sh

# Claude CLI だけ更新
bash scripts/units/06-claude.sh

# kubeconfig を再エクスポート
bash scripts/units/10-kubeconfig.sh
```

### SSH 公開鍵の再エクスポート

```bash
op signin
bash scripts/units/08-ssh-keys.sh
# または直接
bash scripts/export-ssh-keys.sh
```

### kubeconfig の再エクスポート

```bash
op signin
bash scripts/units/10-kubeconfig.sh
# または直接
bash scripts/export-kubeconfig.sh
```

## 1Password との連携

### SSH Agent（秘密鍵をファイルに保存しない）

1Password Windows アプリの SSH Agent 機能を使用する。
WSL2 からは `npiperelay.exe` + `socat` で Windows の named pipe を Unix ソケットに転送してアクセスする。

```
1Password (Windows)
  └─ \\.\pipe\openssh-ssh-agent
       └─ npiperelay.exe + socat
            └─ /tmp/ssh-agent-1p.sock  ($SSH_AUTH_SOCK)
```

Git は `core.sshCommand = "ssh.exe"` で Windows SSH を直接使用するため、ブリッジ不要。

### SSH 公開鍵のエクスポート

1Password の SSH Key アイテムに `dotfiles` タグを付けておくと、スクリプトが自動で検出・エクスポートする。

```bash
# タグで一括エクスポート（デフォルト: "dotfiles" タグ）
bash scripts/export-ssh-keys.sh

# カスタムタグ
bash scripts/export-ssh-keys.sh my-tag

# タグなし（全 SSH Key アイテム）
bash scripts/export-ssh-keys.sh ""
```

エクスポート先: `~/.ssh/imported_keys/<アイテム名>.pub`

SSH config の `IdentityFile` はアイテム名から自動生成されるパスを参照するため、
1Password のアイテム名と `home/ssh.nix` の `identityFile` パスを合わせておく必要がある。

### kubeconfig の管理

kubeconfig は 1Password にドキュメントタイプで保存し、リポジトリには含めない。

```bash
# 初回：1Password に保存
op document create ~/.kube/config --title "kubeconfig" --tags dotfiles

# 以降：エクスポート
bash scripts/export-kubeconfig.sh
```

## パッケージ管理

Nix で管理するパッケージは `home/packages.nix` に記載。
追加後は `home-manager switch --flake ".#ryosh"` で反映する。

```nix
home.packages = with pkgs; [
  eza bat socat nodejs_22
  _1password-cli jq
  kubectl
  nmap nettools dnsutils traceroute wget
];
```

## 検証

```bash
# Nix 管理パッケージ確認
which eza bat node op kubectl nmap

# bootstrap.sh でインストールしたツール確認
claude --version
gemini --version
docker --version
docker run hello-world

# home-manager 管理のシンボリックリンク確認
ls -la ~/.zshrc ~/.gitconfig ~/.config/starship.toml ~/.ssh/config

# 1Password SSH Agent ブリッジ確認
ls -la /tmp/ssh-agent-1p.sock
SSH_AUTH_SOCK=/tmp/ssh-agent-1p.sock ssh-add -l

# Git SSH 動作確認
git config --get core.sshCommand  # → ssh.exe

# デフォルトシェル確認
echo $SHELL  # → /path/to/zsh
```
