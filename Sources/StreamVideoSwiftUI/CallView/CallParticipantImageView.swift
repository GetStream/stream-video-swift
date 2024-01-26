//
// Copyright © 2024 Stream.io Inc. All rights reserved.
//

import StreamVideo
import SwiftUI

public struct CallParticipantImageView: View {

    @Injected(\.colors) var colors
    
    var id: String
    var name: String
    var imageURL: URL?

    public init(id: String, name: String, imageURL: URL? = nil) {
        self.id = id
        self.name = name
        self.imageURL = imageURL
    }

    public var body: some View {
        ZStack {
            CallParticipantBackground(imageURL: imageURL) {
                Color(colors.participantBackground)
            }
            CallParticipantImage(id: id, name: name, imageURL: imageURL)
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
    }
}

struct CallParticipantImage: View {
    
    @Injected(\.colors) var colors
    
    private let size: CGFloat = 138
    
    var id: String
    var name: String
    var imageURL: URL?
    
    var body: some View {
        ZStack {
            if #available(iOS 14.0, *), let imageURL = imageURL {
                UserAvatar(imageURL: imageURL, size: size) {
                    CircledTitleView(
                        title: name.isEmpty ? id : String(name.uppercased().first!),
                        size: size
                    )
                }
            } else {
                CircledTitleView(
                    title: name.isEmpty ? id : String(name.uppercased().first!),
                    size: size
                )
            }
        }
    }
}
