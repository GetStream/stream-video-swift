#!/bin/zsh

CODEX_SCRIPT_DIR=${0:A:h}
CODEX_REPO_ROOT=${CODEX_SCRIPT_DIR:h:h}
CODEX_PROJECT_PATH="${CODEX_REPO_ROOT}/StreamVideo.xcodeproj"
CODEX_SIMULATOR_BUDDY_BIN=${SIMULATOR_BUDDY_BIN:-simulator-buddy}
CODEX_DESTINATION_SCOPE=${CODEX_DESTINATION_SCOPE:-${CODEX_REPO_ROOT}}
CODEX_XCODEBUILDMCP_BIN=${XCODEBUILDMCP_BIN:-xcodebuildmcp}
CODEX_XCODEBUILD_BIN=${XCODEBUILD_BIN:-xcodebuild}

codex_die() {
    echo "error: $*" >&2
    exit 1
}

codex_ensure_repo_root() {
    cd "${CODEX_REPO_ROOT}"
}

codex_require_command() {
    command -v "$1" >/dev/null 2>&1 || codex_die "Missing required command: $1"
}

codex_destination_records() {
    local selection_type="${1:-all}"
    local payload

    codex_require_command "${CODEX_SIMULATOR_BUDDY_BIN}"
    codex_require_command python3

    payload="$(
        "${CODEX_SIMULATOR_BUDDY_BIN}" list \
            --type "${selection_type}" \
            --format json \
            2>/dev/null
    )" || {
        echo "error: simulator-buddy list failed for ${selection_type}." >&2
        return 2
    }

    SIMULATOR_BUDDY_JSON="${payload}" python3 - <<'PY'
import json
import os

items = json.loads(os.environ["SIMULATOR_BUDDY_JSON"])

for item in items:
    kind = item.get("kind")
    name = item.get("name")
    udid = item.get("udid")
    runtime = item.get("runtime", "")
    state = item.get("state")

    if not kind or not name or not udid or state == "unavailable":
        continue

    print(f"{kind}|{name}|{udid}|{runtime}")
PY
}

codex_simulator_records() {
    local records="${1:-$(codex_destination_records simulator)}"
    print -r -- "${records}" | awk -F'|' '$1 == "simulator"'
}

codex_device_records() {
    local records="${1:-$(codex_destination_records device)}"
    print -r -- "${records}" | awk -F'|' '$1 == "device"'
}

codex_find_record_by_udid() {
    local records="$1"
    local udid="$2"

    if [[ -z "${records}" || -z "${udid}" ]]; then
        return 0
    fi

    print -r -- "${records}" | grep -F "|${udid}|" | head -n 1 || true
}

codex_record_udid() {
    local record="$1"
    print -r -- "${${(s:|:)record}[3]}"
}

codex_select_record_with_simulator_buddy() {
    local selection_type="$1"
    local output
    local exit_code

    codex_require_command "${CODEX_SIMULATOR_BUDDY_BIN}"
    codex_require_command python3

    output="$(
        "${CODEX_SIMULATOR_BUDDY_BIN}" select \
            --type "${selection_type}" \
            --scope "${CODEX_DESTINATION_SCOPE}" \
            --format json \
            2>/dev/null
    )"
    exit_code=$?

    case "${exit_code}" in
        0)
            ;;
        1)
            return 1
            ;;
        130)
            return 130
            ;;
        *)
            echo \
                "error: simulator-buddy select failed for ${selection_type}." \
                >&2
            return 2
            ;;
    esac

    SIMULATOR_BUDDY_JSON="${output}" python3 - <<'PY'
import json
import os

payload = json.loads(os.environ["SIMULATOR_BUDDY_JSON"])
destination = payload.get("destination") or {}

kind = destination.get("kind")
name = destination.get("name")
udid = destination.get("udid")
runtime = destination.get("runtime", "")
state = destination.get("state")

if not kind or not name or not udid or state == "unavailable":
    raise SystemExit(1)

print(f"{kind}|{name}|{udid}|{runtime}")
PY
}
