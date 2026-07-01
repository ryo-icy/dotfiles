# dotfiles

開発環境（WSL2/Ubuntu・Kubuntu）を、Nix + [home-manager](https://github.com/nix-community/home-manager) で宣言的に管理するための dotfiles リポジトリです。

SSH は 1Password の SSH Agent を経由して利用し、SSH 公開鍵と kubeconfig は 1Password からエクスポートして配置します。

## 環境別設定

| 設定名 | 環境 | SSH Agent |
|---|---|---|
| `ryosh` | WSL2/Ubuntu | Windows named pipe → socat ブリッジ |
| `ryosh-kubuntu` | Kubuntu (ネイティブ Linux) | 1Password for Linux (`~/.1password/agent.sock`) |

## セットアップ

### 新規（WSL2）

```bash
git clone git@github.com:ryo-icy/dotfiles.git ~/codes/dotfiles
cd ~/codes/dotfiles
bash scripts/bootstrap.sh
```

`bootstrap.sh` は、既存設定のバックアップ、Docker / Nix / Home Manager の導入、1Password SSH Agent ブリッジの準備、公開鍵と kubeconfig の再配置までを順に実行します。LLM エージェント（Claude Code・Antigravity CLI・Codex・Copilot CLI）は Home Manager（05-home-manager.sh）が導入します。

### 新規（Kubuntu）

```bash
git clone git@github.com:ryo-icy/dotfiles.git ~/codes/dotfiles
cd ~/codes/dotfiles
bash scripts/bootstrap-kubuntu.sh
```

`bootstrap-kubuntu.sh` は、既存設定のバックアップ、Docker / Nix / Home Manager の導入、公開鍵と kubeconfig の再配置までを順に実行します。1Password SSH Agent は 1Password for Linux デスクトップアプリ経由で利用するため、事前に「設定 → デベロッパー → SSH Agent」を有効にしておいてください。

bootstrap 完了後、ログアウトして SDDM のログイン画面でセッション選択を **「Plasma (Wayland)」** に切り替えてください。タッチパッドジェスチャーを含む全設定は Wayland セッションを前提としています。

### 既存（WSL2）

```bash
cd ~/codes/dotfiles
home-manager switch --flake ".#ryosh"
```

または:

```bash
nix run .#switch
```

### 既存（Kubuntu）

```bash
cd ~/codes/dotfiles
home-manager switch --flake ".#ryosh-kubuntu"
```

または:

```bash
nix run .#switch-kubuntu
```

特定の処理だけやり直したい場合は、`scripts/units/` 配下のユニットを個別に実行します。

## 日常運用

- 設定変更を反映するときは上記の `home-manager switch` コマンドを使います。
- 依存を更新するときは `nix flake update` のあとに `flake.lock` をコミットし、再度 switch を実行します。
- LLM エージェントの更新は `nix flake update && home-manager switch --flake ".#<設定名>"` で行います。
- このリポジトリの Git hook は `just setup` で導入し、`just lint` でまとめて実行します。

`home.stateVersion` はパッケージ更新用の値ではなく、初回アクティベーション時点の互換性基準です。更新目的で変更しないでください。

## シークレットと外部管理

- SSH 公開鍵と kubeconfig はこのリポジトリで生成せず、1Password からエクスポートして再配置する運用です。
- SSH 公開鍵は `~/.ssh/imported_keys/`、kubeconfig は `~/.kube/config` に配置されます。
- SSH 秘密鍵は 1Password 管理を前提とし、配置はされません。
- WSL2 では Windows 側 named pipe を Linux 側ソケットへブリッジします。Kubuntu では 1Password for Linux のデスクトップアプリが `~/.1password/agent.sock` を提供します。

再エクスポートが必要な場合:

```bash
op signin
bash scripts/export-ssh-keys.sh
bash scripts/export-kubeconfig.sh
```
