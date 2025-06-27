//
// Copyright © 2025 Stream.io Inc. All rights reserved.
//

import StreamVideo
import SwiftUI

public struct CallBackground: View {
    
    var imageURL: URL?
    
    public init(imageURL: URL? = nil) {
        self.imageURL = imageURL
    }
    
    public var body: some View {
        StreamLazyImage(imageURL: imageURL) {
            FallbackBackground()
        }
    }
}
