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
  go run . openapi generate-client --language swift --spec "$SOURCE_PATH/releases/v2/video-openapi-clientside.yaml" --output "$PROJECT_ROOT/Sources/StreamVideo/OpenApi/generated/"
)

# format the generated code
swiftformat Sources/StreamVideo/OpenApi/generated
