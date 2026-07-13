// swift-tools-version:5.10

import Foundation
import PackageDescription

let package = Package(
    name: "StreamVideo",
    defaultLocalization: "en",
    platforms: [.iOS(.v13)],
    products: [
        .library(
            name: "StreamVideo",
            targets: ["StreamVideo"]
        ),
        .library(
            name: "StreamVideoSwiftUI",
            targets: ["StreamVideoSwiftUI"]
        ),
        .library(
            name: "StreamVideoUIKit",
            targets: ["StreamVideoUIKit"]
        )
    ],
    dependencies: [
        .package(url: "https://github.com/apple/swift-protobuf.git", exact: "1.30.0"),
        .package(url: "https://github.com/GetStream/stream-video-swift-webrtc.git", exact: "145.8.0"),
        // Shared low-level SDK. Provides the logger, WebSocket client, error
        // model, etc. that StreamVideo is migrating onto.
        .package(url: "https://github.com/GetStream/stream-core-swift.git", branch: "develop")
    ],
    targets: [
        .target(
            name: "StreamVideo",
            dependencies: [
                .product(name: "SwiftProtobuf", package: "swift-protobuf"),
                .product(name: "StreamWebRTC", package: "stream-video-swift-webrtc"),
                .product(name: "StreamCore", package: "stream-core-swift")
            ]
        ),
        .target(
            name: "StreamVideoSwiftUI",
            // Links StreamCore directly: StreamVideo's public logger types are
            // now typealiases to StreamCore's, so this module references
            // StreamCore symbols (e.g. `LogSubsystem`, `Publisher.log`) at link
            // time even though it only imports StreamVideo.
            dependencies: [
                "StreamVideo",
                .product(name: "StreamCore", package: "stream-core-swift")
            ],
            resources: [
                .process("Resources")
            ]
        ),
        .target(
            name: "StreamVideoUIKit",
            // Links StreamCore for the same reason as StreamVideoSwiftUI.
            dependencies: [
                "StreamVideo",
                "StreamVideoSwiftUI",
                .product(name: "StreamCore", package: "stream-core-swift")
            ]
        )
    ]
)
