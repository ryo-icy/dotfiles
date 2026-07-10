---
name: herdr-orchestrate
description: herdr（ターミナルワークスペースマネージャ）のソケットAPI経由で、同じherdrセッション内の他のペイン・タブ・エージェント（claude/codex/copilot/agy等）を操作する。「別ペインで実行して」「別タブで動かして」「agyにレビューさせて」「他のエージェントに指示を送って」「herdrで◯◯して」といった依頼で使う。
---

herdrはターミナル上で複数のペイン・タブ・エージェントセッションを管理するツールで、`herdr`コマンドのソケットAPI（`herdr pane ...` / `herdr agent ...` / `herdr tab ...` 等）から操作できる。以下は実際に手を動かして確認した使い方と、ハマりやすい罠。

## 前提

- herdrサーバーが起動していない環境では使えない。まず `timeout 3 herdr status` で確認し、失敗したら無理に進めず素直にユーザーに伝える。
- 自分（このエージェント自身）が今どのペイン/タブ/ワークスペースにいるかは次で取得できる：
  ```bash
  herdr pane current --current
  ```
  返ってくる `workspace_id` を起点に、同じスペース内の他ペインを列挙・操作する。

## 対象の一覧・特定

```bash
herdr tab list --workspace <workspace_id>
herdr pane list --workspace <workspace_id>
```

`pane list` の各要素から `label`（ユーザーが付けた名前）、`agent`（検出されたエージェント種別: claude/codex/copilot/agy等）、`agent_status`（idle/working/blocked/unknown等）、`cwd`、`pane_id` が分かる。

**target解決の注意**:
- ペインの`label`（例:「Work」）は `herdr agent`/`herdr pane` コマンドのtargetとしてそのままでは解決できない。`pane list` の出力を `label` でjqフィルタしてpane_idを取り出す必要がある。
- agentの種別名（例: `agy`）は、同種のエージェントペインが1つしかない場合のみ一意なtargetとして使える。複数存在する場合はpane_idか、`herdr agent start <name>` で明示的に付けた一意な名前を使う。

## 別ペインでワンショットのコマンドを実行する

```bash
herdr pane run <pane_id> "<command>"
herdr pane read <pane_id> --lines <N>
```

`pane read` は生テキストをそのまま返す（後述の`agent read`と挙動が違う）。

## 新しいペインでコマンド/エージェントを起動する

```bash
herdr agent start <name> --cwd <path> [--tab <tab_id>] [--split right|down] [--no-focus] -- <argv...>
```

**罠**: `<argv...>` が一発実行で終了するプロセス（例: `agy -p "..."` のような非対話ワンショット実行）だと、プロセス終了と同時にペインごと閉じてしまい、出力を読む前に消える。結果を読みたい場合は先に `herdr pane split` で永続シェルのペインを作り、その中で `herdr pane run <pane_id> "<command>"` を実行すること。

## 既存の対話セッション（他のエージェント）に指示を送る

```bash
herdr agent send <target> "<指示文>"
herdr pane send-keys <pane_id> Return
```

`agent send` は入力欄に文字列を書き込むだけで、それ単体では送信されない。**Returnキーの送信は別操作として必須。**

**注意**: `agent send` の `<target>` はagent名（例: `agy`）でも通るが、`pane send-keys` はpane_id専用でagent名を受け付けない。名前でsendした後にReturn送信でpane_idが分からず詰まる、という事態を避けるため、**先にpane_idを特定し、`agent send`の`<target>`にもpane_idを指定して両方のコマンドをpane_idで統一する**こと。

## 完了を待つ

```bash
herdr agent wait <target> --status idle --timeout <ms>
```

**既知の罠（レース条件）**: このコマンドは「現在すでに指定ステータスなら即座に返る」実装であり、「次に指定ステータスへ遷移するまで待つ」わけではない。Return送信直後（相手がまだidle→workingへ遷移する前）に呼ぶと、遷移前のidleに一致して即座に空振り終了してしまう。**Return送信後に2〜3秒のsleepを挟んでから** `wait` を呼ぶこと。

## 結果を読む

- `herdr pane read <pane_id> --lines <N>` — 生テキストで返る。基本はこちらを使う。
- `herdr agent read <target>` — JSON包装（`.result.read.text`）されて返るので、そのままだとJSON文字列が混入する。使うなら`jq`で`.result.read.text`を取り出す。

## 対話型エージェント（agy等）特有の注意

- `claude`/`codex`/`copilot` は `herdr integration status` で確認できる公式フック連携があり、状態報告（idle/working等）が正確。`agy`（Antigravity CLI）など公式連携がないエージェントはヒューリスティック検出のみで、状態遷移の粒度が粗いことがある。
- 対話モードのエージェントは、許可プロンプトなしで動くフラグ（例: `--dangerously-skip-permissions`, `--sandbox`）付きで起動していない限り、シェルコマンド実行やワークスペース外ファイル読み取りのたびに許可プロンプトを出し、そこで自動化が止まる。
  - ヘッドレスに指示を送って自動で完了させたい場合は、専用ペインを許可プロンプトなしのフラグ付きで起動する。
  - サンドボックスフラグを付けても、起動時のcwd外のファイル読み取りには許可プロンプトが出ることがある。読ませたい一時ファイルは対象エージェントの`cwd`（`pane list`/`pane get`の`.cwd`）配下に置くと避けられる。
  - 許可プロンプトで止まっていないかの簡易な目印は、読み取ったテキストに `"esc to cancel"` が含まれるかどうか。含まれていたらそのターンは完了していないとみなし、`herdr pane send-keys <pane_id> Escape` でキャンセルしてセッションを止まったままにしない。

## その他

- `herdr integration status` — claude/codex/copilot等の公式フック連携の導入状況を確認できる。
- 状況確認系コマンド（`herdr status`, `herdr agent get`, `herdr pane list` 等）は、herdrサーバーが落ちている環境で長くハングしないよう `timeout <秒> herdr ...` でラップするとよい。
