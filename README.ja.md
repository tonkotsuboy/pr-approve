# pr-approve

> GitHub の Pull Request を、ターミナルや Raycast から、安全チェック（pre-flight）と確認のうえで approve する CLI。

[English](README.md) | **日本語**

`pr-approve` は [GitHub CLI (`gh`)](https://cli.github.com/) をラップして、**必要ならレビュワーに自分を追加 → approve** までを、ターミナルや Raycast から一発で行う。

## モチベーション

- 内容を細かく見る必要はないが、approve しないとマージできない PR がある。
- いちいちブラウザを開き、自分がアサインされていなければアサインし、approve ボタンを押す——その都度、作業の思考が止まり、手が止まり、時間と関心が削られる。
- CLI や Raycast から approve するだけ、の機能がほしかった。

## 安全性ファースト

approve は取り消しにくい外向きの操作なので、安全性を最優先している:

- **pre-flight チェック**で「approve すべきでない PR」を機械的に除外する。
- approve の直前に**サマリを出して確認**を取る（ターミナルは `y/n`、Raycast 等の非対話環境では macOS のダイアログ）。
- PR の中身の良し悪しは判断しない。**あなたが「承認 OK」と判断した PR を実行するだけ**の薄い実行係。

## 必要なもの

- [GitHub CLI (`gh`)](https://cli.github.com/) — 認証済みであること（`gh auth login`）。approve / レビュワー追加は `gh` の**認証ユーザー本人**として行われる。
- [`jq`](https://jqlang.github.io/jq/)
- macOS — `--gui` の確認ダイアログ（`osascript`）にのみ必要。`--gui` を使わなければ macOS でなくても動く。

## インストール

### Homebrew（推奨）

```bash
brew install tonkotsuboy/tap/pr-approve
```

`gh` / `jq` も依存として同時にインストールされる。

### 手動

```bash
curl -fsSL https://raw.githubusercontent.com/tonkotsuboy/pr-approve/main/pr-approve -o ~/.local/bin/pr-approve
chmod +x ~/.local/bin/pr-approve
```

## 使い方

```bash
pr-approve <PR_URL>                 # 1 件
pr-approve <URL1> <URL2> ...        # 複数まとめて
pr-approve 123 124                  # リポジトリ内で実行するなら番号だけでも可
pr-approve --gui <URL>              # 確認を macOS ダイアログで（Raycast 用）
```

## 動作

### pre-flight チェック

次のいずれかに該当する PR は、approve せずスキップして理由を表示する:

| 条件 | 理由 |
| :--- | :--- |
| 既にマージ / クローズ済み | approve できない |
| 自分が作者 | GitHub は自分の PR を approve できない |
| 既に自分が approve 済み | 二重 approve は無意味 |
| CI が失敗 / pending | まだ承認すべきでない可能性がある |
| 他者が changes を要求中 | 同上 |

### approve までの流れ

1. pre-flight を通過した PR について、自分がレビュワーに未指名なら自分を追加する
   （GitHub が「自分自身へのレビュー依頼」を弾いた場合は停止して確認する）。
2. PR のサマリ（番号・タイトル・作者・変更ファイル数・CI 状況・reviewer 状態）を表示。
3. 確認（`y/n` または macOS ダイアログ）で OK なら `gh pr review --approve` を実行（コメントなし）。

## 言語

メッセージは**既定で英語**。ロケールが `ja*`（例: `LANG=ja_JP.UTF-8`）のときは**日本語**になる。`PR_APPROVE_LANG=en` / `PR_APPROVE_LANG=ja` で明示指定も可能。

## Raycast から使う

このリポジトリの [`raycast/approve-pr.sh`](raycast/approve-pr.sh) を Raycast の Script Command として登録すると、Raycast から PR URL を渡して approve できる。確認は macOS ダイアログで出るので、非対話でも安全。

1. `raycast/approve-pr.sh` を任意のディレクトリ（例: `~/raycast-scripts`）に置く。
2. Raycast → Settings → Extensions → Script Commands → **Add Directories** でそのディレクトリを追加。
3. Raycast 検索で **Approve PR** → PR URL を入力して実行。

> Raycast は最小 PATH でスクリプトを起動することがあるため、`approve-pr.sh` 内で `gh` / `jq` / `pr-approve` の場所を PATH に通している。環境（Homebrew のパス等）に合わせて調整のこと。Raycast から日本語メッセージにしたい場合は、スクリプト内の `export PR_APPROVE_LANG=ja` をコメント解除する。

## 設計メモ

「異常検知」には2種類ある。**既知の異常**（マージ済み・自分が作者・CI 失敗 など、事前にルール化できるもの）は pre-flight で機械的に弾ける。一方、**未知の異常**（タイトルに `[DO NOT MERGE]`、説明に「レビュー待って」等の、ルール化していない “なんか変”）は機械では拾えない。だからこそ approve の直前に**人間がサマリを見て確認する**ステップを最後の砦として残している。

## トラブルシューティング

### Raycast で「gh が認証されていません」と出る

**原因**: Raycast はスクリプトをログインシェルとして起動しないため、`~/.zshrc` などで `export GH_TOKEN=...` して gh を認証している場合、その環境変数が渡らず gh が未認証になる。

**確認**: `gh auth status` の末尾が `(GH_TOKEN)` なら環境変数依存、`(keyring)` や `(oauth_token)` なら gh のストアに保存済み（＝Raycast でも使える）。

**解決**: gh の認証ストア（macOS なら keychain）に認証情報を永続化する。

```bash
# 方法1: いま使っている GH_TOKEN をそのままストアに保存（ブラウザ不要）
TOKEN="$GH_TOKEN"
( unset GH_TOKEN GITHUB_TOKEN; printf '%s' "$TOKEN" | gh auth login --with-token )

# 方法2: ブラウザでログインし直す
unset GH_TOKEN GITHUB_TOKEN      # set されていると gh auth login が拒否するため
gh auth login
```

保存後に `gh auth status` が `(keyring)` 等になっていれば、Raycast からも認証が通る。
（`GH_TOKEN` が set されているターミナルでは引き続き環境変数が優先されるので、ターミナル側の挙動は変わらない。）

### `setlocale: LC_ALL: cannot change locale` という警告が出る

Raycast が非標準のロケール（例: `en-JP-u-ca-gregory-...`）を渡してくるのが原因。`raycast/approve-pr.sh` 内で `LC_ALL` / `LANG` を上書きして抑止している。実害はない。

## ライセンス

[MIT](LICENSE)
