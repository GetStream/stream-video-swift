#!/bin/zsh

emulate -L zsh
setopt errexit nounset pipefail

ROOT_DIR=${0:A:h:h}
SCRIPT_PATH="${ROOT_DIR}/scripts/codex_run_demo_app.sh"
TEST_SCHEME_SCRIPT_PATH="${ROOT_DIR}/scripts/codex_test_scheme.sh"
SIMULATOR_BUDDY_BIN=${SIMULATOR_BUDDY_BIN:-simulator-buddy}

fake_xcodebuild="$(mktemp)"
trap 'rm -f "${fake_xcodebuild}"' EXIT

cat >"${fake_xcodebuild}" <<'EOF'
#!/usr/bin/env bash
set -euo pipefail

for arg in "$@"; do
    if [[ "${arg}" == "-showdestinations" ]]; then
        echo "Unexpected -showdestinations invocation" >&2
        exit 99
    fi
done

case " $* " in
    *" -showBuildSettings "*)
        cat <<'JSON'
[{"buildSettings":{"PRODUCT_TYPE":"com.apple.product-type.application","TARGET_BUILD_DIR":"/tmp/CodexProducts","FULL_PRODUCT_NAME":"StreamVideoCallApp-Debug.app"}}]
JSON
        ;;
    *)
        echo "Unexpected xcodebuild invocation: $*" >&2
        exit 98
        ;;
esac
EOF

chmod +x "${fake_xcodebuild}"

assert_contains() {
    local haystack="$1"
    local needle="$2"

    if [[ "${haystack}" != *"${needle}"* ]]; then
        echo "Expected output to contain: ${needle}" >&2
        echo "${haystack}" >&2
        exit 1
    fi
}

assert_not_contains() {
    local haystack="$1"
    local needle="$2"

    if [[ "${haystack}" == *"${needle}"* ]]; then
        echo "Expected output not to contain: ${needle}" >&2
        echo "${haystack}" >&2
        exit 1
    fi
}

first_simulator_id="$(
    "${SIMULATOR_BUDDY_BIN}" list --type simulator --format json | python3 -c '
import json
import sys

for item in json.load(sys.stdin):
    if item.get("state") == "unavailable":
        continue
    print(item["udid"])
    break
'
)"

[[ -n "${first_simulator_id}" ]] || {
    echo "No simulator destination available for test." >&2
    exit 1
}

simulator_output="$(
    "${SCRIPT_PATH}" --dry-run
)"

assert_contains "${simulator_output}" "Dry run: simulator-buddy run"
assert_contains "${simulator_output}" "--env STREAM_VIDEO_TERMINAL_LOGS=1"
assert_contains "${simulator_output}" "--log-category Video"
assert_contains "${simulator_output}" "-project"
assert_contains "${simulator_output}" "StreamVideo.xcodeproj"
assert_contains "${simulator_output}" "-scheme DemoApp"
assert_contains "${simulator_output}" "-hideShellScriptEnvironment"
assert_not_contains "${simulator_output}" "xcrun simctl"
assert_not_contains "${simulator_output}" "xcrun devicectl"

simulator_choice_output="$("${SCRIPT_PATH}" --choose-simulator --dry-run)"
assert_contains "${simulator_choice_output}" "--type simulator"

device_choice_output="$("${SCRIPT_PATH}" --choose-device --dry-run)"
assert_contains "${device_choice_output}" "--type device"

direct_destination_output="$("${SCRIPT_PATH}" --simulator-id SIM-TEST --dry-run)"
assert_contains "${direct_destination_output}" "--destination SIM-TEST"

test_scheme_output="$(
    XCODEBUILD_BIN="${fake_xcodebuild}" \
        "${TEST_SCHEME_SCRIPT_PATH}" StreamVideo --simulator-id "${first_simulator_id}" --dry-run
)"

assert_contains "${test_scheme_output}" "==> Resolving simulators for StreamVideo"
assert_contains "${test_scheme_output}" "Dry run: ${fake_xcodebuild} test"

echo "codex_run_demo_app tests passed"
