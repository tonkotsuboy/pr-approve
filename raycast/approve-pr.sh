#!/bin/bash

# Raycast Script Command
# @raycast.schemaVersion 1
# @raycast.title Approve PR
# @raycast.mode fullOutput
# @raycast.packageName GitHub
# @raycast.icon ✅
# @raycast.argument1 { "type": "text", "placeholder": "PR URL または番号（複数はスペース区切り）" }
#
# Optional:
# @raycast.description 指定した GitHub PR を pre-flight チェックし、確認ダイアログを出して approve する
# @raycast.author tonkotsuboy

# Raycast が壊れたロケール（LC_ALL=en-JP-u-ca-...）を渡してきて bash が警告を出すので明示的に上書き
export LC_ALL=en_US.UTF-8 LANG=en_US.UTF-8

# Raycast は最小 PATH でスクリプトを起動することがあるので、gh / jq / pr-approve の場所を明示的に通す
export PATH="/opt/homebrew/bin:/usr/local/bin:$HOME/.local/bin:$PATH"

# --gui を付けて確認を macOS ダイアログにする。$1 は引用しない（スペース区切りの複数 PR を許可）
exec pr-approve --gui $1
