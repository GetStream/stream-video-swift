# stream-video-swiftui
Repo for Stream Video in SwiftUI.

# Introduction

For now, this repo contains the following parts:
- twirp code generation tool
- possibility to create Swift protobufs from the backend repo
- LiveKit wrapper
- Sample app using LiveKit
- Sample app using lower level WebRTC client

### Twirp code generation tool

This tool creates async/await versions of all the twirp service methods in the CallCoordinatorService from the backend.

It's written in go, so if you want to change something, you will need to open client.go in `DemoApp/protobuf/twirp/generator and run:
```
go build
```
This will generate another executable, with the name `protoc-gen-swiftwirp` that you can use to create protobufs.

### Create Swift protobufs

In order to create Swift protobufs, you will need to first setup the Swift code generator plugin, as described here: https://github.com/apple/swift-protobuf.

Make sure that you have copied the latest proto files from the backend repo. At the moment, the following folders are copied:
- video_coordinator_rpc
- validate
- video_models
- video_events

These folders contain .proto files, which will be converted to .swift files. In the future, we can also load them as gitmodules, to automate the process.

Next, you will need to cd to `DemoApp/protobuf` and run `generate.sh`:
```
./generate.sh
```
This will create the .swift files. The ones from the folders above are already automatically added in the Xcode project.

//TODO: WIP
