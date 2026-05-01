# dotfiles

開発環境(Ubuntu/WSL2) 環境を、Nix + [home-manager](https://github.com/nix-community/home-manager) で宣言的に管理するための dotfiles リポジトリです。

このリポジトリは、Windows 11 上で WSL2 による Ubuntu 環境を使い、1Password を併用する前提で構成しています。SSH は 1Password の SSH Agent を経由して利用し、SSH 公開鍵と kubeconfig は 1Password から WSL 側へエクスポートして配置します。

## セットアップ

### 新規

```bash
git clone git@github.com:ryo-icy/dotfiles.git ~/codes/dotfiles
cd ~/codes/dotfiles
bash scripts/bootstrap.sh
```

`bootstrap.sh` は、既存設定のバックアップ、Docker / Nix / Home Manager の導入、1Password SSH Agent ブリッジの準備、Gemini CLI の導入、公開鍵と kubeconfig の再配置までを順に実行します。

### 既存

```bash
cd ~/codes/dotfiles
home-manager switch --flake ".#ryosh"
```

または:

```bash
nix run .#switch
```

特定の処理だけやり直したい場合は、`scripts/units/` 配下のユニットを個別に実行します。

## 日常運用

- 設定変更を反映するときは `home-manager switch --flake ".#ryosh"` か `nix run .#switch` を使います。
- 依存を更新するときは `nix flake update` のあとに `flake.lock` をコミットし、再度 `home-manager switch` を実行します。
- Gemini CLI は Nix 管理外なので、更新は `update-gemini` または `bash scripts/units/07-gemini.sh` で行います。
- このリポジトリの Git hook は `just setup` で導入し、`just lint` でまとめて実行します。

`home.stateVersion` はパッケージ更新用の値ではなく、初回アクティベーション時点の互換性基準です。更新目的で変更しないでください。

## シークレットと外部管理

- SSH 公開鍵と kubeconfig はこのリポジトリで生成せず、1Password からエクスポートして再配置する運用です。
- SSH 公開鍵は `~/.ssh/imported_keys/`、kubeconfig は `~/.kube/config` に配置されます。
- SSH 秘密鍵は 1Password 管理を前提とし、配置はされません。
- WSL2 から 1Password SSH Agent を使うため、Windows 側の named pipe を Linux 側のソケットへブリッジします。

再エクスポートが必要な場合:

```bash
op signin
bash scripts/export-ssh-keys.sh
bash scripts/export-kubeconfig.sh
```
