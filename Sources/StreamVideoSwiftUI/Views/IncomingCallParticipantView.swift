//
// Copyright © 2025 Stream.io Inc. All rights reserved.
//

import StreamVideo
import SwiftUI

struct IncomingCallParticipantView<Factory: ViewFactory>: View {

    var viewFactory: Factory
    var participant: Member
    var size: CGFloat

    init(
        viewFactory: Factory,
        participant: Member,
        size: CGFloat = .expandedAvatarSize
    ) {
        self.viewFactory = viewFactory
        self.participant = participant
        self.size = size
    }

    var body: some View {
        viewFactory.makeUserAvatar(
            participant.user,
            with: .init(size: size) {
                AnyView(CircledTitleView(title: title, size: size))
            }
        )
        .frame(width: size, height: size)
        .modifier(ShadowModifier())
        .animation(nil)
        .debugViewRendering()
    }

    private var title: String {
        let name = participant.user.name.isEmpty ? "Unknown" : participant.user.name
        let title = String(name.uppercased().first!)
        return title
    }
}
