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

変更がない場合はその旨を伝えてスキルを終了する。

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

### 3. ブランチの確認・提案

現在のブランチを確認し：

- **main / master ブランチにいる場合**：新しいブランチの作成を提案する
  - 提案ブランチ名の形式：`<commit type>/<commit name>`
  - 例：`chore/update-argocd-versions`、`feat/add-login-feature`
  - ユーザーに確認を求め、承認されたら `git checkout -b <branch-name>` で作成・移動する
- **すでに feature ブランチにいる場合**：そのまま続行する

### 4. コミットメッセージの生成

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

生成したコミットメッセージをユーザーに提示し、承認を求める。修正が必要な場合はフィードバックを求める。

### 5. ステージングとコミット

`.env`、`credentials`、秘密鍵などの機密ファイルが含まれていないことを確認した上で：

1. 未ステージのファイルを適切にステージング（`git add` でファイルを個別に指定する。`git add -A` や `git add .` は使わない）
2. コミットを実行（HEREDOCでメッセージを渡す）：

```bash
git commit -m "$(cat <<'EOF'
<type>: <日本語の要約>

<詳細（任意）>

Co-Authored-By: Claude Sonnet 4.6 <noreply@anthropic.com>
EOF
)"
```

3. コミット後に `git status` と `git log --oneline -3` で成功を確認する

pre-commit フックが失敗した場合は、問題を修正してから新しいコミットを作成する（`--amend` は使用しない）。

### 6. プッシュの確認

コミット完了後、以下の情報をユーザーに提示してプッシュの確認を求める：

- 現在のブランチ名
- プッシュ先リモート（通常は `origin`）
- コミット内容の概要

ユーザーが承認した場合のみ `git push -u origin <branch-name>` を実行する。

拒否された場合はローカルコミットのみで完了とする。

## 注意事項

- `--no-verify` や `--force` は使用しない（ユーザーが明示的に求めた場合を除く）
- main/master への直接プッシュは警告を出す
- 機密情報を含む可能性のあるファイルは必ずユーザーに確認する