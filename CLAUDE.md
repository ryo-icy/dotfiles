# CLAUDE.md

このファイルは Claude Code がこのリポジトリで作業する際の指示を定義する。

## 言語設定

- **会話**: 常に日本語で行う
- **コード内のコメント**: 日本語で記述する
- **エラーメッセージの説明**: 日本語で行う
- **ドキュメント**: 日本語で生成する

## リポジトリ概要

WSL2 Ubuntu 環境を Nix + home-manager で宣言的に管理する dotfiles リポジトリ。

## アーキテクチャ

```
flake.nix              # nixpkgs + home-manager の入力定義
home/
  default.nix          # ルートモジュール（username, homeDirectory, stateVersion）
  packages.nix         # home.packages（Nix 管理パッケージ）
  shell.nix            # programs.zsh（プラグイン・エイリアス・補完）
  starship.nix         # programs.starship（プロンプト設定）
  git.nix              # programs.git（ssh.exe 連携含む）
  ssh.nix              # programs.ssh（全 Host ブロック）
  wsl.nix              # WSL2 固有設定（npiperelay ブリッジ・PATH）
  claude.nix           # ~/.claude/skills のシンボリックリンク管理
  pkgs/                # カスタムパッケージ定義 (difit, ccusage, openclaw)
claude/
  skills/              # Claude Code スキルファイル（通常形式で管理）
scripts/
  bootstrap.sh              # 新規マシン初回セットアップスクリプト
  export-ssh-keys.sh        # 1Password から SSH 公開鍵を一括エクスポート
  export-kubeconfig.sh      # 1Password から kubeconfig をエクスポート
  units/
    01-backup.sh            # 既存 dotfile のバックアップ
    02-docker.sh            # Docker Engine のインストール
    03-nix.sh               # Nix のインストール
    04-npiperelay.sh        # npiperelay.exe のダウンロード（~/.local/bin/）
    05-home-manager.sh      # home-manager switch の実行
    06-claude.sh            # Claude CLI のインストール（~/.local/bin/）
    07-gemini.sh            # Gemini CLI のインストール（~/.local/bin/）
    08-ssh-keys.sh          # SSH 公開鍵のエクスポート
    09-chsh.sh              # デフォルトシェルを zsh に変更
    10-kubeconfig.sh        # kubeconfig のエクスポート
```

## 重要な設計判断

### home.stateVersion
`home/default.nix` の `home.stateVersion` は初回 `home-manager switch` 時のバージョンを設定し、**以後絶対に変更しない**。
パッケージバージョンではなく home-manager の状態マイグレーション挙動を制御するものであるため。

### Nix 管理のカスタムパッケージ (NPM系)
`difit`, `ccusage`, `openclaw` などの nixpkgs 未収録ツールは、`home/pkgs/` 以下の個別の Nix ファイルで定義し、ソースからビルドする。これにより、NPM ツールのバージョンと依存関係を Nix で宣言的に管理する。

#### ビルド時の注意点
- **ネットワーク制限**: Nix サンドボックス内ではネットワークアクセスが禁止されているため、`pnpm run build` が内部で外部 API やスキーマ（LiteLLM 等）をフェッチしようとする場合、ビルドが失敗する。
- **直接実行の推奨**: `ccusage` のようにビルドスクリプトが複雑な場合は、`pnpm run build` 全体ではなく、`tsdown` などのモジュールバンドラーを `node_modules` から直接実行して最小限の成果物のみを生成する。
- **シンボリックリンクの掃除**: PNPM が作成する `node_modules` 内の壊れたシンボリックリンクは、Nix のビルド成果物スキャンでエラーを引き起こすため、`find -xtype l -delete` で削除する必要がある。

### Nix 管理外のツール

以下のツールは `scripts/bootstrap.sh` でインストールし、Nix では管理しない。

| ツール | インストール先 | Nix 管理外の理由 |
|---|---|---|
| Claude CLI | `~/.local/bin/` (公式ネイティブインストーラー) | auto-updater が Nix ストアの read-only を破壊するため |
| Gemini CLI | `~/.local/bin/` (`npm --prefix ~/.local`) | Claude CLI と同様の理由 |
| Docker Engine | apt | systemd・cgroup などシステムレベルの設定が必要なため |

### npm install の install 先
`npm install -g` はデフォルトで Node.js インストール先（Nix ストア）に書き込もうとするが、Nix ストアは read-only のため失敗する。
`--prefix "$HOME/.local"` を指定して `~/.local/bin/` にインストールする。

### Windows バイナリが PATH に混入する問題
WSL2 では `/mnt/c/` 以下の Windows バイナリも PATH に現れる。
`command -v claude` や `command -v gemini` で既インストール確認すると Windows 側のバイナリを誤検知するため、
`~/.local/bin/claude` の**ファイル存在確認**で判定する。

### npiperelay ブリッジの役割
Linux ネイティブ ssh や `op` CLI など `SSH_AUTH_SOCK` を参照するツールが
1Password SSH Agent を使えるようにするためのブリッジ。
インストール先は `~/.local/bin/npiperelay.exe`。
これにより `ssh.exe` エイリアスは不要となり、`~/.ssh/config`（home-manager 管理）が
すべての SSH 接続に適用される。Git も `core.sshCommand` を設定せず Linux ssh を使用する。
- Windows 側: `\\.\pipe\openssh-ssh-agent`（1Password が提供）
- Linux 側: `/tmp/ssh-agent-1p.sock`（`$SSH_AUTH_SOCK` に設定）

### kubeconfig の管理
kubeconfig にはシークレット情報が含まれるため、リポジトリには含めない。
1Password にドキュメントタイプで保存し、`scripts/export-kubeconfig.sh` で `~/.kube/config` にエクスポートする。

### starship format 文字列の書き方
Nix `''` (indented) 文字列では `\` はエスケープ処理されずリテラルになる。
行末の `\` + 改行が starship の設定ファイルに `\<改行>` として書き込まれ、starship がパースエラーを起こす。
starship の format は Nix `"..."` (double-quoted) 文字列で1行に書き、改行が必要な箇所には `\n` を使う。

### flake.lock の管理

`flake.lock` はリポジトリに含め、nixpkgs・home-manager のリビジョンを固定する。
これにより `bootstrap.sh` による新規マシンセットアップが既存マシンと同一のビルド結果になる。

- **更新するとき**: `nix flake update` を実行し、生成された `flake.lock` の変更をコミットする
- **特定の input だけ更新**: `nix flake update nixpkgs` のように input 名を指定する
- **意図しない更新を防ぐ**: `flake.lock` を変更せずに `home-manager switch` を実行すれば、固定バージョンのまま反映される

## 設定変更の手順

```bash
# 設定を編集後、反映する（flake.lock のバージョン固定を維持）
home-manager switch --flake ".#ryosh"

# パッケージを追加する場合
# home/packages.nix を編集してから上記コマンドを実行

# 依存関係（nixpkgs・home-manager）を最新に更新する場合
nix flake update
git add flake.lock
git commit -m "chore: nix flake update"
home-manager switch --flake ".#ryosh"
```

## SSH 公開鍵の管理

SSH 公開鍵は `~/.ssh/imported_keys/` に置かれ、リポジトリには含まない。
秘密鍵は 1Password で管理し、ファイルには保存しない。

新しいキーを追加する際は:
1. 1Password にキーを保存し `dotfiles` タグを付ける
2. `home/ssh.nix` に対応する `matchBlocks` エントリを追加する
3. `home-manager switch` で反映する
4. `bash scripts/export-ssh-keys.sh` で公開鍵をエクスポートする
