//
// Copyright © 2026 Stream.io Inc. All rights reserved.
//

import Foundation

extension Bundle {
    
    private final class StreamVideoTestResources {}
    
    static let bundleName = "StreamVideo_StreamVideoTestResources"
    
    static let testResources: Bundle = {
        let candidates = [
            // Bundle should be present here when the package is linked into an App.
            Bundle.main.resourceURL,
            
            // Bundle should be present here when the package is linked into a framework.
            Bundle(for: StreamVideoTestResources.self).resourceURL,
            
            // For command-line tools.
            Bundle.main.bundleURL
        ]

        for candidate in candidates {
            let bundlePath = candidate?.appendingPathComponent(bundleName + ".bundle")
            if let bundle = bundlePath.flatMap(Bundle.init(url:)) {
                return bundle
            }
        }
        return Bundle(for: StreamVideoTestResources.self)
    }()
}
