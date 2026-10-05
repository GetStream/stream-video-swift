//
// Copyright © 2026 Stream.io Inc. All rights reserved.
//

import Foundation
import StreamVideo
import StreamVideoSwiftUI
import SwiftUI

struct DemoModalNavigationBarViewModifier: ViewModifier {

    @Injected(\.colors) private var colors
    @Injected(\.images) private var images
    @Injected(\.fonts) private var fonts
    @Injected(\.layout) private var layout

    var title: String
    var closeAction: (() -> Void)?

    func body(content: Content) -> some View {
        VStack(spacing: 0) {
            HStack(spacing: layout.spacingXs) {
                if !title.isEmpty {
                    Text(title)
                        .font(fonts.title3)
                        .fontWeight(.medium)
                }

                Spacer()

                if let closeAction {
                    ModalButton(image: images.xmark) {
                        closeAction()
                    }
                }
            }
            .foregroundColor(Color(colors.textPrimary))
            .padding(.bottom, layout.spacingXl)
            .padding(.top, layout.spacingMd)
            .padding(.horizontal, layout.spacingMd)

            content
        }
    }
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
