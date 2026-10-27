#!/usr/bin/env bash

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
PROJECT_ROOT="$(cd "$SCRIPT_DIR/.." && pwd)"
SOURCE_PATH="$(cd "$PROJECT_ROOT/../chat" && pwd)"
OUTPUT_DIR="$PROJECT_ROOT/Sources/StreamVideo/OpenApi/generated"
ALLOWED_FILE="$SCRIPT_DIR/openapi-allowed.json"
SPEC_DIR="$(mktemp -d)"
trap 'rm -rf "$SPEC_DIR"' EXIT

source "$SCRIPT_DIR/openapi_generate_helpers.sh"

if [ ! -d "$SOURCE_PATH" ]
then
  echo "cannot find chat path on the parent folder (${SOURCE_PATH}), do you have a copy of the API source?";
  exit 1;
fi

set -ex

# The spec no longer has this model, but the deprecated
# OwnUserResponse.pushNotifications returns it until IOS-2219 removes both.
cp "$OUTPUT_DIR/Models/PushNotificationSettingsResponse.swift" "$SPEC_DIR/"

# remove old generated code
rm -rf "$OUTPUT_DIR"

# run from the chat root: generate-spec reads tools/oasdiff relative to cwd
(
  cd "$SOURCE_PATH" &&
  make -C tools/openapi build &&
  # v1 keeps the /video paths and the guest, devices and longpoll endpoints
  ./build/openapi generate-spec -products video -version v1 -clientside -output "$SPEC_DIR/video-openapi-clientside" -renamed-models "$SCRIPT_DIR/renamed-models.json" &&
  # number_as_float keeps JSON numbers as Float. The generator defaults to Double
  # since Float truncates float64s, but our generated models are public, so
  # widening them would be a source and binary break.
  ./build/openapi generate-client --language swift --spec "$SPEC_DIR/video-openapi-clientside.yaml" --opt number_as_float=true --output "$OUTPUT_DIR/"
)

# The generator writes models/, git tracks Models/.
mv "$OUTPUT_DIR/models" "$OUTPUT_DIR/Models"

# DefaultEndpoints is unused. WSCallEvent clashes with VideoEvent's protocol.
rm -f "$OUTPUT_DIR/APIs/DefaultEndpoints.swift" "$OUTPUT_DIR/Models/WSCallEvent.swift"

# Shared OpenAPI types are provided by StreamCore.
rm -f \
  "$PROJECT_ROOT/Sources/StreamVideo/OpenApi/generated/APIHelper.swift" \
  "$PROJECT_ROOT/Sources/StreamVideo/OpenApi/generated/CodableHelper.swift" \
  "$PROJECT_ROOT/Sources/StreamVideo/OpenApi/generated/Extensions.swift" \
  "$PROJECT_ROOT/Sources/StreamVideo/OpenApi/generated/JSONDataEncoding.swift" \
  "$PROJECT_ROOT/Sources/StreamVideo/OpenApi/generated/Models.swift" \
  "$PROJECT_ROOT/Sources/StreamVideo/OpenApi/generated/OpenISO8601DateFormatter.swift" \
  "$PROJECT_ROOT/Sources/StreamVideo/OpenApi/generated/Models/APIError.swift" \
  "$PROJECT_ROOT/Sources/StreamVideo/OpenApi/generated/Models/ConnectUserDetailsRequest.swift" \
  "$PROJECT_ROOT/Sources/StreamVideo/OpenApi/generated/Models/CreateDeviceRequest.swift" \
  "$PROJECT_ROOT/Sources/StreamVideo/OpenApi/generated/Models/Device.swift" \
  "$PROJECT_ROOT/Sources/StreamVideo/OpenApi/generated/Models/ListDevicesResponse.swift" \
  "$PROJECT_ROOT/Sources/StreamVideo/OpenApi/generated/Models/ModelResponse.swift" \
  "$PROJECT_ROOT/Sources/StreamVideo/OpenApi/generated/Models/WSAuthMessageRequest.swift"

remove_unused_endpoints
remove_unused_events

# Keep the public API unchanged until the next major version removes these.
# https://linear.app/stream/issue/IOS-2219
keep_existing_v2_endpoints
remove_coding_keys_case_iterable
remove_properties
retype_properties
remove_enum_cases

# Runs last, so models only the removed properties used go too.
remove_unused_models

# format the generated code, .swiftformat excludes it by default
swiftformat --unexclude "$OUTPUT_DIR" "$OUTPUT_DIR"

# After formatting, so the kept model stays unchanged.
cp "$SPEC_DIR/PushNotificationSettingsResponse.swift" "$OUTPUT_DIR/Models/"
