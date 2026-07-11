# AGENTS.md

このファイルは、このリポジトリで作業する AI Agent 向けの運用ルールを定義する。

## 言語設定

- 会話は常に日本語で行う。
- コード内コメント、エラーメッセージの説明、ドキュメントも日本語で扱う。

## このリポジトリで優先すること

このリポジトリは、WSL2/Ubuntu および Kubuntu 環境を Nix と home-manager で宣言的に管理するための正本である。初回構築は WSL2 が `scripts/bootstrap.sh`、Kubuntu が `scripts/bootstrap-kubuntu.sh`。日常更新は `nix run .#switch`（WSL2）/ `nix run .#switch-kubuntu`（Kubuntu）を前提とする。

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

### LLM エージェント（Claude Code / Antigravity CLI / Codex / Copilot CLI）

- Claude Code・Antigravity CLI（旧 Gemini CLI）・Codex・Copilot CLI はすべて `llm-agents` input（github:numtide/llm-agents.nix）経由で Nix 管理する。
- `nix-claude-code` input は削除済み。npm による Gemini CLI インストールも廃止。
- Claude Code の導入や更新のために `scripts/units/06-claude.sh` を前提にしない。導入は Home Manager 側で扱う。

### Antigravity CLI

- Antigravity CLI（バイナリ名: `agy`）は Google の Gemini CLI 後継ツール（Gemini CLI は 2026-06-18 廃止）。
- Antigravity CLI は `~/.gemini/` を設定ディレクトリとして継承するため、設定ファイルの管理は `home/antigravity.nix` が `~/.gemini/` 配下を担う。
- WSL2 では Windows 側の `agy` が PATH に混入しうるため、存在確認を `command -v agy` だけで済ませない。
- `~/.gemini/settings.json` は Antigravity が認証情報を書き込むため、symlink ではなくマージ方式で扱う。

### Codex

- Codex CLI 自体は Nix 管理パッケージとして扱う。
- `~/.codex/config.toml` をこのリポジトリで管理する場合、Codex が `projects` や `notice` を追記する前提で、symlink ではなくマージ方式を使う。

### Hister（個人検索エンジン）

- `hister listen` にはデタッチ/デーモンモードがなく、フォアグラウンド常駐前提のため systemd `--user` サービスとして常駐させる（`home/hister.nix`）。
- Claude Code へのMCP登録（`claude mcp add --transport http --scope user hister http://127.0.0.1:4433/mcp`）はClaude Code自身の実行時状態ファイル（`~/.claude.json`）に書き込まれるため、Nix管理の対象外。新しい端末では手動で再実行する。
- `~/.config/hister/rules.json`（skip/priority/aliases）はWeb UI・API・CLIから随時更新される運用データのため、Codexの`config.toml`と同様にsymlink管理せず直接編集する。

### Agent Skills

- 共通スキルの正本は `config/agents/skills/` に置く。
- 配信の有効化や target の切り替えは Home Manager 側の設定を正本とする。
- 配信先やスキル運用の詳細は `config/agents/README.md` で管理する。

### Git Hook

- `prek` 本体は Nix 管理するが、hook 自体は各リポジトリで個別に導入する。
- グローバル `core.hooksPath` は設定しない。
- このリポジトリの定型操作は `just setup` と `just lint` を入口にする。

### 1Password / SSH Agent

- `core.sshCommand` を上書きして回避しない。Linux 側の `~/.ssh/config` と `SSH_AUTH_SOCK` を前提に保つ。
- WSL2: Windows 側 named pipe を socat でブリッジし、`SSH_AUTH_SOCK=/tmp/ssh-agent-1p.sock` に設定する（`home/wsl.nix`）。
- Kubuntu: 1Password for Linux デスクトップアプリが `~/.1password/agent.sock` を提供する（`home/kubuntu.nix`）。

### Kubuntu / Wayland

- Kubuntu は KDE Plasma の Wayland セッション（`plasma-workspace-wayland` パッケージ）を使用する。`scripts/units/12-wayland.sh` が導入し、bootstrap 後に SDDM で「Plasma (Wayland)」を選択して初回ログインする必要がある。
- タッチパッドジェスチャーは `libinput-gestures` + `qdbus` で実装する。KDE Wayland は `zwp_virtual_keyboard_manager_v1` を実装していないため `xdotool`・`wtype` によるキー注入は動作しない。KDE グローバルショートカットは `qdbus org.kde.kglobalaccel` 経由で呼び出す。
- KWin の `SwipeMinFingerCount=4`（`kwinrc [Gestures]`）で 3本指スワイプを KWin ジェスチャー認識から除外し、libinput-gestures に完全委任する。これを設定しないと 3本指スワイプがスクロールとして漏れる。
- タッチパッド設定（NaturalScroll・tapToClick・clickMethod）は `touchpadxlibinputrc` に書き `kcminit kcm_touchpad` autostart で適用する。`qdbus org.kde.KWin /KWin reconfigure` だけでは touchpadxlibinputrc が再読み込みされない。

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

設定反映（WSL2）:

```bash
home-manager switch --flake ".#ryosh"
```

または:

```bash
nix run .#switch
```

設定反映（Kubuntu）:

```bash
home-manager switch --flake ".#ryosh-kubuntu"
```

または:

```bash
nix run .#switch-kubuntu
```

依存更新を伴う場合:

```bash
nix flake update
git add flake.lock
git commit -m "chore: nix flake update"
home-manager switch --flake ".#<設定名>"
```

シークレットの再配置:

```bash
op signin
bash scripts/export-ssh-keys.sh
bash scripts/export-kubeconfig.sh
```

新規端末への Nix trusted-users / cachix 初期設定（bootstrap を実行しない既存環境向け）:

```bash
printf 'trusted-users = root ryosh\nextra-substituters = https://ryo-icy-dotfiles.cachix.org\nextra-trusted-public-keys = ryo-icy-dotfiles.cachix.org-1:b0DWdQSrNhcUcy0WcXH3JuAK4KqA3wGayM9T4YRdpBk=\n' \
  | sudo tee -a /etc/nix/nix.custom.conf && sudo systemctl restart nix-daemon
```

`/etc/nix/nix.conf` は Determinate Systems が管理・上書きするため変更しない。設定は `nix.custom.conf` に書き込む（再起動後も保持される）。新規端末では `scripts/units/03-nix.sh`（bootstrap 経由）が自動で行う。
