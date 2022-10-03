//
// Copyright © 2022 Stream.io Inc. All rights reserved.
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
        Image("incomingCallBackground")
            .resizable()
            .aspectRatio(contentMode: .fill)
            .edgesIgnoringSafeArea(.all)
    }
}

struct CallParticipantBackground<Background: View>: View {
    
    var imageURL: URL?
    var fallbackBackground: () -> Background
    
    var body: some View {
        ZStack {
            if let imageURL = imageURL {
                LazyImage(url: imageURL)
                    .aspectRatio(contentMode: .fill)
                    .frame(maxWidth: .infinity, maxHeight: .infinity)
                    .blur(radius: 8)
                    .clipped()
            } else {
                fallbackBackground()
            }
        }
        .edgesIgnoringSafeArea(.all)
    }
}
