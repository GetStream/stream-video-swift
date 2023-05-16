Pod::Spec.new do |spec|
  spec.name = "StreamVideoUIKit"
  spec.version = "0.0.1"
  spec.summary = "StreamVideo UIKit Video Components"
  spec.description = "StreamVideoUIKit SDK offers flexible UIKit components able to display data provided by StreamVideo SDK."

  spec.homepage = "https://getstream.io/video/"
  spec.license = { type: "BSD-3", file: "LICENSE" }
  spec.author = { "getstream.io" => "support@getstream.io" }
  spec.social_media_url = "https://getstream.io"

  spec.swift_version = "5.2"
  spec.platform = :ios, "14.0"
  spec.requires_arc = true

  spec.framework = "Foundation", "UIKit"
  spec.module_name = spec.name
  spec.source = { git: "https://github.com/GetStream/stream-video-swift.git", tag: spec.version }
  spec.source_files = ["Sources/#{spec.name}/**/*.swift"]
  spec.exclude_files = ["Sources/#{spec.name}/**/*_Tests.swift", "Sources/#{spec.name}/**/*_Mock.swift"]

  spec.dependency("StreamVideo", spec.version)
  spec.dependency("Nuke", "10.7.1")
  spec.dependency("NukeUI", "0.8.0")
end
