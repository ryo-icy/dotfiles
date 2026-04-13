# GEMINI.md

このファイルは Gemini CLI がこのリポジトリ（dotfiles）で作業する際の全体像と、守るべき重要な規約を定義する。

## プロジェクト概要

WSL2 Ubuntu 環境を Nix + home-manager で宣言的に管理する dotfiles リポジトリ。
`flake.nix` をエントリポイントとし、`home/` 以下のモジュールで各ツールの設定を定義している。

### 主要技術スタック
- **Nix / Home Manager**: パッケージ管理および設定ファイルの生成。
- **Zsh / Starship**: シェル環境とプロンプト。
- **1Password**: SSH 秘密鍵、kubeconfig などの機密情報のソース。
- **Docker**: apt で管理（Nix 外）。
- **Claude / Gemini CLI**: `~/.local/bin/` にインストール（Nix 外）。

## アーキテクチャ

```text
.
├── flake.nix             # Nix Flake 定義（nixpkgs, home-manager の入力）
├───home/                 # home-manager モジュール群
│   ├───default.nix       # ルートモジュール（username, homeDirectory 等）
│   ├───packages.nix      # home.packages（Nix 管理パッケージ一覧）
│   ├───shell.nix         # Zsh 設定（エイリアス、プラグイン、gclone/gcd 関数）
│   ├───git.nix           # Git 設定（delta pager・ghq.root・nvim エディタ）
│   ├───ssh.nix           # SSH Config 管理
│   ├───wsl.nix           # WSL2 固有設定（1Password SSH Agent ブリッジ等）
│   ├───claude.nix        # Claude 設定（設定ファイル・フック管理）
│   ├───agent-skills.nix  # agent-skills-nix による Claude/Gemini スキル一元管理
│   ├───nvim.nix          # Neovim 設定
│   ├───yazi.nix          # Yazi ファイルマネージャ（zsh 統合・zoxide キーバインド）
│   ├───lazygit.nix       # Lazygit 設定（delta side-by-side 連携）
│   └───pkgs/             # カスタムパッケージ定義 (difit, ccusage, mo)
├───config/               # アプリケーション設定
│   ├───agents/
│   │   └───skills/       # AI エージェント（Claude/Gemini）共通スキル定義
│   ├───claude/           # Claude 固有設定（settings.json, hooks 等）
│   └───nvim/
│       └───init.lua
├───scripts/              # セットアップ・運用スクリプト

│   ├── bootstrap.sh      # 新規マシン初回セットアップ（全ユニット実行）
│   └── units/            # 個別実行可能なセットアップスクリプト
```

## 主要コマンド

### 設定の反映
設定ファイルを編集した後、以下のコマンドで環境に反映する。
```bash
home-manager switch --flake ".#ryosh"
```

### 依存関係の更新
`flake.lock` を更新して nixpkgs や home-manager のバージョンを上げる。
```bash
nix flake update
# その後 switch で反映
home-manager switch --flake ".#ryosh"
```

### 初回セットアップ
```bash
bash scripts/bootstrap.sh
```

### 1Password 連携（手動実行が必要なもの）
```bash
# SSH 公開鍵のエクスポート（1Password に "dotfiles" タグが付いたキーが対象）
bash scripts/export-ssh-keys.sh

# kubeconfig のエクスポート
bash scripts/export-kubeconfig.sh
```

## 開発・運用の規約

### 言語設定
- **会話・ドキュメント**: 日本語を使用する。
- **コード内コメント**: 日本語で記述する。

### Nix 管理に関する重要事項
- **home.stateVersion**: `home/default.nix` に定義。初回設定時から**絶対に変更しない**。
- **Nix 外管理ツール**: Claude CLI, Gemini CLI, Docker は `bootstrap.sh` で管理する。これらを `home.packages` に追加してはならない。
- **カスタムパッケージ (NPM系)**: `difit`, `ccusage` は `home/pkgs/` 以下の個別の Nix ファイルで定義され、ソースからビルドして `home.packages` に追加されている。
- **カスタムパッケージ (Go バイナリ)**: `mo`（Markdown ビューア）は Go バイナリのため npm ビルド不要。GitHub Releases から linux_amd64 tarball を直接ダウンロードして使用する。
- **NPM ビルドの制約**: Nix サンドボックス内ではネットワークアクセスが禁止されているため、外部フェッチを伴う `pnpm run build` は避け、`tsdown` 等を直接実行して成果物を生成すること。また、`node_modules` 内の壊れたシンボリックリンクは `find -xtype l -delete` で削除すること。
- **npm install**: Nix ストアは読み取り専用のため、`npm install -g` は失敗する。`--prefix "$HOME/.local"` を使用して `~/.local/bin/` にインストールすること。

### 1Password SSH Agent ブリッジ
WSL2 から Windows 側の 1Password SSH Agent を利用するため、`npiperelay.exe` と `socat` を使用したブリッジ（`/tmp/ssh-agent-1p.sock`）を `home/wsl.nix` で構築している。
- `SSH_AUTH_SOCK` は自動的に設定される。
- Git は Linux 側の `ssh` を使用するように設定されている。

### Starship 設定の注意点
`home/starship.nix` で `format` 文字列を定義する際、Nix の `''` (indented string) ではバックスラッシュがエスケープされない。
Starship のパースエラーを防ぐため、`format` は `"` (double-quoted string) で1行に記述し、改行には `\n` を使用すること。

### Windows バイナリの誤検知回避
WSL2 の PATH には Windows 側のバイナリが含まれるため、`command -v` によるインストール確認は誤検知の可能性がある。
`~/.local/bin/` 以下のファイル実体の存在確認を優先すること。

### 秘匿情報の扱い
- 秘密鍵やトークンはリポジトリに含めない。
- kubeconfig は 1Password に保存し、スクリプトで `~/.kube/config` に展開する。
- SSH 公開鍵は `~/.ssh/imported_keys/` に配置され、リポジトリからは除外（`.gitignore`）されている。
