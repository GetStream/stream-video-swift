#!/bin/zsh

emulate -L zsh
setopt errexit nounset pipefail

SCRIPT_DIR=${0:A:h}
source "${SCRIPT_DIR}/codex_xcodebuildmcp_common.sh"

usage() {
    cat <<'EOF'
Usage:
  ./.codex/scripts/codex_test_scheme.sh <scheme> [--dry-run]
  ./.codex/scripts/codex_test_scheme.sh <scheme> --simulator-id <udid> [--dry-run]
EOF
}

(( $# >= 1 )) || {
    usage
    exit 1
}

scheme="$1"
shift

dry_run=false
choose_simulator=false
simulator_id=""

while (( $# > 0 )); do
    case "$1" in
        --dry-run)
            dry_run=true
            ;;
        --choose-simulator)
            choose_simulator=true
            ;;
        --simulator-id)
            shift
            (( $# > 0 )) || codex_die "--simulator-id requires a value."
            simulator_id="$1"
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

case "${scheme}" in
    StreamVideo|StreamVideoSwiftUI|StreamVideoUIKit)
        ;;
    *)
        codex_die "Unsupported scheme: ${scheme}"
        ;;
esac

codex_require_command "${CODEX_SIMULATOR_BUDDY_BIN}"
codex_require_command python3
codex_ensure_repo_root
echo "==> Resolving simulators for ${scheme}"
simulator_records="$(codex_destination_records simulator)"

if [[ -n "${simulator_id}" ]]; then
    selected_record="$(codex_find_record_by_udid "${simulator_records}" "${simulator_id}")"
    [[ -n "${selected_record}" ]] || codex_die "Simulator ${simulator_id} was not found."
else
    selected_record="$(
        codex_select_record_with_simulator_buddy \
            simulator
    )" || exit $?
fi

IFS='|' read -r _ simulator_name simulator_udid simulator_os <<< "${selected_record}"

command=(
    "${CODEX_XCODEBUILD_BIN}"
    test
    -project "${CODEX_PROJECT_PATH}"
    -scheme "${scheme}"
    -destination "platform=iOS Simulator,id=${simulator_udid}"
)

echo "Testing ${scheme} on ${simulator_name} (${simulator_udid})"

if ${dry_run}; then
    printf 'Dry run:'
    printf ' %q' "${command[@]}"
    printf '\n'
    exit 0
fi

"${command[@]}"
