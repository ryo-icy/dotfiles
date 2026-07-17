---
name: hister-search
description: Histerで索引化した自分のブラウジング履歴・保存ページをローカルの`hister search`コマンドで検索する。キーワードから関連ページのタイトル・URL・閲覧日時を提示し、必要ならブラウザで開く。
disable-model-invocation: true
---

Histerサーバー（arcana上のDocker stackとして稼働。旧・home-managerのsystemd `--user`サービスから移行済み）に対して`hister search`コマンドで検索を行い、結果を整形して提示する。

## 前提

- Histerサーバーはarcana（Komodoで管理するDockerホスト、tailnetのサブネットルータ経由でのみ到達可能）上でコンテナとして稼働している。ローカルのsystemd `--user`サービスとしてはもう起動していない（`home/hister.nix`は撤去済み）。
- サーバーURLは`http://10.0.1.240:4433`固定（値を変える場合はここ1箇所を直せばよい）。以下のコマンド例はすべて`$HISTER_URL`を参照するので、実行前に一度設定しておく:

  ```bash
  export HISTER_URL=http://10.0.1.240:4433
  ```

  ローカルの既定（127.0.0.1）はもう疎通しないため、必ず`--server-url "$HISTER_URL"`を明示する。
- access_tokenは設定していない（tailnet経由でしか到達できないことをアクセス制御としている）ので`--token`は不要。
- hister MCPサーバー（`$HISTER_URL/mcp`）は、サーバー移行に伴い**再登録が必要**（旧URL`127.0.0.1:4433/mcp`で登録されていた場合は無効）。MCPツール（`search`/`get_preview`/`get_history`）が使えるエージェントではそちらを優先し、このスキルのシェルコマンドは使わない。MCPが未登録のエージェントでのみ以下の手順に従う。

## 手順

### 1. 検索実行（疎通確認を兼ねる）

histerのHTTP APIにルートパス`/`向けのヘルスチェック用エンドポイントがあるかは未確認のため、検索と切り離した事前疎通確認は行わない。検索コマンドをそのまま実行し、その終了コード・エラー出力（`connection refused`/タイムアウト等）で疎通を判断する。

ユーザーの依頼からキーワードを抽出し、JSON形式・必要最小限のフィールドで検索する。`favicon`や`html`、`text`フィールドは巨大なペイロード（faviconはbase64画像）になるため、明示的に求められない限り含めない。

```bash
hister search "<検索キーワード>" --server-url "$HISTER_URL" --format json --fields url,title,domain,added,score --limit 10
```

接続エラーが返った場合、原因はローカル側ではなくarcanaホスト（Komodo/Dockerコンテナ）側にある可能性が高い。無闇に再試行を繰り返さず、arcanaのKomodo UIやコンテナログを確認するようユーザーに報告する。

- 複数キーワードはスペース区切りでそのまま渡してよい（AND検索として扱われる）。
- フィールド指定検索も使える: `title:<語>`、`domain:<ドメイン>`、`text:"<フレーズ>"`、`visits:2..`など。OR は`(a|b)`、除外は`-<語>`。
- 旧サーバーでは`gh`（`domain:github.com`）、`local`（`type:file`）等のエイリアスをrules.jsonに登録していたが、これはサーバー側のデータ（arcana移行時にデータは引き継いでいない）なので**新サーバーには存在しない**。エイリアス検索を使いたい場合はarcanaのhisterコンテナ側で`rules.json`を再設定するようユーザーに案内する。
- 結果件数を絞りたい／増やしたい場合は`--limit`を調整する。
- ユーザーが「最近の」「今日の」等の時間軸を指定した場合は、結果の`added`（Unixエポック秒）でフィルタ・ソートして絞り込む。

### 2. 結果の整形と提示

- `added`はUnixエポック秒なので、`date -d @<epoch>`（またはPythonの`datetime.fromtimestamp`）でJSTの読める日時に変換する。
- `score`が高い順（＝JSON出力の順序どおり）にランキングとして提示する。
- 各結果は「タイトル / URL / ドメイン / 閲覧日時」を1件ずつ簡潔にまとめる。生のJSONをそのまま貼り付けない。
- 該当件数が0件の場合は、キーワードを変えて再検索するか、`hister index <URL> --server-url "$HISTER_URL"`で手動インデックスが必要な可能性をユーザーに伝える。

### 3. ページを開く（任意）

ユーザーが特定の結果を開きたいと言った場合のみ、そのURLを`xdg-open`で開く（WSL2では`xdg-open`がWindows側の既定ブラウザに委譲するようセットアップ済み）。

```bash
xdg-open "<結果のURL>"
```

## 注意事項

- `hister search`を引数なしで実行するとTUIが起動し対話モードになるため、エージェントからは必ず検索キーワードと`--format json`を指定して非対話で実行する。
- サーバーに接続できない（`connection refused`等）場合は、arcana（Komodo）側のコンテナ状態を確認するようユーザーに報告し、無闇に再試行を繰り返さない。ローカルのsystemdサービスはもう存在しないため、`systemctl --user`での復旧は不可。
