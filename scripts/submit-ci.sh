#!/bin/bash
# submit-ci.sh — Create and push a submission branch to the competition GitLab.
#
# Usage:
#   ./scripts/submit-ci.sh              # auto-generate branch name
#   ./scripts/submit-ci.sh my-branch    # use custom branch name

set -euo pipefail

GITLAB_REMOTE="${GITLAB_REMOTE:-gitlab}"
GITLAB_BASE="${GITLAB_BASE:-gitlab/main}"
BRANCH="${1:-submit-$(date +%Y%m%d-%H%M)}"
CUR_BRANCH=$(git rev-parse --abbrev-ref HEAD)
WORKTREE=$(mktemp -d /tmp/submit-ci-XXXXXX)

cleanup() {
    git checkout "${CUR_BRANCH}" >/dev/null 2>&1 || true
    git worktree remove "${WORKTREE}" --force 2>/dev/null || rm -rf "${WORKTREE}"
}
trap cleanup EXIT

echo "=== GitLab CI Submission ==="
echo "  Remote : ${GITLAB_REMOTE}"
echo "  Base   : ${GITLAB_BASE}"
echo "  Branch : ${BRANCH}"

echo "[1/5] Creating worktree from ${GITLAB_BASE}..."
git worktree add -b "${BRANCH}" "${WORKTREE}" "${GITLAB_BASE}" 2>/dev/null || {
    git worktree add "${WORKTREE}" "${GITLAB_BASE}"
    cd "${WORKTREE}"
    git checkout -b "${BRANCH}"
    cd - >/dev/null
}

echo "[2/5] Resolving symlinks from src/soc/..."
mkdir -p "${WORKTREE}/src/soc"
rsync -a --copy-links src/soc/ "${WORKTREE}/src/soc/"
cp run_vivado/constraints/soc.xdc "${WORKTREE}/run_vivado/constraints/soc.xdc" 2>/dev/null || true

echo "[3/5] Committing..."
cd "${WORKTREE}"
git add -A
git commit -m "CI submission from ${CUR_BRANCH} @ $(git -C "${OLDPWD}" rev-parse --short HEAD)

RTL files resolved from symlinks at src/soc/"
cd - >/dev/null

echo "[4/5] Pushing to ${GITLAB_REMOTE}..."
cd "${WORKTREE}"
git push "${GITLAB_REMOTE}" "${BRANCH}"
cd - >/dev/null

echo "[5/5] Cleaning up worktree..."
git worktree remove "${WORKTREE}" --force 2>/dev/null || rm -rf "${WORKTREE}"

echo "=== Done: ${BRANCH} pushed to ${GITLAB_REMOTE} ==="
echo "View CI: http://OJ_HOST_REDACTED:18001"
