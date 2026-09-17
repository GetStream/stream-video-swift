//
// Copyright © 2026 Stream.io Inc. All rights reserved.
//

import StreamCoreUI
import StreamVideo
import SwiftUI

struct SelectedParticipantView<Factory: ViewFactory>: View {

    @Injected(\.videoAppearance) var videoAppearance

    private let avatarSize: CGFloat = 50

    var viewFactory: Factory
    var user: User
    var onUserTapped: (User) -> Void

    init(
        viewFactory: Factory,
        user: User,
        onUserTapped: @escaping (User) -> Void
    ) {
        self.viewFactory = viewFactory
        self.user = user
        self.onUserTapped = onUserTapped
    }

    var body: some View {
        VStack {
            viewFactory.makeUserAvatar(
                user,
                with: .init(size: avatarSize)
            )

            Text(user.name)
                .lineLimit(1)
                .font(videoAppearance.tokens.fonts.footnote)
        }
        .overlay(
            TopRightView {
                Button(action: {
                    withAnimation {
                        onUserTapped(user)
                    }
                }, label: {
                    ZStack {
                        Circle()
                            .fill(Color.white)
                            .frame(width: 16, height: 16)

                        Image(systemName: "xmark.circle.fill")
                            .foregroundColor(
                                Color.black.opacity(0.8)
                            )
                    }
                    .padding(
                        .all,
                        videoAppearance.tokens.layout.spacingXxs
                    )
                })
            }
            .offset(x: 6, y: -4)
        )
        .frame(width: avatarSize)
    }
}
