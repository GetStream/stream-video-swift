#!/bin/bash

# Exit immediately if a command exits with a non-zero status.
set -e

# Define an array of paths
paths=("Sources" "DemoApp" "DemoAppUIKit")

# Loop through each path
for path in "${paths[@]}"; do
    mint run swiftformat --lint --config .swiftformat \
        --exclude "**/Generated","**/generated","**/protobuf","**/OpenApi","**/Nuke*" \
        "$path"
done