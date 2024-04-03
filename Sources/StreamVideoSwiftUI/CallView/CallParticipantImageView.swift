//
// Copyright © 2024 Stream.io Inc. All rights reserved.
//

import StreamVideo
import SwiftUI

public struct CallParticipantImageView: View {

    @Injected(\.colors) var colors
    
    private let size: CGFloat = 138

    var id: String
    var name: String
    var imageURL: URL?

    public init(id: String, name: String, imageURL: URL? = nil) {
        self.id = id
        self.name = name
        self.imageURL = imageURL
    }

    public var body: some View {
        StreamLazyImage(imageURL: imageURL) {
            Color(colors.participantBackground)
        }
        .blur(radius: 8)
        .overlay(
            UserAvatar(imageURL: imageURL, size: size) {
                CircledTitleView(
                    title: name.isEmpty ? id : String(name.uppercased().first!),
                    size: size
                )
            }
        )
    }
}
