# Stream Video iOS
Repo for Stream Video on iOS.

# Introduction

This repo contains the following parts:
- low-level client for video
- SwiftUI SDK
- Demo app example

Additionally, there's an empty (for now), UIKit SDK. We will either provide a UIKit wrapper around the SwiftUI SDK, or build a new native one in the future.

### Swift protobuf and twirp code

The backend APIs consist of two parts:
- coordinator API, for determining which edge server to use for connecting to a call
- SFU (Selective Forwarding Unit) - used for performing the video call

We use protobufs and twirp for communicating with these APIs. The Swift protobufs are generated and integrated in the Xcode project.

For the coordinator API, the protobufs are located at our internal (video-proto)[https://github.com/GetStream/video-proto] repo. Follow the steps there if you want to generate newer version of these files. The generated files are part of the versioning control and all updates related to them should be pushed.

For the SFU API, at the moment, the Swift protobufs are in two parts (this is not ideal and will be addressed by the backend team). The first part, can be found in the same video-proto repo from above. The second part, needs still to be generated locally on this repo. In order to do this, you need to copy the latest files from the (SFU repo)[https://github.com/GetStream/video-sfu], in the protobuf folder. 

After you copy these files, you need to run the local generate.sh script, which can be found at `Sources/StreamVideo/protobuf`. 

```
./generate.sh
```

This will create the .swift files. The ones from the folders above are already automatically added in the Xcode project. If you create new ones, you would need to explicitly add them to the Xcode project, only the first time.

This creates async/await versions of all the twirp service methods in the SFU. It's written in go, so if you want to change something, you will need to open client.go in `Sources/StreamVideo/protobuf/twirp/generator` and run:
```
go build
```
This will generate another executable, with the name `protoc-gen-swiftwirp` that you can use to create protobufs.

In order to create Swift protobufs, you will need to first setup the Swift code generator plugin, as described here: https://github.com/apple/swift-protobuf.

### Sample app

The sample app integrates the low-level client and the SwiftUI UI components. In the app, you can test the following:
- full flow, consisting of edge selection (coordinator API) and call establishing. If you test with multiple devices, make sure that you use the same call id for all of them. The coordinator API is still not deployed anywhere. In order to test it, you will need to run it locally. In that case, make sure to change the `192.168.0.132` IP address with your own one. In order to invoke this flow, press the button `Start call`.
- test only the SFU, which already has a deployed test instance. You can invoke this flow by pressing the "Test SFU" button (no local server setup is required for this test).