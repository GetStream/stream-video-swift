#!/usr/bin/env bash
set -euo pipefail

script="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)/openapi_open_pull_request.sh"
root="$(mktemp -d)"
trap 'rm -rf "$root"' EXIT

git -C "$root" init -q
git -C "$root" config user.name "OpenAPI Test"
git -C "$root" config user.email "openapi-test@example.com"
mkdir -p "$root/Sources/StreamVideo/OpenApi/generated"
printf 'old\n' > "$root/Sources/StreamVideo/OpenApi/generated/Model.swift"
git -C "$root" add Sources
git -C "$root" commit -q -m "base"
git -C "$root" branch -M main

OPENAPI_PR_ROOT="$root" \
  OPENAPI_PR_SKIP_PUBLISH=1 \
  GITHUB_REF_NAME=main \
  "$script"
test "$(git -C "$root" branch --show-current)" = "main"

printf 'new\n' > "$root/Sources/StreamVideo/OpenApi/generated/Model.swift"
OPENAPI_PR_ROOT="$root" \
  OPENAPI_PR_SKIP_PUBLISH=1 \
  GITHUB_REF_NAME=main \
  GIT_AUTHOR_NAME="OpenAPI Test" \
  GIT_AUTHOR_EMAIL="openapi-test@example.com" \
  "$script"
test "$(git -C "$root" branch --show-current)" != "main"
test "$(git -C "$root" show HEAD:Sources/StreamVideo/OpenApi/generated/Model.swift)" = "new"

echo "openapi_open_pull_request_test: ok"
