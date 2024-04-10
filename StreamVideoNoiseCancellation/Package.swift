// swift-tools-version: 5.10
// The swift-tools-version declares the minimum version of Swift required to build this package.

import PackageDescription

let package = Package(
    name: "StreamVideoNoiseCancellation",
    platforms: [
      .iOS(.v13),
      .macOS(.v11)
    ],
    products: [
        .library(
            name: "StreamVideoNoiseCancellation",
            targets: ["StreamVideoNoiseCancellation"]),
    ],
    dependencies: [
        .package(
            url: "https://github.com/GetStream/stream-video-swift-webrtc.git",
            exact: "114.5735.08"
        )
    ],
    targets: [
        .target(
            name: "StreamVideoNoiseCancellation",
            dependencies: [
                "StreamKrispModels",
                "StreamKrispPlugin",
                .product(name: "StreamWebRTC", package: "stream-video-swift-webrtc")
            ]
        ),

        .target(
            name: "StreamKrispModels",
            resources: [.process("Models")]
        ),

        .target(
            name: "StreamKrispPlugin",
            dependencies: [
                "KrispAudioSDK",
                .product(name: "StreamWebRTC", package: "stream-video-swift-webrtc")
            ],
            publicHeadersPath:"include"
        ),

        .binaryTarget(
            name: "KrispAudioSDK",
            path: "Frameworks/KrispAudioSDK.xcframework"
        )
    ],
    cxxLanguageStandard: .cxx14
)
