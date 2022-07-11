#! /bin/bash
cp -r `find backend/protobuf/** -type d` .
protoc --swift_opt=FileNaming=DropPath --swift_out=. **/*.proto
protoc --swift_out=:. --swiftwirp_out=:. --plugin="twirp/protoc-gen-swiftwirp"  **/*service.proto
mv **/*twirp.swift .
for folder in `find backend/protobuf/** -type d`
do
	rm -rf `basename $folder`
done