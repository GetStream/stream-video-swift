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
  author_name="$(gh api user --jq .login)"
  author_id="$(gh api user --jq .id)"
  author_email="${author_id}+${author_name}@users.noreply.github.com"
fi

git -c "user.name=${author_name}" -c "user.email=${author_email}" commit -m "$title"

if [ "${OPENAPI_PR_SKIP_PUBLISH:-}" = 1 ]; then
  echo "Skipped push and pull request."
  exit 0
fi

git push --set-upstream origin "$branch"

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
