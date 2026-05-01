# AGENTS.md

このファイルは、このリポジトリで作業する AI Agent 向けの運用ルールを定義する。

## 言語設定

- 会話は常に日本語で行う。
- コード内コメント、エラーメッセージの説明、ドキュメントも日本語で扱う。

## このリポジトリで優先すること

このリポジトリは、WSL2 Ubuntu 環境を Nix と home-manager で宣言的に管理するための正本である。初回構築は `scripts/bootstrap.sh`、日常更新は `home-manager switch` または `nix run .#switch` を前提とする。

ルートのドキュメントは高レベルの方針だけを書く。あるディレクトリ固有の運用や判断基準は、そのディレクトリの `README.md` または `AGENTS.md` に置き、上位ドキュメントへ詳細を積み増さない。

## ドキュメント原則

- `README.md` は人間向け、`AGENTS.md` は AI Agent 向けとして役割を分ける。
- `CLAUDE.md` や `GEMINI.md` を置く場合は別管理せず、`AGENTS.md` へのシンボリックリンクにする。
- tree 形式やファイル一覧をドキュメントに書かない。構造説明が必要なら prose で責務だけを書く。
- 設計理由、制約、正本、変更時の非自明な手順を書く。コードを読めば分かる説明は避ける。
- ある変更が特定ディレクトリだけに閉じるなら、ルートではなくそのディレクトリのドキュメントを更新する。

## 重要な設計判断

### Home Manager

- `home.stateVersion` は初回 `home-manager switch` 時点の互換性基準であり、以後変更しない。
- 新しい Home Manager モジュールを追加したら、`home/default.nix` の import と関連ドキュメントを同期する。

### Claude Code

- Claude Code は `nix-claude-code` input 経由で Nix 管理する。
- Claude Code の導入や更新のために `scripts/units/06-claude.sh` を前提にしない。導入は Home Manager 側で扱う。

### Gemini CLI

- Gemini CLI は Nix 管理外で、`npm install -g --prefix "$HOME/.local"` により `~/.local/bin` へ導入する。
- WSL2 では Windows 側の `gemini` が PATH に混入しうるため、存在確認を `command -v gemini` だけで済ませない。
- `~/.gemini/settings.json` は Gemini が認証情報を書き込むため、symlink ではなくマージ方式で扱う。

### Codex

- Codex CLI 自体は Nix 管理パッケージとして扱う。
- `~/.codex/config.toml` をこのリポジトリで管理する場合、Codex が `projects` や `notice` を追記する前提で、symlink ではなくマージ方式を使う。

### Agent Skills

- 共通スキルの正本は `config/agents/skills/` に置く。
- 配信の有効化や target の切り替えは Home Manager 側の設定を正本とする。
- 配信先やスキル運用の詳細は `config/agents/README.md` で管理する。

### Git Hook

- `prek` 本体は Nix 管理するが、hook 自体は各リポジトリで個別に導入する。
- グローバル `core.hooksPath` は設定しない。
- このリポジトリの定型操作は `just setup` と `just lint` を入口にする。

### 1Password / WSL2

- Linux ネイティブの `ssh` や `op` から 1Password SSH Agent を使うため、Windows 側 named pipe を Linux 側ソケットへブリッジする。
- `core.sshCommand` を上書きして回避しない。Linux 側の `~/.ssh/config` と `SSH_AUTH_SOCK` を前提に保つ。

### Nix 管理のカスタムパッケージ

- nixpkgs 未収録ツールは `home/pkgs/` で管理する。
- NPM 系ツールを Nix でビルドする場合は、サンドボックスのネットワーク制限と壊れた symlink の扱いに注意する。

## 変更時の判断基準

- `README.md` と `AGENTS.md` に同じ事実を書いている場合は、片方だけ更新しない。
- `bootstrap.sh` や `scripts/units/` の順序、役割、前提が変わったら両方のドキュメントを更新する。
- ファイルを追加しただけではドキュメント更新は不要。設計意図、責務、導線が変わるときだけ更新する。
- 新しいディレクトリに固有ルールが生まれたら、そのディレクトリへ `README.md` または `AGENTS.md` を追加する。
- 他人の未コミット変更がある前提で作業し、依頼されていない差分を戻さない。

## 変更時の実務メモ

設定反映:

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

シークレットの再配置:

```bash
op signin
bash scripts/export-ssh-keys.sh
bash scripts/export-kubeconfig.sh
```
