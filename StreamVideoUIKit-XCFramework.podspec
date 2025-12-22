Pod::Spec.new do |spec|
  spec.name = 'StreamVideoUIKit-XCFramework'
  spec.version = '1.38.2'
  spec.summary = 'StreamVideo UIKit Video Components'
  spec.description = 'StreamVideoUIKit SDK offers flexible UIKit components able to display data provided by StreamVideo SDK.'

  spec.homepage = 'https://getstream.io/video/'
  spec.license = { type: 'Proprietary', file: 'LICENSE' }
  spec.author = { 'getstream.io' => 'support@getstream.io' }
  spec.social_media_url = 'https://getstream.io'

  spec.swift_version = '5.9'
  spec.platform = :ios, '13.0'
  spec.requires_arc = true

  spec.framework = 'Foundation', 'UIKit'

  spec.module_name = 'StreamVideoUIKit'
  spec.source = { http: "https://github.com/GetStream/stream-video-swift/releases/download/#{spec.version}/#{spec.module_name}.zip" }
  spec.vendored_frameworks = "#{spec.module_name}.xcframework"
  spec.preserve_paths = "#{spec.module_name}.xcframework/*"

  spec.dependency('StreamVideo-XCFramework', "#{spec.version}")
  spec.dependency('StreamVideoSwiftUI-XCFramework', "#{spec.version}")
end
