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
  shell.nix            # programs.zsh（プラグイン・エイリアス）
  starship.nix         # programs.starship（プロンプト設定）
  git.nix              # programs.git（ssh.exe 連携含む）
  ssh.nix              # programs.ssh（全 Host ブロック）
  wsl.nix              # WSL2 固有設定（npiperelay ブリッジ・PATH）
scripts/
  bootstrap.sh         # 新規マシン初回セットアップスクリプト
  export-ssh-keys.sh   # 1Password から SSH 公開鍵を一括エクスポート
```

## 重要な設計判断

### home.stateVersion
`home/default.nix` の `home.stateVersion` は初回 `home-manager switch` 時のバージョンを設定し、**以後絶対に変更しない**。
パッケージバージョンではなく home-manager の状態マイグレーション挙動を制御するものであるため。

### Nix 管理外のツール

以下のツールは `scripts/bootstrap.sh` でインストールし、Nix では管理しない。

| ツール | インストール方法 | Nix 管理外の理由 |
|---|---|---|
| Claude CLI | `npm install -g @anthropic-ai/claude-code` | auto-updater が Nix ストアの read-only を破壊するため |
| Gemini CLI | `npm install -g @google/gemini-cli` | Claude CLI と同様の理由 |
| Docker Engine | apt | systemd・cgroup などシステムレベルの設定が必要なため |

### Git が ssh.exe を使う理由
WSL2 上の Linux ネイティブ ssh では Windows 側の 1Password SSH Agent に直接アクセスできない。
`core.sshCommand = "ssh.exe"` により Windows SSH バイナリ経由でエージェントを利用する。

### npiperelay ブリッジの役割
Linux ネイティブ ssh（`ssh.exe` エイリアス経由でない場合）や `op` CLI など、
`SSH_AUTH_SOCK` を参照するツールが 1Password SSH Agent を使えるようにするためのブリッジ。
- Windows 側: `\\.\pipe\openssh-ssh-agent`（1Password が提供）
- Linux 側: `/tmp/ssh-agent-1p.sock`（`$SSH_AUTH_SOCK` に設定）

## 設定変更の手順

```bash
# 設定を編集後、反映する
home-manager switch --flake ".#ryosh"

# パッケージを追加する場合
# home/packages.nix を編集してから上記コマンドを実行
```

## SSH 公開鍵の管理

SSH 公開鍵は `~/.ssh/imported_keys/` に置かれ、リポジトリには含まない。
秘密鍵は 1Password で管理し、ファイルには保存しない。

`home/ssh.nix` の `identityFile` パスは 1Password アイテム名に対応している:
- `github.com` アイテム → `~/.ssh/imported_keys/github.com.pub`
- `rouzinkai` アイテム → `~/.ssh/imported_keys/rouzinkai.pub`

新しいキーを追加する際は:
1. 1Password にキーを保存し `dotfiles` タグを付ける
2. `home/ssh.nix` に対応する `matchBlocks` エントリを追加する
3. `home-manager switch` で反映する
4. `bash scripts/export-ssh-keys.sh` で公開鍵をエクスポートする
