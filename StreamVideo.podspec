Pod::Spec.new do |spec|
  spec.name = 'StreamVideo'
  spec.version = '1.38.1'
  spec.summary = 'StreamVideo iOS Video Client'
  spec.description = 'StreamVideo is the official Swift client for Stream Video, a service for building video applications.'

  spec.homepage = 'https://getstream.io/video/'
  spec.license = { type: 'Proprietary', file: 'LICENSE' }
  spec.author = { 'getstream.io' => 'support@getstream.io' }
  spec.social_media_url = 'https://getstream.io'

  spec.swift_version = '5.10'
  spec.platform = :ios, '13.0'
  spec.requires_arc = true

  spec.framework = 'Foundation'

  spec.module_name = spec.name
  spec.source = { git: 'https://github.com/GetStream/stream-video-swift.git', tag: spec.version }
  spec.source_files = ["Sources/#{spec.name}/**/*.swift"]
  spec.exclude_files = ["Sources/#{spec.name}/**/*_Tests.swift", "Sources/#{spec.name}/**/*_Mock.swift"]

  spec.dependency('SwiftProtobuf', '~> 1.29')
  spec.vendored_frameworks = 'Frameworks/StreamWebRTC.xcframework'

  spec.prepare_command = <<-CMD
    mkdir -p Frameworks/
    curl -sL "https://github.com/GetStream/stream-video-swift-webrtc/releases/download/137.0.54/StreamWebRTC.xcframework.zip" -o Frameworks/StreamWebRTC.zip
    unzip -o Frameworks/StreamWebRTC.zip -d Frameworks/
    rm Frameworks/StreamWebRTC.zip
  CMD

  spec.pod_target_xcconfig = { 'SWIFT_OPTIMIZATION_LEVEL' => '-Osize' }
end
