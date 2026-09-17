//
// Copyright © 2026 Stream.io Inc. All rights reserved.
//

import Foundation
import StreamCoreUI
import StreamVideo
import SwiftUI

public struct ModalButton: View {

    @Injected(\.videoAppearance) var videoAppearance

    var image: Image
    var action: () -> Void

    public init(image: Image, action: @escaping () -> Void) {
        self.image = image
        self.action = action
    }

    public var body: some View {
        Button {
            action()
        } label: {
            image
                .resizable()
                .foregroundColor(Color(colors.textPrimary))
                .aspectRatio(contentMode: .fit)
                .padding(layout.spacingXs)
        }
        .buttonStyle(.modal)
    }

    private var colors: DesignSystemTokens.Colors {
        videoAppearance.tokens.colors
    }

    private var layout: DesignSystemTokens.Layout {
        videoAppearance.tokens.layout
    }
}

struct ModalButtonStyle: ButtonStyle {

    @Injected(\.videoAppearance) var videoAppearance

    func makeBody(configuration: Configuration) -> some View {
        configuration
            .label
            .opacity(configuration.isPressed ? 0.5 : 1)
            .background(
                Circle()
                    .fill(
                        Color(
                            colors.backgroundCoreSurfaceDefault
                        )
                    )
            )
            .frame(width: 30, height: 30)
    }

    private var colors: DesignSystemTokens.Colors {
        videoAppearance.tokens.colors
    }
}

extension ButtonStyle where Self == ModalButtonStyle {

    static var modal: ModalButtonStyle { ModalButtonStyle() }
}
