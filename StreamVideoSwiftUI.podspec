Pod::Spec.new do |spec|
  spec.name = 'StreamVideoSwiftUI'
  spec.version = '0.0.8'
  spec.summary = 'StreamVideo SwiftUI Video Components'
  spec.description = 'StreamVideoSwiftUI SDK offers flexible SwiftUI components able to display data provided by StreamVideo SDK.'

  spec.homepage = 'https://getstream.io/video/'
  spec.license = { type: 'BSD-3', file: 'LICENSE' }
  spec.author = { 'getstream.io' => 'support@getstream.io' }
  spec.social_media_url = 'https://getstream.io'

  spec.swift_version = '5.2'
  spec.platform = :ios, '14.0'
  spec.requires_arc = true

  spec.framework = 'Foundation', 'SwiftUI'
  spec.module_name = spec.name
  spec.source = { git: 'https://github.com/GetStream/stream-video-swift.git', tag: spec.version.to_s }
  spec.source_files = ["Sources/#{spec.name}/**/*.swift"]
  spec.exclude_files = ["Sources/#{spec.name}/**/*_Tests.swift", "Sources/#{spec.name}/**/*_Mock.swift"]
  spec.resource_bundles = { spec.name => ["Sources/#{spec.name}/Resources/**/*"] }

  spec.dependency('StreamVideo', spec.version.to_s)
  spec.dependency('Nuke', '10.7.1')
  spec.dependency('NukeUI', '0.8.0')
end
