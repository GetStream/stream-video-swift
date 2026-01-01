//
// Copyright © 2026 Stream.io Inc. All rights reserved.
//

import Foundation
import StreamVideo
import StreamVideoSwiftUI
import SwiftUI

struct DemoModalNavigationBarViewModifier: ViewModifier {

    @Injected(\.fonts) private var fonts
    @Injected(\.images) private var images
    @Injected(\.colors) private var colors

    var title: String
    var closeAction: (() -> Void)?

    func body(content: Content) -> some View {
        VStack(spacing: 0) {
            HStack {
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
            .foregroundColor(.white)
            .padding(.bottom, 24)
            .padding(.top)
            .padding(.horizontal)

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
