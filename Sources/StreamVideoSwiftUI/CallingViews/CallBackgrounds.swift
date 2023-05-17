//
// Copyright © 2023 Stream.io Inc. All rights reserved.
//

import NukeUI
import StreamVideo
import SwiftUI

struct CallingScreenBackground: View {
    
    var imageURL: URL?
    
    var body: some View {
        CallParticipantBackground(imageURL: imageURL) {
            FallbackBackground()
        }
    }
}

struct FallbackBackground: View {
        
    var body: some View {
        LinearGradient(
            colors: [
                Color(red: 60/255, green: 64/255, blue: 72/255),
                Color(red: 30/255, green: 33/255, blue: 36/255)
            ],
            startPoint: .top,
            endPoint: .bottom
        )
        .aspectRatio(contentMode: .fill)
        .edgesIgnoringSafeArea(.all)
    }
}

struct CallParticipantBackground<Background: View>: View {
    
    var imageURL: URL?
    var fallbackBackground: () -> Background
    
    var body: some View {
        ZStack {
            if #available(iOS 14.0, *), let imageURL = imageURL {
                LazyImage(source: imageURL)
                    .aspectRatio(contentMode: .fill)
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
