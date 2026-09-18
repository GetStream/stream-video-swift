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
        VStack(spacing: layout.spacingXs) {
            viewFactory.makeUserAvatar(
                user,
                with: .init(size: avatarSize)
            )

            Text(user.name)
                .lineLimit(1)
                .font(fonts.footnote)
                .foregroundColor(Color(colors.textPrimary))
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
                            .fill(Color(colors.textOnInverse))
                            .frame(
                                width: layout.iconSizeSm,
                                height: layout.iconSizeSm
                            )

                        videoAppearance.images.xmarkCircleFill
                            .foregroundColor(
                                Color(colors.backgroundCoreInverse)
                            )
                    }
                    .padding(.all, layout.spacingXxs)
                })
            }
            .offset(
                x: layout.buttonPaddingXIconOnlySm,
                y: -layout.spacingXxs
            )
        )
        .frame(width: avatarSize)
    }

    private var colors: DesignSystemTokens.Colors {
        videoAppearance.tokens.colors
    }

    private var fonts: DesignSystemTokens.Fonts {
        videoAppearance.tokens.fonts
    }

    private var layout: DesignSystemTokens.Layout {
        videoAppearance.tokens.layout
    }
}
