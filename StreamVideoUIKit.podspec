Pod::Spec.new do |spec|
  spec.name = 'StreamVideoUIKit'
  spec.version = '1.38.1'
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
  spec.module_name = spec.name
  spec.source = { git: 'https://github.com/GetStream/stream-video-swift.git', tag: spec.version }
  spec.source_files = ["Sources/#{spec.name}/**/*.swift"]
  spec.exclude_files = ["Sources/#{spec.name}/**/*_Tests.swift", "Sources/#{spec.name}/**/*_Mock.swift"]

  spec.dependency('StreamVideo', "#{spec.version}")
  spec.dependency('StreamVideoSwiftUI', "#{spec.version}")
end
