Pod::Spec.new do |spec|
  spec.name = 'StreamVideoSwiftUI-XCFramework'
  spec.version = '1.38.0'
  spec.summary = 'StreamVideo SwiftUI Video Components'
  spec.description = 'StreamVideoSwiftUI SDK offers flexible SwiftUI components able to display data provided by StreamVideo SDK.'

  spec.homepage = 'https://getstream.io/video/'
  spec.license = { type: 'Proprietary', file: 'LICENSE' }
  spec.author = { 'getstream.io' => 'support@getstream.io' }
  spec.social_media_url = 'https://getstream.io'

  spec.swift_version = '5.10'
  spec.platform = :ios, '13.0'
  spec.requires_arc = true

  spec.framework = 'Foundation', 'SwiftUI'

  spec.module_name = 'StreamVideoSwiftUI'
  spec.source = { http: "https://github.com/GetStream/stream-video-swift/releases/download/#{spec.version}/#{spec.module_name}.zip" }
  spec.vendored_frameworks = "#{spec.module_name}.xcframework"
  spec.preserve_paths = "#{spec.module_name}.xcframework/*"

  spec.dependency('StreamVideo-XCFramework', spec.version.to_s)
end
