#!/usr/bin/env bash

set -e

PROJECT_ROOT=$(pwd)
OPENAPI_GENERATED_CODE_ROOT="${PROJECT_ROOT}/Sources/StreamVideo/OpenApi/generated"

# delete all files in the target path of openapi to make sure we do not leave legacy code around
echo rm -rf "${OPENAPI_GENERATED_CODE_ROOT}"

docker run --rm -v "${OPENAPI_GENERATED_CODE_ROOT}:/local" \
   ghcr.io/getstream/openapi-generator:master \
   generate -g swift5 \
   -i https://raw.githubusercontent.com/GetStream/protocol/main/openapi/video-openapi.yaml \
   -o /local/tmp \
   --skip-validate-spec \
   --additional-properties=nonPublicApi=true

# copy only the files that we care about from /tmp into project

# delete the tmp path
echo rm -rf "${OPENAPI_GENERATED_CODE_ROOT}/tmp"

# TODO: use git diff to add/remove files to the project file

