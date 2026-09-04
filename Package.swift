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
        .package(url: "https://github.com/GetStream/stream-video-swift-webrtc.git", exact: "145.15.0"),
        // Temporary pin to the develop commit that added StreamCoreUI
        // fonts. Restore `from:` once they ship in a tag.
        .package(
            url: "https://github.com/GetStream/stream-core-swift.git",
            revision: "fecb30ec066d29b4fd4acd3d9b6039558057d91f"
        )
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
            dependencies: [
                "StreamVideo",
                .product(name: "StreamCoreUI", package: "stream-core-swift")
            ],
            resources: [
                .process("Resources")
            ]
        ),
        .target(
            name: "StreamVideoUIKit",
            dependencies: ["StreamVideo", "StreamVideoSwiftUI"]
        )
    ]
)
