#!/usr/bin/env bash

set -e

PROJECT_ROOT=$(pwd)
OPENAPI_GENERATED_CODE_ROOT="${PROJECT_ROOT}/Sources/StreamVideo/OpenApi/generated"

# use something like this if you want to work on custom openapi spec and templates
#docker run --rm -v "${OPENAPI_GENERATED_CODE_ROOT}:/local" \
#   -v "/Users/tommaso/src/protocol/openapi:/openapi" \
#   -v "/Users/tommaso/src/openapi-generator/modules/openapi-generator/src/main/resources:/templates" \
#   ghcr.io/getstream/openapi-generator:master \
#   generate -g swift5 \
#   -i /openapi/video-openapi.yaml \
#   -t /templates/swift5 \
#   -o /local/tmp \
#   --skip-validate-spec \
#   --additional-properties=nonPublicApi=true \
#   --additional-properties=responseAs=AsyncAwait

# build openapi using latest manifest available
docker run --rm -v "${OPENAPI_GENERATED_CODE_ROOT}:/local" \
   ghcr.io/getstream/openapi-generator:master \
   generate -g swift5 \
   -i /openapi/video-openapi.yaml \
   -t /templates/swift5 \
   -o /local/tmp \
   --skip-validate-spec \
   --additional-properties=nonPublicApi=true \
   --additional-properties=responseAs=AsyncAwait

# move generated code from tmp to generated code root path
rm -rf ${OPENAPI_GENERATED_CODE_ROOT}/APIs
rm -rf ${OPENAPI_GENERATED_CODE_ROOT}/Models
rm -rf ${OPENAPI_GENERATED_CODE_ROOT}/*.swift

cp ${OPENAPI_GENERATED_CODE_ROOT}/tmp/OpenAPIClient/Classes/OpenAPIs/*.swift ${OPENAPI_GENERATED_CODE_ROOT}
rm ${OPENAPI_GENERATED_CODE_ROOT}/URLSessionImplementations.swift
mv ${OPENAPI_GENERATED_CODE_ROOT}/tmp/OpenAPIClient/Classes/OpenAPIs/APIs ${OPENAPI_GENERATED_CODE_ROOT}
mv ${OPENAPI_GENERATED_CODE_ROOT}/tmp/OpenAPIClient/Classes/OpenAPIs/Models ${OPENAPI_GENERATED_CODE_ROOT}

# delete the tmp path
rm -rf "${OPENAPI_GENERATED_CODE_ROOT}/tmp"
