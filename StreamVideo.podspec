Pod::Spec.new do |spec|
  spec.name = "StreamVideo"
  spec.version = "0.0.1"
  spec.summary = "StreamVideo iOS Video Client"
  spec.description = "stream-video-swift is the official Swift client for Stream Video, a service for building video applications."

  spec.homepage = "https://getstream.io/video/"
  spec.license = { type: "BSD-3", file: "LICENSE" }
  spec.author = { "getstream.io" => "support@getstream.io" }
  spec.social_media_url = "https://getstream.io"

  spec.swift_version = "5.2"
  spec.platform = :ios, "14.0"
  spec.requires_arc = true

  spec.framework = "Foundation"
  spec.module_name = spec.name
  spec.source = { git: "https://github.com/GetStream/stream-video-swift.git", tag: spec.version }
  spec.source_files = ["Sources/StreamVideo/**/*.swift"]
  spec.exclude_files = ["Sources/StreamVideo/**/*_Tests.swift", "Sources/StreamVideo/**/*_Mock.swift"]

  spec.dependency("SwiftProtobuf", "~> 1.18.0")
  spec.dependency("WebRTC-SDK", "104.5112.11")
end
