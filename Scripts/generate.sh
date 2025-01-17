#!/usr/bin/env bash

SOURCE_PATH=../chat

if [ ! -d $SOURCE_PATH ]
then
  echo "cannot find chat path on the parent folder (${SOURCE_PATH}), do you have a copy of the API source?";
  exit 1;
fi

set -ex

# remove old generated code
rm -rf ./Sources/StreamVideo/OpenApi/generated/Models/*

# cd in API repo, generate new spec and then generate code from it
(
  cd $SOURCE_PATH &&
  go run ./cmd/chat-manager openapi generate-spec -products video -version v1 -clientside -output releases/video-openapi-clientside -renamed-models ../stream-video-swift/Scripts/renamed-models.json &&
  go run ./cmd/chat-manager openapi generate-client --language swift --spec ./releases/video-openapi-clientside.yaml --output ../stream-video-swift/Sources/StreamVideo/OpenApi/generated/
)

# format the generated code
mint run swiftformat Sources/StreamVideo/OpenApi/generated
