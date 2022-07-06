# Stream Video iOS
Repo for Stream Video on iOS.

# Introduction

For now, this repo contains the following parts:
- twirp code generation tool
- possibility to create Swift protobufs from the backend repo
- LiveKit wrapper
- Sample app using LiveKit
- Sample app using lower level WebRTC client

### Twirp code generation tool

This tool creates async/await versions of all the twirp service methods in the CallCoordinatorService from the backend.

It's written in go, so if you want to change something, you will need to open client.go in `DemoApp/protobuf/twirp/generator` and run:
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
This will create the .swift files. The ones from the folders above are already automatically added in the Xcode project. If you create new ones, you would need to explicitly add them to the Xcode project, only the first time.

### Sample app

The project contains a sample app, with LiveKit integration. There are two users available, that you can use to test video calls.

The sample does edge server selection in the background, with the generated twirp async/await methods from above.
```swift
     func selectEdgeServer() {
        Task {
            let selectEdgeRequest = Stream_Video_SelectEdgeServerRequest()
            let response = try await callCoordinatorService.selectEdgeServer(selectEdgeServerRequest: selectEdgeRequest)
            url = "wss://\(response.edgeServer.url)"
        }
     }
```
At the moment, you need to setup the server on your local machine. In order to do this, follow the guide from the backend repo: https://github.com/GetStream/video.

After you have the server up and running, you can test the edge server selection.

If you test the video call, you will need to explicitly open the video camera, by tapping the camera icon, it's disabled by default (for now).

### WebRTC sample app

In the `old` folder, there's another sample app, that doesn't use LiveKit, but a low-level WebRTC implementation. You can also try it out, by running a node.js server, but for now it will be just used as a reference (or maybe deleted).
