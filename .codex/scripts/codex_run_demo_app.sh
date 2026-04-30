#!/bin/zsh

emulate -L zsh
setopt errexit nounset pipefail

SCRIPT_DIR=${0:A:h}
source "${SCRIPT_DIR}/codex_xcodebuildmcp_common.sh"

CODEX_DEMO_SCHEME=${CODEX_DEMO_SCHEME:-DemoApp}
CODEX_DEMO_CONFIGURATION=${CODEX_DEMO_CONFIGURATION:-Debug}
CODEX_DEMO_BUNDLE_ID=${CODEX_DEMO_BUNDLE_ID:-}
CODEX_TERMINAL_LOG_ENV=${CODEX_TERMINAL_LOG_ENV:-STREAM_VIDEO_TERMINAL_LOGS}
CODEX_DEMO_LOG_CATEGORIES=${CODEX_DEMO_LOG_CATEGORIES:-Video}

usage() {
    cat <<'EOF'
Usage:
  ./.codex/scripts/codex_run_demo_app.sh [--dry-run]
  ./.codex/scripts/codex_run_demo_app.sh --choose-simulator [--dry-run]
  ./.codex/scripts/codex_run_demo_app.sh --choose-device [--dry-run]
  ./.codex/scripts/codex_run_demo_app.sh --simulator-id <udid> [--dry-run]
  ./.codex/scripts/codex_run_demo_app.sh --device-id <udid> [--dry-run]

Optional environment overrides:
  CODEX_DEMO_DESTINATION=simulator|device
  CODEX_SIMULATOR_ID=<udid>
  CODEX_DEVICE_ID=<udid>
  CODEX_DEMO_LOG_CATEGORIES=Video,WebRTC
EOF
}

codex_print_command() {
    local label="$1"
    shift

    printf '%s:' "${label}"
    printf ' %q' "$@"
    printf '\n'
}

codex_destination_from_options() {
    local simulator_id="${CODEX_SIMULATOR_ID:-}"
    local device_id="${CODEX_DEVICE_ID:-}"
    local choose_simulator=false
    local choose_device=false
    local dry_run=false
    local extra_options=()

    while (( $# > 0 )); do
        case "$1" in
            --dry-run)
                dry_run=true
                ;;
            --choose-simulator)
                choose_simulator=true
                ;;
            --choose-device)
                choose_device=true
                ;;
            --simulator-id)
                shift
                (( $# > 0 )) || codex_die "--simulator-id requires a value."
                simulator_id="$1"
                ;;
            --device-id)
                shift
                (( $# > 0 )) || codex_die "--device-id requires a value."
                device_id="$1"
                ;;
            --help|-h)
                usage
                exit 0
                ;;
            *)
                extra_options+=("$1")
                ;;
        esac
        shift
    done

    if ${choose_simulator} && ${choose_device}; then
        codex_die "Choose either a simulator or a device, not both."
    fi

    if [[ -n "${simulator_id}" && -n "${device_id}" ]]; then
        codex_die "Provide either --simulator-id or --device-id, not both."
    fi

    if [[ -n "${simulator_id}" ]]; then
        extra_options+=(--destination "${simulator_id}")
    elif [[ -n "${device_id}" ]]; then
        extra_options+=(--destination "${device_id}")
    elif ${choose_simulator}; then
        extra_options+=(--type simulator)
    elif ${choose_device}; then
        extra_options+=(--type device)
    elif [[ "${CODEX_DEMO_DESTINATION:-}" == "simulator" ]]; then
        extra_options+=(--type simulator)
    elif [[ "${CODEX_DEMO_DESTINATION:-}" == "device" ]]; then
        extra_options+=(--type device)
    elif [[ -n "${CODEX_DEMO_DESTINATION:-}" ]]; then
        codex_die "CODEX_DEMO_DESTINATION must be simulator or device."
    fi

    CODEX_RESOLVED_DRY_RUN="${dry_run}"
    CODEX_RESOLVED_OPTIONS=("${extra_options[@]}")
}

codex_ensure_repo_root
codex_require_command "${CODEX_SIMULATOR_BUDDY_BIN}"
codex_destination_from_options "$@"

run_command=(
    "${CODEX_SIMULATOR_BUDDY_BIN}" run
    --env "${CODEX_TERMINAL_LOG_ENV}=1"
    "${CODEX_RESOLVED_OPTIONS[@]}"
)

if [[ -n "${CODEX_DEMO_LOG_CATEGORIES}" ]]; then
    run_command+=(--log-category "${CODEX_DEMO_LOG_CATEGORIES}")
fi

if [[ -n "${CODEX_DEMO_BUNDLE_ID}" ]]; then
    run_command+=(--bundle-id "${CODEX_DEMO_BUNDLE_ID}")
fi

run_command+=(
    -project "${CODEX_PROJECT_PATH}"
    -scheme "${CODEX_DEMO_SCHEME}"
    -configuration "${CODEX_DEMO_CONFIGURATION}"
    -hideShellScriptEnvironment
)

if [[ "${CODEX_RESOLVED_DRY_RUN}" == "true" ]]; then
    codex_print_command "Dry run" "${run_command[@]}"
    exit 0
fi

exec "${run_command[@]}"
