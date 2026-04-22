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
    local scheme="$1"
    local platform="$2"

    codex_require_command "${CODEX_XCODEBUILD_BIN}"
    "${CODEX_XCODEBUILD_BIN}" \
        -project "${CODEX_PROJECT_PATH}" \
        -scheme "${scheme}" \
        -showdestinations | awk -v wanted_platform="${platform}" '
            /\{ platform:/ {
                line = $0
                sub(/^[[:space:]]*\{ /, "", line)
                sub(/ \}$/, "", line)

                split(line, parts, /, /)
                delete field

                for (i = 1; i <= length(parts); i++) {
                    separator = index(parts[i], ":")
                    if (separator == 0) {
                        continue
                    }

                    key = substr(parts[i], 1, separator - 1)
                    value = substr(parts[i], separator + 1)
                    field[key] = value
                }

                if (field["platform"] != wanted_platform) {
                    next
                }

                if (field["id"] ~ /^dvtdevice-/) {
                    next
                }

                if (field["error"] != "") {
                    next
                }

                print field["name"] "|" field["id"] "|" field["OS"]
            }
        '
}

codex_simulator_records() {
    local scheme="$1"
    codex_destination_records "${scheme}" "iOS Simulator"
}

codex_device_records() {
    local scheme="$1"
    codex_destination_records "${scheme}" "iOS"
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
    print -r -- "${${(s:|:)record}[2]}"
}

codex_simulator_buddy_udid() {
    local command="$1"
    local selection_type="$2"
    local output
    local exit_code

    output="$(
        "${CODEX_SIMULATOR_BUDDY_BIN}" "${command}" \
            --type "${selection_type}" \
            --scope "${CODEX_DESTINATION_SCOPE}" \
            2>/dev/null
    )"
    exit_code=$?

    if (( exit_code == 0 )); then
        print -r -- "${output}"
        return 0
    fi

    case "${exit_code}" in
        1)
            return 1
            ;;
        130)
            return 130
            ;;
        *)
            echo \
                "error: simulator-buddy ${command} failed for ${selection_type}." \
                >&2
            return 2
            ;;
    esac
}

codex_select_udid_with_simulator_buddy() {
    local selection_type="$1"
    local selected_udid
    local exit_code

    selected_udid="$(
        codex_simulator_buddy_udid select "${selection_type}"
    )"
    exit_code=$?

    case "${exit_code}" in
        0)
            print -r -- "${selected_udid}"
            return 0
            ;;
        130)
            return 130
            ;;
        *)
            return "${exit_code}"
            ;;
    esac
}

codex_select_record_with_simulator_buddy() {
    local records="$1"
    local selection_type="$2"
    local label="$3"
    local selected_udid selected_record

    selected_udid="$(
        codex_select_udid_with_simulator_buddy "${selection_type}"
    )" || return $?

    selected_record="$(codex_find_record_by_udid "${records}" "${selected_udid}")"
    if [[ -z "${selected_record}" ]]; then
        echo \
            "error: Selected ${label} ${selected_udid} is not available for this action." \
            >&2
        return 2
    fi

    print -r -- "${selected_record}"
}
