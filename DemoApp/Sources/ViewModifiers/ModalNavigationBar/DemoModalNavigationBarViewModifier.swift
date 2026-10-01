//
// Copyright © 2026 Stream.io Inc. All rights reserved.
//

import Foundation
import StreamVideo
import StreamVideoSwiftUI
import SwiftUI

struct DemoModalNavigationBarViewModifier: ViewModifier {

    @Injected(\.videoAppearance) private var videoAppearance

    var title: String
    var closeAction: (() -> Void)?

    func body(content: Content) -> some View {
        VStack(spacing: 0) {
            HStack(spacing: tokens.layout.spacingXs) {
                if !title.isEmpty {
                    Text(title)
                        .font(tokens.fonts.title3)
                        .fontWeight(.medium)
                }

                Spacer()

                if let closeAction {
                    ModalButton(image: videoAppearance.images.xmark) {
                        closeAction()
                    }
                }
            }
            .foregroundColor(Color(tokens.colors.textPrimary))
            .padding(.bottom, tokens.layout.spacingXl)
            .padding(.top, tokens.layout.spacingMd)
            .padding(.horizontal, tokens.layout.spacingMd)

            content
        }
    }

    private var tokens: DesignSystemTokens { videoAppearance.tokens }
}

extension View {

    @ViewBuilder
    func withModalNavigationBar(
        title: String,
        closeAction: (() -> Void)? = nil
    ) -> some View {
        modifier(
            DemoModalNavigationBarViewModifier(
                title: title,
                closeAction: closeAction
            )
        )
    }
}
