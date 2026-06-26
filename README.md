# pr-approve

> GitHub の Pull Request を、安全チェック（pre-flight）と確認のうえでサクッと approve する CLI。

「ただ approve すればいいだけの PR」のために、毎回ブラウザを開いて画面遷移して承認ボタンを押すのは面倒。`pr-approve` は [GitHub CLI (`gh`)](https://cli.github.com/) をラップして、**必要ならレビュワーに自分を追加 → approve** までを一発で行う。

approve は取り消しにくい外向きの操作なので、安全性を最優先している:

- **pre-flight チェック**で「approve すべきでない PR」を機械的に除外する
- approve の直前に**サマリを出して確認**を取る（ターミナルは `y/n`、Raycast 等の非対話環境では macOS のダイアログ）
- PR の中身の良し悪しは判断しない。**あなたが「承認 OK」と判断した PR を実行するだけ**の薄い実行係

## 必要なもの

- [GitHub CLI (`gh`)](https://cli.github.com/) — 認証済みであること（`gh auth login`）。approve / レビュワー追加は `gh` の**認証ユーザー本人**として行われる
- [`jq`](https://jqlang.github.io/jq/)
- macOS — `--gui` の確認ダイアログは `osascript` を使う（`--gui` を使わなければ macOS でなくても動く）

## インストール

```bash
# PATH の通ったディレクトリに置いて実行権限を付ける
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
   （GitHub が「自分自身へのレビュー依頼」を弾いた場合は停止して確認する）
2. PR のサマリ（番号・タイトル・作者・変更ファイル数・CI 状況・reviewer 状態）を表示
3. 確認（`y/n` または macOS ダイアログ）で OK なら `gh pr review --approve` を実行（コメントなし）

## Raycast から使う

このリポジトリの [`raycast/approve-pr.sh`](raycast/approve-pr.sh) を Raycast の Script Command として登録すると、Raycast から PR URL を渡して approve できる。確認は macOS ダイアログで出るので、非対話でも安全。

1. `raycast/approve-pr.sh` を任意のディレクトリ（例: `~/raycast-scripts`）に置く
2. Raycast → Settings → Extensions → Script Commands → **Add Directories** でそのディレクトリを追加
3. Raycast 検索で **Approve PR** → PR URL を入力して実行

> Raycast は最小 PATH でスクリプトを起動することがあるため、`approve-pr.sh` 内で `gh` / `jq` / `pr-approve` の場所を PATH に通している。環境（Homebrew のパス等）に合わせて調整のこと。

## 設計メモ

「異常検知」には2種類ある。**既知の異常**（マージ済み・自分が作者・CI 失敗 など、事前にルール化できるもの）は pre-flight で機械的に弾ける。一方、**未知の異常**（タイトルに `[DO NOT MERGE]`、説明に「レビュー待って」等の、ルール化していない “なんか変”）は機械では拾えない。だからこそ approve の直前に**人間がサマリを見て確認する**ステップを最後の砦として残している。

## ライセンス

[MIT](LICENSE)
