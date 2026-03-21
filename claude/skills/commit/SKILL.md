---
name: commit
description: gitリポジトリの変更をまとめてコミット・プッシュする。ブランチ作成（<type>/<name>形式）、日本語Conventional Commitsメッセージの生成、ユーザー確認後のプッシュを行う。
disable-model-invocation: true
---

gitリポジトリの変更内容を分析し、日本語のConventional Commitsメッセージを生成してコミット・プッシュを行う。

## 手順

### 1. 変更内容の確認

以下を並列で実行して現状を把握する：

- `git status`（未追跡ファイルを確認。`-uall` フラグは使用しない）
- `git diff HEAD`（ステージ済み・未ステージ両方の差分）
- `git log --oneline -10`（直近のコミット履歴）
- `git branch --show-current`（現在のブランチ名）
- `git remote -v`（リモートの確認）

変更がない場合はその旨を伝えてスキルを終了する。

ブランチ名が確定したら、リモートブランチの存在を確認する：

- `git ls-remote --heads origin <branch-name>`（リモートブランチの存在確認）
- リモートブランチが存在する場合は `git log origin/<branch-name>..HEAD --oneline` でローカルにある未プッシュのコミット数も確認する

### 2. コミットタイプと内容の分析

変更内容を分析して以下を決定する：

**コミットタイプ（commit type）：**

- `feat`：新機能の追加
- `fix`：バグ修正
- `chore`：ビルド・ツール・設定・依存関係の更新など（機能に直接関係しないもの）
- `docs`：ドキュメントのみの変更
- `style`：コードの動作に影響しない変更（フォーマット等）
- `refactor`：バグ修正でも機能追加でもないコード変更
- `test`：テストの追加・修正
- `ci`：CI/CD設定の変更

**commit name（ブランチ名の一部）：**

- 変更内容を端的に表す英語の kebab-case 名前
- 例：`update-argocd-versions`、`add-login-feature`、`fix-null-pointer`

### 3. 実行計画の生成とまとめて確認

以下をすべて分析し、**1回の確認**でユーザーに提示する：

**ブランチ：**

- **main / master ブランチにいる場合**：新しいブランチの作成を提案する
  - 提案ブランチ名の形式：`<commit type>/<commit name>`
  - 例：`chore/update-argocd-versions`、`feat/add-login-feature`
- **すでに feature ブランチにいる場合**：そのまま続行する（ブランチ作成なし）

**コミットメッセージ：**

以下の形式で日本語のコミットメッセージを生成する：

```
<type>: <変更内容の要約（日本語・50文字以内）>

<詳細説明（複数の変更がある場合）>
- 変更点1
- 変更点2

Co-Authored-By: Claude Sonnet 4.6 <noreply@anthropic.com>
```

**例：**

```
chore: ArgoCDのバージョンを最新版に更新

- argocd を v2.9.0 から v2.10.0 に更新
- argocd-image-updater を v0.12.0 から v0.13.0 に更新

Co-Authored-By: Claude Sonnet 4.6 <noreply@anthropic.com>
```

**提示フォーマット（すべてをまとめて1回で確認）：**

リモートブランチが**存在しない**場合（新規プッシュ）：

```
以下の内容で進めます。よろしいですか？

ブランチ: <現在のブランチ名> → <新規ブランチ名（作成する場合）、またはそのまま>
コミット:
  <生成したコミットメッセージ全文>
プッシュ: git push -u origin <ブランチ名>（新規）
```

リモートブランチが**すでに存在する**場合（PR 対応などの追加プッシュ）：

```
以下の内容で進めます。よろしいですか？

ブランチ: <ブランチ名>（リモートに既存・未プッシュ <N> コミット）
コミット:
  <生成したコミットメッセージ全文>
プッシュ: git push origin <ブランチ名>（追加プッシュ）
```

ユーザーが承認した場合は手順4へ進む。修正が必要な場合はフィードバックを受けて再提示する。

### 4. ステージングとコミット・プッシュ

`.env`、`credentials`、秘密鍵などの機密ファイルが含まれていないことを確認した上で：

1. 必要に応じて `git checkout -b <branch-name>` でブランチを作成
2. 未ステージのファイルを適切にステージング（`git add` でファイルを個別に指定する。`git add -A` や `git add .` は使わない）
3. コミットを実行（HEREDOCでメッセージを渡す）：

```bash
git commit -m "$(cat <<'EOF'
<type>: <日本語の要約>

<詳細（任意）>

Co-Authored-By: Claude Sonnet 4.6 <noreply@anthropic.com>
EOF
)"
```

4. コミット後に `git status` と `git log --oneline -3` で成功を確認する
5. プッシュを実行する：
   - リモートブランチが存在しない場合：`git push -u origin <branch-name>`
   - リモートブランチがすでに存在する場合：`git push origin <branch-name>`

pre-commit フックが失敗した場合は、問題を修正してから新しいコミットを作成する（`--amend` は使用しない）。
プッシュをスキップしたい場合はユーザーが手順3の確認時に申告する。

## 注意事項

- `--no-verify` や `--force` は使用しない（ユーザーが明示的に求めた場合を除く）
- main/master への直接プッシュは警告を出す
- 機密情報を含む可能性のあるファイルは必ずユーザーに確認する