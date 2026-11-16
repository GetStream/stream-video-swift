#!/usr/bin/env bash
set -euo pipefail

helper="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)/openapi_generate_helpers.sh"

if grep -n "sed -i ''" "$helper"; then
  echo "BSD sed -i remains in $helper" >&2
  exit 1
fi

dir="$(mktemp -d)"
trap 'rm -rf "$dir"' EXIT
printf 'func send<Response: Codable>() {}\n' > "$dir/DefaultAPI.swift"
perl -pi -e 's/send<Response: Codable>/send<Response: Decodable>/' "$dir/DefaultAPI.swift"
grep -q 'send<Response: Decodable>()' "$dir/DefaultAPI.swift"

mkdir -p "$dir/Models" "$dir/APIs"
printf 'public struct VideoEvent {}\n' > "$dir/Models/VideoEvent.swift"
printf 'public struct Orphan {}\n' > "$dir/Models/Orphan.swift"
printf 'func send() {}\n' > "$dir/APIs/DefaultAPI.swift"
OUTPUT_DIR="$dir" bash -c 'set -euo pipefail; source "$1"; remove_unused_models' _ "$helper"
test -f "$dir/Models/VideoEvent.swift"
test ! -f "$dir/Models/Orphan.swift"

echo "openapi_generate_helpers_test: ok"
