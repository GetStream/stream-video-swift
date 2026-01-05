//
// Copyright © 2026 Stream.io Inc. All rights reserved.
//

import StreamVideo
import SwiftUI

public struct CallParticipantImageView<Factory: ViewFactory>: View {

    @Injected(\.colors) var colors
    
    private let size: CGFloat = 138

    var viewFactory: Factory
    var id: String
    var name: String
    var imageURL: URL?

    public init(
        viewFactory: Factory = DefaultViewFactory.shared,
        id: String,
        name: String,
        imageURL: URL? = nil
    ) {
        self.viewFactory = viewFactory
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
            viewFactory.makeUserAvatar(
                .init(id: id, name: name, imageURL: imageURL),
                with: .init(size: size) {
                    AnyView(
                        CircledTitleView(
                            title: name.isEmpty ? id : String(name.uppercased().first!),
                            size: size
                        )
                    )
                }
            )
        )
    }
}
