#!/bin/zsh

emulate -L zsh
setopt errexit nounset pipefail

SCRIPT_DIR=${0:A:h}
source "${SCRIPT_DIR}/codex_xcodebuildmcp_common.sh"

CODEX_DEMO_SCHEME=${CODEX_DEMO_SCHEME:-DemoApp}
CODEX_DEMO_BUNDLE_ID=${CODEX_DEMO_BUNDLE_ID:-io.getstream.iOS.VideoDemoApp}
CODEX_DEMO_CONFIGURATION=${CODEX_DEMO_CONFIGURATION:-Debug}
CODEX_TERMINAL_LOG_ENV=${CODEX_TERMINAL_LOG_ENV:-STREAM_VIDEO_TERMINAL_LOGS}
CODEX_BUILD_COMMAND=()
CODEX_LAUNCH_COMMAND=()

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
EOF
}

codex_build_settings_json() {
    local destination="$1"

    "${CODEX_XCODEBUILD_BIN}" \
        -project "${CODEX_PROJECT_PATH}" \
        -scheme "${CODEX_DEMO_SCHEME}" \
        -configuration "${CODEX_DEMO_CONFIGURATION}" \
        -destination "${destination}" \
        -showBuildSettings \
        -json
}

codex_build_app() {
    CODEX_BUILD_COMMAND=(
        -project "${CODEX_PROJECT_PATH}" \
        -scheme "${CODEX_DEMO_SCHEME}" \
        -configuration "${CODEX_DEMO_CONFIGURATION}" \
        -destination "$1" \
        -hideShellScriptEnvironment \
        build
    )
    CODEX_BUILD_COMMAND=("${CODEX_XCODEBUILD_BIN}" "${CODEX_BUILD_COMMAND[@]}")
}

codex_app_artifact_field() {
    local destination="$1"
    local field="$2"
    local payload

    payload="$(codex_build_settings_json "${destination}")"

    BUILD_SETTINGS_JSON="${payload}" python3 - "${field}" <<'PY'
import json
import os
import sys

field = sys.argv[1]
payload = json.loads(os.environ["BUILD_SETTINGS_JSON"])

for entry in payload:
    settings = entry.get("buildSettings", {})
    if settings.get("PRODUCT_TYPE") != "com.apple.product-type.application":
        continue

    if field == "app_path":
        print(f"{settings['TARGET_BUILD_DIR']}/{settings['FULL_PRODUCT_NAME']}")
    else:
        print(settings[field])
    raise SystemExit(0)

raise SystemExit(1)
PY
}

codex_print_command() {
    local label="$1"
    shift

    printf '%s:' "${label}"
    printf ' %q' "$@"
    printf '\n'
}

codex_build_simulator_launch_command() {
    local simulator_id="$1"

    CODEX_LAUNCH_COMMAND=(
        env
        "SIMCTL_CHILD_${CODEX_TERMINAL_LOG_ENV}=1"
        xcrun simctl launch
        --console-pty
        --terminate-running-process
        "${simulator_id}"
        "${CODEX_DEMO_BUNDLE_ID}"
    )
}

codex_build_device_launch_command() {
    local device_id="$1"

    CODEX_LAUNCH_COMMAND=(
        env
        "DEVICECTL_CHILD_${CODEX_TERMINAL_LOG_ENV}=1"
        xcrun devicectl device process launch
        --device "${device_id}"
        --console
        --terminate-existing
        "${CODEX_DEMO_BUNDLE_ID}"
    )
}

codex_prepare_simulator() {
    local simulator_id="$1"

    open -a Simulator --args -CurrentDeviceUDID "${simulator_id}" \
        >/dev/null 2>&1 || true

    if ! xcrun simctl bootstatus "${simulator_id}" -b >/dev/null 2>&1; then
        xcrun simctl boot "${simulator_id}" >/dev/null 2>&1 || true
        xcrun simctl bootstatus "${simulator_id}" -b
    fi
}

codex_select_destination_record() {
    local simulator_records="$1"
    local device_records="$2"
    local selection_type="$3"
    local selected_udid selected_record

    selected_udid="$(
        codex_select_udid_with_simulator_buddy "${selection_type}"
    )" || return $?

    selected_record="$(codex_find_record_by_udid "${simulator_records}" "${selected_udid}")"
    if [[ -n "${selected_record}" ]]; then
        CODEX_RESOLVED_DESTINATION_KIND="simulator"
        CODEX_RESOLVED_RECORD="${selected_record}"
        return 0
    fi

    selected_record="$(codex_find_record_by_udid "${device_records}" "${selected_udid}")"
    if [[ -n "${selected_record}" ]]; then
        CODEX_RESOLVED_DESTINATION_KIND="device"
        CODEX_RESOLVED_RECORD="${selected_record}"
        return 0
    fi

    echo \
        "error: Selected destination ${selected_udid} is not available for ${CODEX_DEMO_SCHEME}." \
        >&2
    return 2
}

codex_resolve_destination() {
    local simulator_records device_records selected_record selection_type
    local destination_kind="${CODEX_DEMO_DESTINATION:-}"
    local simulator_id="${CODEX_SIMULATOR_ID:-}"
    local device_id="${CODEX_DEVICE_ID:-}"
    local choose_simulator=false
    local choose_device=false

    dry_run=false

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
                codex_die "Unknown argument: $1"
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

    codex_ensure_repo_root
    simulator_records="$(codex_simulator_records "${CODEX_DEMO_SCHEME}")"
    device_records="$(codex_device_records "${CODEX_DEMO_SCHEME}")"

    if [[ -n "${destination_kind}" && "${destination_kind}" != "simulator" && "${destination_kind}" != "device" ]]; then
        codex_die "CODEX_DEMO_DESTINATION must be simulator or device."
    fi

    if [[ -n "${device_id}" ]]; then
        [[ -z "${simulator_id}" ]] || codex_die "Cannot combine simulator and device options."
        ${choose_simulator} && codex_die "Cannot combine simulator and device options."
        destination_kind="device"
        selected_record="$(codex_find_record_by_udid "${device_records}" "${device_id}")"
        [[ -n "${selected_record}" ]] || codex_die "Device ${device_id} was not found."
    elif [[ -n "${simulator_id}" ]]; then
        [[ -z "${device_id}" ]] || codex_die "Cannot combine simulator and device options."
        destination_kind="simulator"
        selected_record="$(codex_find_record_by_udid "${simulator_records}" "${simulator_id}")"
        [[ -n "${selected_record}" ]] || codex_die "Simulator ${simulator_id} was not found."
    else
        if ${choose_device}; then
            ${choose_simulator} && codex_die "Choose either a simulator or a device, not both."
            selection_type="device"
        elif ${choose_simulator}; then
            selection_type="simulator"
        elif [[ -n "${destination_kind}" ]]; then
            selection_type="${destination_kind}"
        else
            selection_type="all"
        fi

        codex_select_destination_record \
            "${simulator_records}" \
            "${device_records}" \
            "${selection_type}" || exit $?
        destination_kind="${CODEX_RESOLVED_DESTINATION_KIND}"
        selected_record="${CODEX_RESOLVED_RECORD}"
    fi

    [[ -n "${selected_record}" ]] || codex_die "No destination was resolved."

    CODEX_RESOLVED_DRY_RUN="${dry_run}"
    CODEX_RESOLVED_DESTINATION_KIND="${destination_kind}"
    CODEX_RESOLVED_RECORD="${selected_record}"
}

codex_run_simulator() {
    local record="$1"
    local dry_run="$2"
    local simulator_name simulator_udid simulator_os destination app_path

    IFS='|' read -r simulator_name simulator_udid simulator_os <<< "${record}"
    destination="id=${simulator_udid}"
    codex_build_app "${destination}"
    codex_build_simulator_launch_command "${simulator_udid}"

    echo "Running ${CODEX_DEMO_SCHEME} on ${simulator_name} (${simulator_udid})"

    if [[ "${dry_run}" == "true" ]]; then
        app_path="$(codex_app_artifact_field "${destination}" app_path)"
        codex_print_command "Build" "${CODEX_BUILD_COMMAND[@]}"
        codex_print_command "Install" \
            xcrun simctl install "${simulator_udid}" "${app_path}"
        codex_print_command "Launch" "${CODEX_LAUNCH_COMMAND[@]}"
        return 0
    fi

    codex_prepare_simulator "${simulator_udid}"
    echo "==> Building ${CODEX_DEMO_SCHEME}"
    "${CODEX_BUILD_COMMAND[@]}"
    echo "==> Resolving app bundle path"
    app_path="$(codex_app_artifact_field "${destination}" app_path)"
    echo "==> Installing on ${simulator_name}"
    xcrun simctl install "${simulator_udid}" "${app_path}"
    echo "==> Launching ${CODEX_DEMO_SCHEME}"
    "${CODEX_LAUNCH_COMMAND[@]}"
}

codex_run_device() {
    local record="$1"
    local dry_run="$2"
    local device_name device_udid _ build_destination app_path

    IFS='|' read -r device_name device_udid _ <<< "${record}"
    build_destination="generic/platform=iOS"
    codex_build_app "${build_destination}"
    codex_build_device_launch_command "${device_udid}"

    echo "Running ${CODEX_DEMO_SCHEME} on ${device_name} (${device_udid})"

    if [[ "${dry_run}" == "true" ]]; then
        app_path="$(codex_app_artifact_field "${build_destination}" app_path)"
        codex_print_command "Build" "${CODEX_BUILD_COMMAND[@]}"
        codex_print_command "Install" \
            xcrun devicectl device install app \
            --device "${device_udid}" \
            "${app_path}"
        codex_print_command "Launch" "${CODEX_LAUNCH_COMMAND[@]}"
        return 0
    fi

    echo "==> Building ${CODEX_DEMO_SCHEME}"
    "${CODEX_BUILD_COMMAND[@]}"
    echo "==> Resolving app bundle path"
    app_path="$(codex_app_artifact_field "${build_destination}" app_path)"
    echo "==> Installing on ${device_name}"
    xcrun devicectl device install app \
        --device "${device_udid}" \
        "${app_path}"
    echo "==> Launching ${CODEX_DEMO_SCHEME}"
    "${CODEX_LAUNCH_COMMAND[@]}"
}

codex_require_command "${CODEX_XCODEBUILD_BIN}"
codex_require_command "${CODEX_SIMULATOR_BUDDY_BIN}"
codex_require_command xcrun
codex_require_command python3
codex_resolve_destination "$@"

case "${CODEX_RESOLVED_DESTINATION_KIND}" in
    simulator)
        codex_run_simulator "${CODEX_RESOLVED_RECORD}" \
            "${CODEX_RESOLVED_DRY_RUN}"
        ;;
    device)
        codex_run_device "${CODEX_RESOLVED_RECORD}" \
            "${CODEX_RESOLVED_DRY_RUN}"
        ;;
    *)
        codex_die "Unsupported destination kind: ${CODEX_RESOLVED_DESTINATION_KIND}"
        ;;
esac
