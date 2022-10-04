// swift-tools-version:5.3
// When used via SPM the minimum Swift version is 5.3 because we need support for resources

import Foundation
import PackageDescription

let package = Package(
    name: "StreamVideo",
    defaultLocalization: "en",
    platforms: [
        .iOS(.v14), .macOS(.v11)
    ],
    products: [
        .library(
            name: "StreamVideo",
            targets: ["StreamVideo"]
        ),
        .library(
            name: "StreamVideoSwiftUI",
            targets: ["StreamVideoSwiftUI"]
        )
    ],
    dependencies: [
        .package(name: "WebRTC", url: "https://github.com/webrtc-sdk/Specs.git", .exact("104.5112.2")),
        .package(url: "https://github.com/kean/Nuke.git", .exact("11.3.0")),
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
        )
    ]
)
