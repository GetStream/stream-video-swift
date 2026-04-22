#!/bin/zsh

emulate -L zsh
setopt errexit nounset pipefail

ROOT_DIR=${0:A:h:h}
SCRIPT_PATH="${ROOT_DIR}/scripts/codex_run_demo_app.sh"
WORKDIR="${ROOT_DIR:h}"

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
    xcodebuild -project "${WORKDIR}/StreamVideo.xcodeproj" \
        -scheme DemoApp \
        -showdestinations | awk '
            /\{ platform:iOS Simulator,/ && $0 !~ /placeholder/ && $0 !~ /error:/ {
                line = $0
                sub(/^.*id:/, "", line)
                sub(/,.*/, "", line)
                gsub(/^[[:space:]]+|[[:space:]]+$/, "", line)
                if (line != "") {
                    print line
                    exit
                }
            }
        '
)"

[[ -n "${first_simulator_id}" ]] || {
    echo "No simulator destination available for test." >&2
    exit 1
}

simulator_output="$(
    "${SCRIPT_PATH}" --simulator-id "${first_simulator_id}" --dry-run
)"

assert_contains "${simulator_output}" "Build: xcodebuild"
assert_not_contains "${simulator_output}" "Build: xcodebuild -quiet"
assert_contains "${simulator_output}" "SIMCTL_CHILD_STREAM_VIDEO_TERMINAL_LOGS=1"
assert_contains "${simulator_output}" "--console-pty"

first_device_id="$(
    xcodebuild -project "${WORKDIR}/StreamVideo.xcodeproj" \
        -scheme DemoApp \
        -showdestinations | awk '
            /\{ platform:iOS,/ && $0 !~ /placeholder/ && $0 !~ /error:/ {
                line = $0
                sub(/^.*id:/, "", line)
                sub(/,.*/, "", line)
                gsub(/^[[:space:]]+|[[:space:]]+$/, "", line)
                if (line != "") {
                    print line
                    exit
                }
            }
        '
)"

if [[ -n "${first_device_id}" ]]; then
    device_output="$(
        "${SCRIPT_PATH}" --device-id "${first_device_id}" --dry-run
    )"

    assert_contains "${device_output}" "Build: xcodebuild"
    assert_not_contains "${device_output}" "Build: xcodebuild -quiet"
    assert_contains "${device_output}" "DEVICECTL_CHILD_STREAM_VIDEO_TERMINAL_LOGS=1"
    assert_contains "${device_output}" "--console"
fi

echo "codex_run_demo_app tests passed"
