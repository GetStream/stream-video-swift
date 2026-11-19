#!/usr/bin/env bash

set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
PROJECT_ROOT="$(cd "$SCRIPT_DIR/.." && pwd)"
OUTPUT_DIR="$PROJECT_ROOT/Sources/StreamVideo/OpenApi/generated"
ALLOWED_FILE="$SCRIPT_DIR/openapi-allowed.json"
SPEC_DIR="$(mktemp -d)"
trap 'rm -rf "$SPEC_DIR"' EXIT

source "$SCRIPT_DIR/openapi_generate_helpers.sh"

# Published v1 video client spec. generate-spec -products video -version v1
# -clientside writes this file into GetStream/protocol.
PROTOCOL_REF="${PROTOCOL_REF:-main}"
SPEC_NAME="video-openapi-clientside.yaml"
if [ -n "${PROTOCOL_SPEC:-}" ]; then
  SPEC_SOURCE="$PROTOCOL_SPEC"
elif [ -n "${PROTOCOL_DIR:-}" ]; then
  SPEC_SOURCE="$PROTOCOL_DIR/openapi/$SPEC_NAME"
else
  SPEC_SOURCE="$SPEC_DIR/$SPEC_NAME"
  curl -fsSL \
    -o "$SPEC_SOURCE" \
    "https://raw.githubusercontent.com/GetStream/protocol/${PROTOCOL_REF}/openapi/${SPEC_NAME}"
fi

if [ ! -f "$SPEC_SOURCE" ]; then
  echo "cannot read video client spec at ${SPEC_SOURCE}" >&2
  exit 1
fi

# The Swift generator binary lives in the private chat repo. The spec does not.
if [ -n "${OPENAPI:-}" ]; then
  OPENAPI_BIN="$OPENAPI"
elif [ -x "$PROJECT_ROOT/../chat/build/openapi" ]; then
  OPENAPI_BIN="$PROJECT_ROOT/../chat/build/openapi"
elif [ -d "$PROJECT_ROOT/../chat/tools/openapi" ]; then
  make -C "$PROJECT_ROOT/../chat/tools/openapi" build
  OPENAPI_BIN="$PROJECT_ROOT/../chat/build/openapi"
else
  echo "cannot find the openapi generator binary. Set OPENAPI to chat's build/openapi." >&2
  exit 1
fi

set -exo pipefail

ruby "$SCRIPT_DIR/apply_renamed_models.rb" \
  "$SPEC_SOURCE" \
  "$SCRIPT_DIR/renamed-models.json" \
  "$SPEC_DIR/$SPEC_NAME"

rm -rf "$OUTPUT_DIR"
# immutable_models makes model properties `let` and the models checked
# Sendable.
# number_as_float keeps JSON numbers as Float. The generator defaults to Double
# since Float truncates float64s, but our generated models are public, so
# widening them would be a source and binary break.
# string_coding_keys replaces the CodingKeys enum of each model with one
# shared StringCodingKey type, which reduces binary size.
"$OPENAPI_BIN" generate-client \
  --language swift \
  --spec "$SPEC_DIR/$SPEC_NAME" \
  --opt immutable_models=true \
  --opt number_as_float=true \
  --opt string_coding_keys=true \
  --output "$OUTPUT_DIR/"

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
remove_properties
retype_properties
remove_enum_cases

# Run last, so models and keys only the removed properties used go too.
remove_unused_models
apply_coding_directions
remove_unused_string_coding_keys

# format the generated code, .swiftformat excludes it by default
swiftformat --unexclude "$OUTPUT_DIR" "$OUTPUT_DIR"
