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

token_root="$(mktemp -d)"
trap 'rm -rf "$root" "$token_root"' EXIT
bindir="$token_root/bin"
mkdir -p "$bindir" "$token_root/Sources/StreamVideo/OpenApi/generated"
cat > "$bindir/gh" <<'EOF'
#!/usr/bin/env bash
if [ "${GH_TOKEN:-}" != "workflow-token" ]; then
  echo "gh expected GITHUB_TOKEN, saw GH_TOKEN=${GH_TOKEN:-empty}" >&2
  exit 9
fi
case "${4:-}" in
  .login) echo "actions-bot" ;;
  .id) echo "1" ;;
  *) echo "unexpected gh $*" >&2; exit 9 ;;
esac
EOF
chmod +x "$bindir/gh"
git -C "$token_root" init -q
git -C "$token_root" config user.name "OpenAPI Test"
git -C "$token_root" config user.email "openapi-test@example.com"
printf 'old\n' > "$token_root/Sources/StreamVideo/OpenApi/generated/Model.swift"
git -C "$token_root" add Sources
git -C "$token_root" commit -q -m "base"
git -C "$token_root" branch -M main
printf 'token\n' > "$token_root/Sources/StreamVideo/OpenApi/generated/Model.swift"
PATH="$bindir:$PATH" \
  OPENAPI_PR_ROOT="$token_root" \
  OPENAPI_PR_SKIP_PUBLISH=1 \
  GITHUB_REF_NAME=main \
  GH_TOKEN=workflow-token \
  GIT_AUTHOR_NAME= \
  GIT_AUTHOR_EMAIL= \
  "$script"
test "$(git -C "$token_root" log -1 --format=%an)" = "actions-bot"

echo "openapi_open_pull_request_test: ok"
