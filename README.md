# pr-approve

> Approve GitHub PRs from your terminal or Raycast — with pre-flight safety checks and a final confirmation.

**English** | [日本語](README.ja.md)

`pr-approve` wraps the [GitHub CLI (`gh`)](https://cli.github.com/) to **add yourself as a reviewer (if needed) and approve** a PR in one step — from your terminal or Raycast.

## Motivation

- Some PRs don't really need a close review, but they still can't be merged until someone approves them.
- Opening the browser every time, assigning yourself as a reviewer if you aren't already, and clicking the **Approve** button breaks your train of thought and stops your hands — a waste of time and attention.
- I wanted something that just does the approve, straight from the CLI or Raycast.

## Safety first

Approve is a hard-to-undo, outward-facing action, so safety comes first:

- **Pre-flight checks** mechanically exclude PRs that shouldn't be approved.
- A **summary + confirmation** is shown right before approving (terminal `y/n`, or a native macOS dialog in non-interactive environments like Raycast).
- It never judges the PR's content — it just executes the PRs **you** decided are OK to approve.

## Requirements

- [GitHub CLI (`gh`)](https://cli.github.com/), authenticated (`gh auth login`). Approvals and reviewer requests are made **as the authenticated `gh` user**.
- [`jq`](https://jqlang.github.io/jq/)
- macOS — only for the `--gui` confirmation dialog (`osascript`). Without `--gui`, macOS isn't required.

## Installation

### Homebrew (recommended)

```bash
brew install tonkotsuboy/tap/pr-approve
```

This also installs the `gh` and `jq` dependencies.

### Manual

```bash
curl -fsSL https://raw.githubusercontent.com/tonkotsuboy/pr-approve/main/pr-approve -o ~/.local/bin/pr-approve
chmod +x ~/.local/bin/pr-approve
```

## Usage

```bash
pr-approve <PR_URL>                 # one PR
pr-approve <URL1> <URL2> ...        # multiple at once
pr-approve 123 124                  # bare numbers work when run inside the repo
pr-approve --gui <URL>              # confirm via a macOS dialog (for Raycast)
```

## How it works

### Pre-flight checks

A PR is skipped (with a reason) if any of these hold:

| Condition | Why |
| :--- | :--- |
| Already merged / closed | Can't be approved |
| You are the author | GitHub doesn't let you approve your own PR |
| You already approved it | A second approval is meaningless |
| CI failing / pending | Maybe not ready to approve yet |
| Changes requested by others | Same as above |

### Flow

1. For a PR that passes pre-flight, add yourself as a reviewer if you aren't requested yet
   (if GitHub rejects requesting a review from yourself, it stops and asks).
2. Show a summary (number, title, author, files changed, CI status, reviewer state).
3. On confirmation (`y/n` or a macOS dialog), run `gh pr review --approve` (no comment).

## Language

Messages are shown in **English by default**, or in **Japanese** when your locale is `ja*` (e.g. `LANG=ja_JP.UTF-8`). Force a specific language with `PR_APPROVE_LANG=en` or `PR_APPROVE_LANG=ja`.

## Raycast

Register [`raycast/approve-pr.sh`](raycast/approve-pr.sh) as a Raycast Script Command to approve a PR from Raycast by passing its URL. The confirmation appears as a macOS dialog, so it works even though Raycast is non-interactive.

1. Put `raycast/approve-pr.sh` in a directory (e.g. `~/raycast-scripts`).
2. Raycast → Settings → Extensions → Script Commands → **Add Directories**, and select that directory.
3. Search **Approve PR** in Raycast → enter the PR URL → run.

> Raycast may launch scripts with a minimal `PATH`, so `approve-pr.sh` adds `gh` / `jq` / `pr-approve` locations to `PATH`. Adjust for your environment (e.g. Homebrew paths). For Japanese messages from Raycast, uncomment `export PR_APPROVE_LANG=ja` inside the script.

## Design note

There are two kinds of "anomaly detection". **Known anomalies** (already merged, you're the author, CI failing, …) can be ruled out mechanically by the pre-flight checks. **Unknown anomalies** (a `[DO NOT MERGE]` in the title, a "please wait" in the description — things you never coded a rule for) can't be caught by a machine. That's exactly why a **human confirmation step right before approving** is kept as the last line of defense.

## Troubleshooting

### Raycast says "gh is not authenticated"

**Cause**: Raycast doesn't launch scripts as a login shell, so if you authenticate `gh` via a `GH_TOKEN` environment variable exported in `~/.zshrc`, that token isn't available and `gh` appears unauthenticated.

**Check**: if `gh auth status` ends with `(GH_TOKEN)`, you rely on the env var; `(keyring)` or `(oauth_token)` means it's stored in gh's own store (which Raycast can use).

**Fix**: persist credentials to gh's store (the macOS keychain).

```bash
# Option 1: store your current GH_TOKEN into gh's store (no browser)
TOKEN="$GH_TOKEN"
( unset GH_TOKEN GITHUB_TOKEN; printf '%s' "$TOKEN" | gh auth login --with-token )

# Option 2: log in via browser
unset GH_TOKEN GITHUB_TOKEN      # gh auth login refuses while this is set
gh auth login
```

After this, `gh auth status` should show `(keyring)` and Raycast will authenticate.
(In a terminal where `GH_TOKEN` is still set, the env var keeps taking precedence, so terminal behavior is unchanged.)

### `setlocale: LC_ALL: cannot change locale` warning

Raycast passes a non-standard locale (e.g. `en-JP-u-ca-gregory-...`). `raycast/approve-pr.sh` overrides `LC_ALL` / `LANG` to suppress the warning. It's harmless.

## License

[MIT](LICENSE)
