//
// Copyright © 2022 Stream.io Inc. All rights reserved.
//

import NukeUI
import StreamVideo
import SwiftUI

struct CallParticipantImageView: View {
    
    @Injected(\.colors) var colors
    
    var id: String
    var name: String
    var imageURL: URL?
    
    private let size: CGFloat = 138
    
    var body: some View {
        ZStack {
            if let imageURL = imageURL {
                LazyImage(source: imageURL)
                    .aspectRatio(contentMode: .fill)
                    .frame(maxWidth: .infinity, maxHeight: .infinity)
                    .blur(radius: 8)
                    .clipped()
                    
                LazyImage(source: imageURL)
                    .aspectRatio(contentMode: .fit)
                    .frame(width: size, height: size)
                    .clipShape(Circle())
                
            } else {
                Color(colors.callBackground)
                // TODO: make this safe
                CircledTitleView(
                    title: name.isEmpty ? id : String(name.uppercased().first!),
                    size: size
                )
            }
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
    }
}
