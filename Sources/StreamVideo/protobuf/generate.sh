#! /bin/bash
cp -r `find ../../../sfu/protobuf/** -type d` .
protoc --swift_opt=FileNaming=PathToUnderscores --swift_out=. **/*.proto
protoc --swift_out=:. --swiftwirp_out=:. --plugin="twirp/protoc-gen-swiftwirp"  **/*signal.proto
mv **/*twirp.swift .
for folder in `find ../../../sfu/protobuf/** -type d`
do
	rm -rf `basename $folder`
done