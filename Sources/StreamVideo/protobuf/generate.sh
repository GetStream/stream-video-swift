#! /bin/bash

protoc --swift_opt=FileNaming=DropPath --swift_out=. **/*.proto
protoc --swift_out=:. --swiftwirp_out=:. --plugin="twirp/protoc-gen-swiftwirp"  **/*service.proto
mv **/*twirp.swift .