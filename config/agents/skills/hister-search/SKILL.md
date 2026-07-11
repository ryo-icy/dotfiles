---
name: hister-search
description: Histerで索引化した自分のブラウジング履歴・保存ページをローカルの`hister search`コマンドで検索する。キーワードから関連ページのタイトル・URL・閲覧日時を提示し、必要ならブラウザで開く。
disable-model-invocation: true
---

Histerサーバー（`hister listen`、systemd `--user`サービスとして常駐）に対して`hister search`コマンドで検索を行い、結果を整形して提示する。

## 前提

- Histerサーバーは`systemctl --user status hister`で常駐している前提（`home/hister.nix`でsystemd `--user`サービス化済み）。
- サーバーURLは既定（`http://127.0.0.1:4433`相当）で疎通する。ユーザーから別サーバーを指定された場合のみ`--server-url`を付ける。
- Claude Codeではhister MCPサーバー（`http://127.0.0.1:4433/mcp`、`--scope user`で登録済み）が利用可能な場合がある。その場合は`search`/`get_preview`/`get_history`のMCPツールを優先し、このスキルのシェルコマンドは使わない。MCP未登録の環境（Codex・Copilot CLI・Antigravity等）でのみ以下の手順に従う。

## 手順

### 1. サーバー疎通確認

検索前に軽くサーバーの生存確認を行う：

```bash
systemctl --user is-active hister
```

`inactive`や`failed`の場合は起動を試みてからユーザーに報告する：

```bash
systemctl --user restart hister
```

### 2. 検索実行

ユーザーの依頼からキーワードを抽出し、JSON形式・必要最小限のフィールドで検索する。`favicon`や`html`、`text`フィールドは巨大なペイロード（faviconはbase64画像）になるため、明示的に求められない限り含めない。

```bash
hister search "<検索キーワード>" --format json --fields url,title,domain,added,score --limit 10
```

- 複数キーワードはスペース区切りでそのまま渡してよい（AND検索として扱われる）。
- フィールド指定検索も使える: `title:<語>`、`domain:<ドメイン>`、`text:"<フレーズ>"`、`visits:2..`など。OR は`(a|b)`、除外は`-<語>`。
- `~/.config/hister/rules.json`にエイリアスを登録済み: `gh`（`domain:github.com`）、`local`（`type:file`）。「GitHubで見た〜」のような依頼では`hister search "gh <キーワード>"`のように使うと速い。
- 結果件数を絞りたい／増やしたい場合は`--limit`を調整する。
- ユーザーが「最近の」「今日の」等の時間軸を指定した場合は、結果の`added`（Unixエポック秒）でフィルタ・ソートして絞り込む。

### 3. 結果の整形と提示

- `added`はUnixエポック秒なので、`date -d @<epoch>`（またはPythonの`datetime.fromtimestamp`）でJSTの読める日時に変換する。
- `score`が高い順（＝JSON出力の順序どおり）にランキングとして提示する。
- 各結果は「タイトル / URL / ドメイン / 閲覧日時」を1件ずつ簡潔にまとめる。生のJSONをそのまま貼り付けない。
- 該当件数が0件の場合は、キーワードを変えて再検索するか、`hister index <URL>`で手動インデックスが必要な可能性をユーザーに伝える。

### 4. ページを開く（任意）

ユーザーが特定の結果を開きたいと言った場合のみ、そのURLを`xdg-open`で開く（WSL2では`xdg-open`がWindows側の既定ブラウザに委譲するようセットアップ済み）。

```bash
xdg-open "<結果のURL>"
```

## 注意事項

- `hister search`を引数なしで実行するとTUIが起動し対話モードになるため、エージェントからは必ず検索キーワードと`--format json`を指定して非対話で実行する。
- サーバーに接続できない（`connection refused`等）場合は、`systemctl --user status hister`の出力とともにユーザーに報告し、無闇に再試行を繰り返さない。
