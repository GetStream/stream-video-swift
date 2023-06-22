#!/usr/bin/env bash

set -e

PROJECT_ROOT=$(pwd)
OPENAPI_GENERATED_CODE_ROOT="${PROJECT_ROOT}/Sources/StreamVideo/OpenApi/generated"
PROTOBUF_GENERATED_CODE_ROOT="${PROJECT_ROOT}/Sources/StreamVideo/protobuf"

# use something like this if you want to work on custom openapi spec and templates
#docker run --rm -v "${OPENAPI_GENERATED_CODE_ROOT}:/local" \
#   -v "/Users/tommaso/src/protocol/openapi:/openapi" \
#   -v "/Users/tommaso/src/openapi-generator/modules/openapi-generator/src/main/resources:/templates" \
#   openapidev \
#   generate -g swift5 \
#   -i /openapi/video-openapi-clientside.yaml \
#   -t /templates/swift5 \
#   -o /local/tmp \
#   --skip-validate-spec \
#   --additional-properties=responseAs=AsyncAwait

# build openapi using latest manifest available
docker pull ghcr.io/getstream/openapi-generator:master

docker run --rm -v "${OPENAPI_GENERATED_CODE_ROOT}:/local" \
   -v "/Users/tommaso/src/protocol/openapi:/openapi" \
   -v "/Users/tommaso/src/openapi-generator/modules/openapi-generator/src/main/resources:/templates" \
   ghcr.io/getstream/openapi-generator:master \
   generate -g swift5 \
   -t /templates/swift5 \
   -i /openapi/video-openapi-clientside.yaml \
   -o /local/tmp \
   --skip-validate-spec \
   --additional-properties=responseAs=AsyncAwait

# move generated code from tmp to generated code root path
rm -rf ${OPENAPI_GENERATED_CODE_ROOT}/APIs/*
rm -rf ${OPENAPI_GENERATED_CODE_ROOT}/Models
rm -rf ${OPENAPI_GENERATED_CODE_ROOT}/*.swift

cp ${OPENAPI_GENERATED_CODE_ROOT}/tmp/OpenAPIClient/Classes/OpenAPIs/*.swift ${OPENAPI_GENERATED_CODE_ROOT}
cp ${OPENAPI_GENERATED_CODE_ROOT}/tmp/OpenAPIClient/Classes/OpenAPIs/APIs/DefaultAPI.swift ${OPENAPI_GENERATED_CODE_ROOT}/APIs/
mv ${OPENAPI_GENERATED_CODE_ROOT}/tmp/OpenAPIClient/Classes/OpenAPIs/Models ${OPENAPI_GENERATED_CODE_ROOT}

# delete the tmp path
rm -rf "${OPENAPI_GENERATED_CODE_ROOT}/tmp"

# pull latest image to generate code from protobuf
docker pull ghcr.io/getstream/protobuf-generate:latest

# run code-gen and put everything under tmp path
docker run --rm -v "${PROTOBUF_GENERATED_CODE_ROOT}:/local" \
    ghcr.io/getstream/protobuf-generate:latest swift /local/tmp

# delete old sfu generated code
rm -rf ${PROTOBUF_GENERATED_CODE_ROOT}/sfu

# put back what we care about
mv ${PROTOBUF_GENERATED_CODE_ROOT}/tmp/video/sfu ${PROTOBUF_GENERATED_CODE_ROOT}
