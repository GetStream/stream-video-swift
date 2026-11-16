#!/usr/bin/env bash
# Opens a pull request when generated OpenAPI models changed.
# The workflow runs this from the repository root. Fastlane's pr_create
# action adds ../Sources, which current Git rejects as outside the repo.

set -euo pipefail

root="${OPENAPI_PR_ROOT:-$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)}"
cd "$root"

generated="Sources/StreamVideo/OpenApi/generated"
title="[Hygiene]OpenAPI models generation"

if [ -z "$(git status --porcelain -- "$generated")" ]; then
  echo "Generated models are unchanged."
  exit 0
fi

base="${GITHUB_REF_NAME:?set GITHUB_REF_NAME to the base branch}"
branch="${base}-openapi-$(date +%s)"
git checkout -b "$branch"
git add -A -- "$generated"

if [ -z "$(git diff --cached --name-only)" ]; then
  echo "Nothing staged."
  exit 0
fi

author_name="${GIT_AUTHOR_NAME:-}"
author_email="${GIT_AUTHOR_EMAIL:-}"
if [ -z "$author_name" ] || [ -z "$author_email" ]; then
  # gh in Actions reads GH_TOKEN and ignores GITHUB_TOKEN.
  export GH_TOKEN="${GITHUB_TOKEN:?set GITHUB_TOKEN}"
  author_name="$(gh api user --jq .login)"
  author_id="$(gh api user --jq .id)"
  author_email="${author_id}+${author_name}@users.noreply.github.com"
fi

GIT_AUTHOR_NAME="$author_name" \
  GIT_AUTHOR_EMAIL="$author_email" \
  GIT_COMMITTER_NAME="$author_name" \
  GIT_COMMITTER_EMAIL="$author_email" \
  git commit -m "$title"

if [ "${OPENAPI_PR_SKIP_PUBLISH:-}" = 1 ]; then
  echo "Skipped push and pull request."
  exit 0
fi

# This repository rejects fine-grained personal access tokens for Git
# pushes. The checkout credential is the workflow GITHUB_TOKEN.
env -u GH_TOKEN git push --set-upstream origin "$branch"
export GH_TOKEN="${GITHUB_TOKEN:?set GITHUB_TOKEN}"

body="This PR was created automatically by CI."
if [ -n "${GITHUB_RUN_ID:-}" ]; then
  body="${body}

Triggered by: ${GITHUB_SERVER_URL}/${GITHUB_REPOSITORY}/actions/runs/${GITHUB_RUN_ID}"
fi

gh pr create \
  --base "$base" \
  --head "$branch" \
  --title "$title" \
  --body "$body"
