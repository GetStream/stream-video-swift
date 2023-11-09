Pod::Spec.new do |spec|
  spec.name = 'StreamVideo-XCFramework'
  spec.version = '0.4.1'
  spec.summary = 'StreamVideo iOS Video Client'
  spec.description = 'StreamVideo is the official Swift client for Stream Video, a service for building video applications.'

  spec.homepage = 'https://getstream.io/video/'
  spec.license = { type: 'BSD-3', file: 'LICENSE' }
  spec.author = { 'getstream.io' => 'support@getstream.io' }
  spec.social_media_url = 'https://getstream.io'

  spec.swift_version = '5.6'
  spec.platform = :ios, '13.0'
  spec.requires_arc = true

  spec.framework = 'Foundation'

  spec.module_name = "StreamVideo"
  spec.source = { :http => "https://github.com/GetStream/stream-video-swift/releases/download/#{spec.version}/#{spec.module_name}.zip" }
  spec.vendored_frameworks = "#{spec.module_name}.xcframework"
  spec.preserve_paths = "#{spec.module_name}.xcframework/*"

  spec.dependency('SwiftProtobuf', '~> 1.18.0')

  spec.cocoapods_version = ">= 1.11.0"
end
