//
// Copyright © 2024 Stream.io Inc. All rights reserved.
//

import StreamVideo
import SwiftUI

public struct CallBackground: View {
    
    var imageURL: URL?
    
    public init(imageURL: URL? = nil) {
        self.imageURL = imageURL
    }
    
    public var body: some View {
        CallParticipantBackground(imageURL: imageURL) {
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
                Color(red: 60/255, green: 64/255, blue: 72/255),
                Color(red: 30/255, green: 33/255, blue: 36/255)
            ],
            startPoint: .top,
            endPoint: .bottom
        )
    }
}

struct CallParticipantBackground<Background: View>: View {
    
    var imageURL: URL?
    var fallbackBackground: () -> Background
    
    var body: some View {
        ZStack {
            if #available(iOS 14.0, *), let imageURL = imageURL {
                StreamLazyImage(imageURL: imageURL) {
                    fallbackBackground()
                }
                .frame(maxWidth: .infinity, maxHeight: .infinity)
                .blur(radius: 8)
                .clipped()
            } else {
                fallbackBackground()
            }
        }
        .edgesIgnoringSafeArea(.all)
        .background(fallbackBackground())
    }
}
