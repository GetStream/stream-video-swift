// swift-tools-version:5.6

import Foundation
import PackageDescription

let package = Package(
    name: "StreamVideo",
    defaultLocalization: "en",
    platforms: [
        .iOS(.v13), .macOS(.v11)
    ],
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
        .package(name: "WebRTC", url: "https://github.com/webrtc-sdk/Specs.git", .exact("114.5735.4")),
        .package(url: "https://github.com/kean/Nuke.git", .exact("11.3.1")),
        .package(url: "https://github.com/apple/swift-protobuf.git", from: "1.18.0")
    ],
    targets: [
        .target(
            name: "StreamVideo",
            dependencies: ["WebRTC", .product(name: "SwiftProtobuf", package: "swift-protobuf")]
        ),
        .target(
            name: "StreamVideoSwiftUI",
            dependencies: ["StreamVideo", "Nuke", .product(name: "NukeUI", package: "Nuke")],
            resources: [.process("Resources")]
        ),
        .target(
            name: "StreamVideoUIKit",
            dependencies: ["StreamVideo", "StreamVideoSwiftUI", "Nuke", .product(name: "NukeUI", package: "Nuke")],
            resources: [.process("Resources")]
        )
    ]
)
