//
// Copyright © 2026 Stream.io Inc. All rights reserved.
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

struct FallbackBackground: View {
        
    var body: some View {
        DefaultBackgroundGradient()
            .aspectRatio(contentMode: .fill)
            .edgesIgnoringSafeArea(.all)
    }
}

struct DefaultBackgroundGradient: View {
    
    var body: some View {
        LinearGradient(
            colors: [
                Color(red: 60 / 255, green: 64 / 255, blue: 72 / 255),
                Color(red: 30 / 255, green: 33 / 255, blue: 36 / 255)
            ],
            startPoint: .top,
            endPoint: .bottom
        )
    }
}
