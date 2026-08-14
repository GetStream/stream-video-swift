#!/usr/bin/env bash

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
PROJECT_ROOT="$(cd "$SCRIPT_DIR/.." && pwd)"
SOURCE_PATH="$(cd "$PROJECT_ROOT/../chat" && pwd)"

if [ ! -d "$SOURCE_PATH" ]
then
  echo "cannot find chat path on the parent folder (${SOURCE_PATH}), do you have a copy of the API source?";
  exit 1;
fi

set -ex

# remove old generated code
rm -rf "$PROJECT_ROOT/Sources/StreamVideo/OpenApi/generated/Models/"*

# cd into chat-manager module dir so go run can find go.mod, use absolute paths for outputs
(
  cd "$SOURCE_PATH/projects/chat-manager" &&
  go run . openapi generate-spec -products video -version v2 -clientside -output "$SOURCE_PATH/releases/v2/video-openapi-clientside" -renamed-models "$SCRIPT_DIR/renamed-models.json" &&
  # number_as_float keeps JSON numbers as Float. The generator defaults to Double
  # since Float truncates float64s, but our generated models are public, so
  # widening them would be a source and binary break.
  go run . openapi generate-client --language swift --spec "$SOURCE_PATH/releases/v2/video-openapi-clientside.yaml" --opt number_as_float=true --output "$PROJECT_ROOT/Sources/StreamVideo/OpenApi/generated/"
)

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

# format the generated code
swiftformat Sources/StreamVideo/OpenApi/generated
