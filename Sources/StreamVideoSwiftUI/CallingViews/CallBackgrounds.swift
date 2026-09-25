//
// Copyright © 2026 Stream.io Inc. All rights reserved.
//

import StreamCoreUI
import StreamVideo
import SwiftUI

public struct CallBackground: View {
    
    @Injected(\.videoAppearance) var videoAppearance
    
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

    @Injected(\.videoAppearance) var videoAppearance

    var body: some View {
        Color(videoAppearance.tokens.colors.backgroundCoreScrim)
            .aspectRatio(contentMode: .fill)
            .edgesIgnoringSafeArea(.all)
    }
}
