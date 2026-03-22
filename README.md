# Automated Backporting POC

Proof-of-concept for automated backporting of merged pull requests to release branches using GitHub Actions and [korthout/backport-action](https://github.com/korthout/backport-action).

## How It Works

1. A PR is merged into `main`.
2. If the PR has one or more `target:<branch>` labels (e.g., `target:release/1.0`), the backport workflow triggers.
3. For each target label, the action:
   - Cherry-picks the merged commits onto a new branch from the target release branch.
   - Opens a backport PR against the target release branch.
   - If the cherry-pick is clean → the backport PR is **auto-merged** (squash).
   - If there's a conflict → a **draft PR** is created with the conflict committed, and a comment is posted on the original PR explaining manual resolution is needed.

## Labels

| Label | Target Branch |
|---|---|
| `target:release/1.0` | `release/1.0` |
| `target:release/2.0` | `release/2.0` |
| `target:release/3.0` | `release/3.0` |

You can target multiple branches by adding multiple labels to a single PR.

## Setup

### Prerequisites

- [GitHub CLI](https://cli.github.com/) (`gh`) installed and authenticated
- Git remote `origin` pointing to this repo on GitHub

### Steps

```bash
# 1. Clone and push the initial commit to GitHub
git init
git add .
git commit -m "Initial commit"
gh repo create poc-automated-backporting --public --source=. --push

# 2. Run the setup script (creates branches, labels, enables auto-merge)
bash setup.sh
```

The setup script will:
- Create release branches (`release/1.0`, `release/2.0`, `release/3.0`) with diverged history
- Create the `target:release/*` labels on GitHub
- Enable auto-merge on the repository

### Manual Step

Verify that **"Allow auto-merge"** is enabled in **Settings → General → Pull Requests**. The setup script attempts to enable it, but it requires admin access.

## Testing

### Test A: Clean Backport

1. Create a branch from `main`, add a new file (e.g., `feature.txt`).
2. Open a PR to `main` and add the label `target:release/3.0`.
3. Merge the PR.
4. Expected: a backport PR is created against `release/3.0` and auto-merged.

### Test B: Conflicting Backport

1. Create a branch from `main`, modify the `divide` function in `app.py`.
2. Open a PR to `main` and add the label `target:release/1.0`.
3. Merge the PR.
4. Expected: a **draft** backport PR is created against `release/1.0` with conflicts. The original PR gets a comment.

### Test C: Multi-Target Backport

1. Create a branch from `main`, add a new file.
2. Open a PR to `main` and add labels `target:release/2.0` and `target:release/3.0`.
3. Merge the PR.
4. Expected: two backport PRs, one for each target branch.

## Workflow Configuration

The workflow is defined in [`.github/workflows/backport.yml`](.github/workflows/backport.yml) with these key settings:

| Input | Value | Purpose |
|---|---|---|
| `label_pattern` | `^target:([^ ]+)$` | Match `target:<branch>` labels |
| `auto_merge_enabled` | `true` | Auto-merge clean backports |
| `auto_merge_method` | `squash` | Squash-merge into release branch |
| `conflict_resolution` | `draft_commit_conflicts` | Draft PR with conflicts on failure |
| `merge_commits` | `skip` | Skip merge commits during cherry-pick |

## Notes

- The workflow uses `pull_request_target` (not `pull_request`) so `GITHUB_TOKEN` has write access even for PRs from forks.
- The default `GITHUB_TOKEN` cannot trigger downstream workflows (e.g., CI on backport PRs). For production, use a GitHub App installation token.
- The action cherry-picks with the `-x` flag, adding a reference to the original commit for traceability.
