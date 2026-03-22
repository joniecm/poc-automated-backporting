#!/usr/bin/env bash
# setup.sh — Bootstraps the POC repo: creates release branches and GitHub labels.
#
# Prerequisites:
#   - GitHub CLI (gh) installed and authenticated
#   - Git remote "origin" pointing to a GitHub repo
#
# Usage:
#   chmod +x setup.sh && ./setup.sh

set -euo pipefail

REPO=$(gh repo view --json nameWithOwner -q .nameWithOwner)
echo "==> Setting up backporting POC for $REPO"

# ── 1. Create release branches with diverged history ──────────────────────────

echo ""
echo "==> Creating release branches with diverged history..."

# Make sure we're on main
git checkout main

# --- release/1.0 (oldest, most diverged) ---
git checkout -b release/1.0
cat >> app.py << 'EOF'


def power(a: float, b: float) -> float:
    """Added only in release/1.0"""
    return a ** b
EOF
git add app.py
git commit -m "release/1.0: add power function"
git push -u origin release/1.0

# --- release/2.0 (medium divergence) ---
git checkout main
git checkout -b release/2.0
cat >> app.py << 'EOF'


def modulo(a: float, b: float) -> float:
    """Added only in release/2.0"""
    if b == 0:
        raise ValueError("Cannot modulo by zero")
    return a % b
EOF
git add app.py
git commit -m "release/2.0: add modulo function"
git push -u origin release/2.0

# --- release/3.0 (closest to main, least divergence) ---
git checkout main
git checkout -b release/3.0
git push -u origin release/3.0

git checkout main
echo "==> Release branches created: release/1.0, release/2.0, release/3.0"

# ── 2. Create GitHub labels ──────────────────────────────────────────────────

echo ""
echo "==> Creating GitHub labels..."

create_label() {
  local name="$1"
  local color="$2"
  local description="$3"
  if gh label create "$name" --color "$color" --description "$description" --repo "$REPO" 2>/dev/null; then
    echo "  Created label: $name"
  else
    echo "  Label already exists: $name"
  fi
}

create_label "target:release/1.0" "0E8A16" "Backport to release/1.0"
create_label "target:release/2.0" "1D76DB" "Backport to release/2.0"
create_label "target:release/3.0" "D93F0B" "Backport to release/3.0"

# ── 3. Enable auto-merge (reminder) ──────────────────────────────────────────

echo ""
echo "==> Enabling auto-merge on the repository..."
gh repo edit --enable-auto-merge --repo "$REPO" || echo "  (Could not enable auto-merge — enable it manually in Settings > General > Pull Requests)"

echo ""
echo "==> Setup complete!"
echo ""
echo "Next steps:"
echo "  1. Verify labels at:  https://github.com/$REPO/labels"
echo "  2. Verify branches at: https://github.com/$REPO/branches"
echo "  3. Ensure 'Allow auto-merge' is ON in repo Settings > General > Pull Requests"
echo "  4. Create a test PR to main, add a 'target:release/3.0' label, merge, and watch the backport action run."
