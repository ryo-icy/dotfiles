---
name: hunk-review
description: hunk（レビュー特化のdiffビューア）のライブセッションAPI（`hunk session ...`）経由で、コードレビューコメントの読み書きを行う。(A) diffをレビューして所見をhunk上に書き込みたいとき。(B) ユーザーがhunk上に残したレビューコメント・指摘を読んで、それに基づき修正するとき。トリガー例:「hunkにレビューして」「hunkに指摘書いて」「hunkのコメント読んで」「hunkのコメント直して」「hunkの指摘に対応して」「hunk確認して直して」「レビュー指摘を反映して」。`hunk diff --watch` のライブセッションが存在する状態でのレビュー記入・コメント追従修正で使う。
---

hunkは`hunk diff --watch`等で開いている間、ローカルデーモン上に「ライブセッション」を持ち、外部から`hunk session ...`サブコマンドで読み書きできる。これによりレビューコメントのやり取りをTUI操作なしでコマンドラインから行える。以下は実際に手を動かして確認した使い方と罠。

## 前提

- hunkのライブセッションが存在するか確認する: `hunk session list`。対象repoのセッションが見当たらなければ、無理に進めずユーザーに「`hunk diff --watch`を開いてください」と伝える。
- 以後のコマンドはすべて`--repo <path>`（対象リポジトリのルート）で対象セッションを指定できる。**同一リポジトリに対して複数のライブセッションが同時に開いていると`--repo`だけでは曖昧**になるので、その場合は`hunk session list`で表示される`session-id`を明示的に使う。

## (A) AIがレビュー所見をhunkに書き込む

**禁止事項**: 「良い実装です」「ここは問題ありません」のような賞賛・肯定コメントは書かない。hunkのコメントはAIが後で読んで対応するための指摘専用チャネルであり、対応不要なコメントは次にこのスキルが動いたときのノイズにしかならない。書き込むのは「指摘（バグ・問題点）」または「提案（改善案）」に限定し、`summary`は指摘/提案の内容が一目で分かる短文にする。

**専用エージェント/スキルの流用**: 自前でdiffを読んで所見をひねり出す前に、まず`/code-review`スキル（Claude Code組み込み、`ReportFindings`ツールで所見を返す）を実効レベル（low/medium/high/xhigh/max）を指定して呼び出す。このスキルは元々「賞賛なし・確認済みの指摘のみ」を返す設計なので、ここでの禁止事項と方針が一致する。返ってきた各findingを次のようにhunkコメントへ変換して`comment apply`に流し込む:

- `file` → `filePath`
- `line` → `newLine`（findingが削除行を指す場合のみ`oldLine`）
- `summary` → `summary`
- `failure_scenario`（と`verdict`があれば付記） → `rationale`
- `author` → `"claude(review)"` 固定、または担当観点ごとに区別

`/code-review`が対象にしない観点（例:運用手順・ドキュメント整合性など）を追加で見る場合のみ、自前の所見を同じ形式で追記する。その場合も上記の禁止事項は変わらない。

1件ずつ書く場合:

```bash
hunk session comment add --repo <path> \
  --file <diffに表示されているファイルパス> \
  --new-line <n>            # 追加/変更後の行番号。削除側を指したいときは --old-line
  --summary "<短い要約>" \
  --rationale "<理由の詳細>" \
  --author "claude(review)"  # 発言者ラベル。誰の所見か区別するため必ず付ける
```

複数件まとめて投入する場合は`comment apply`にJSONを流し込む:

```bash
hunk session comment apply --repo <path> --stdin <<'EOF'
{
  "comments": [
    {
      "filePath": "deploy.sh",
      "newLine": 4,
      "summary": "APIキーがハードコードされています",
      "rationale": "環境変数や1Password参照に置き換えるべき",
      "author": "claude(review)"
    }
  ]
}
EOF
```

`filePath`と`summary`に加えて、`hunk`/`hunkNumber`/`oldLine`/`newLine`のいずれか1つが必須。

**罠**: 書き込む前に`hunk session comment list --repo <path>`で既存コメントを確認し、同じ指摘を重複投稿しない。

**マルチエージェントレビュー**: herdrで別ペインに他のエージェント（[[herdr-orchestrate]]参照）を起動し、それぞれに担当観点（セキュリティ/パフォーマンス/運用堅牢性等）を割り振って同じセッションに`comment add`させると、1つのdiff画面に複数視点の指摘が集約される。`--author`を役割ごとに変えて発言者を区別すること。

## (B) ユーザーのコメントを読んで修正する

hunkは**push通知を持たない（pull型）**。ユーザーが書いたコメントは、こちらから明示的に問い合わせない限り気づけない。このスキルがトリガーされたら、まず以下でユーザー分のコメントだけを取得する:

```bash
hunk session comment list --repo <path> --type user
```

`--json`を付けると`noteId` / `filePath` / `newRange`（[start,end]） / `body` / `author` / `createdAt`が構造化データで取れる。diff全体の文脈も一緒に欲しい場合は:

```bash
hunk session review --repo <path> --include-patch --include-notes
```

手順:

1. `--type user`で拾ったコメントごとに、`filePath`と`newRange`を手がかりに実ファイルを読み、該当箇所を特定する（hunk側は行番号を教えてくれるだけで、コードの意味は自分で読む必要がある）。
2. コメントの`body`の指摘に沿って実際にファイルを修正する。
3. 対応が終わったコメントは`comment rm`で消す。消さないと同じ指摘が残り続け、次にこのスキルが起動したときにまた反応してしまう。

```bash
hunk session comment rm --repo <path> <comment-id>   # comment-id は noteId の値
```

**罠**: `comment clear --include-user --yes`は人間のコメントも含めて一括削除してしまう破壊的操作。個別に対応が終わったものだけを`comment rm`で消すのが基本で、未読・未対応のユーザーコメントを誤って消さないよう`clear`は使わない。

## ナビゲーション（TUI側の表示位置を動かしたいとき）

```bash
hunk session navigate --repo <path> --file <path> --new-line <n>   # 特定行にジャンプ
hunk session navigate --repo <path> --next-comment                  # 次のコメント付きhunkへ
```

ユーザーが今どこを見ているか把握したいときは`hunk session context --repo <path>`。

## その他

- `--agent-context <path>`（`hunk diff`起動時のJSONサイドカー）は、hunk sessionのライブコメントとは別物。AI自身が行った変更の設計意図を最初から表示しておきたいときに使う静的な仕組みで、`hunk session comment add`のような後からの書き込みではない。混同しない。
- サイドカーJSONをリポジトリ内に置くと、それ自体が未追跡ファイルとしてdiffに紛れ込む。`.gitignore`するかリポジトリ外に置く。
