//
// Copyright © 2026 Stream.io Inc. All rights reserved.
//

import StreamCoreUI
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

struct FallbackBackground: View {

    @Injected(\.colors) var colors

    var body: some View {
        Color(colors.backgroundCoreScrim)
            .aspectRatio(contentMode: .fill)
            .edgesIgnoringSafeArea(.all)
    }
}
