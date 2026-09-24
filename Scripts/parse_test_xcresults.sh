#!/bin/bash
set -uo pipefail

scheme="${1:?Pass the test scheme}"
output="${2:-fastlane/test_output}"
status=0
[[ -d "$output" ]] || exit 0

while IFS= read -r -d '' result; do
    relative="${result#"$output/"}"
    destination="$output/logs/${relative%.xcresult}"
    mkdir -p "$destination"
    if ! xcrun xcresulttool get test-results summary --path "$result" > "$destination/summary.json"; then
        status=1
        continue
    fi
    xcparse logs "$result" "$destination" || status=1
done < <(find "$output" -type d -name "$scheme.xcresult" -prune -print0)

exit "$status"
