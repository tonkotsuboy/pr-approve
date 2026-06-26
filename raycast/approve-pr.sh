#!/bin/bash

# Raycast Script Command
# @raycast.schemaVersion 1
# @raycast.title Approve PR
# @raycast.mode fullOutput
# @raycast.packageName GitHub
# @raycast.icon ✅
# @raycast.argument1 { "type": "text", "placeholder": "PR URL or number (space-separated for multiple)" }
#
# Optional:
# @raycast.description Approve a GitHub PR after pre-flight checks, with a confirmation dialog
# @raycast.author tonkotsuboy

# Raycast passes a non-standard locale (e.g. LC_ALL=en-JP-u-ca-...) that bash warns about; override it.
export LC_ALL=en_US.UTF-8 LANG=en_US.UTF-8

# Messages default to English. For Japanese messages, uncomment the next line:
# 日本語メッセージにしたい場合は次の行を有効化:
# export PR_APPROVE_LANG=ja

# Raycast は最小 PATH でスクリプトを起動することがあるので、gh / jq / pr-approve の場所を明示的に通す
export PATH="/opt/homebrew/bin:/usr/local/bin:$HOME/.local/bin:$PATH"

# --gui を付けて確認を macOS ダイアログにする。$1 は引用しない（スペース区切りの複数 PR を許可）
exec pr-approve --gui $1
