//
// Copyright © 2026 Stream.io Inc. All rights reserved.
//

import StreamVideo
import StreamVideoSwiftUI
import SwiftUI

struct CallButtonView: View {
    @Injected(\.videoAppearance) var videoAppearance

    var title: String
    var maxWidth: CGFloat?
    var isDisabled: Bool

    var body: some View {
        Text(title)
            .bold()
            .foregroundColor(
                Color(
                    isDisabled
                        ? tokens.colors.textDisabled
                        : tokens.colors.buttonPrimaryTextOnAccent
                )
            )
            .padding(.all, tokens.layout.spacingSm)
            .frame(maxWidth: maxWidth ?? .infinity)
            .background(
                isDisabled
                    ? Color(tokens.colors.backgroundUtilityDisabled)
                    : Color(tokens.colors.buttonPrimaryBackground)
            )
            .cornerRadius(tokens.layout.radiusMd)
    }

    private var tokens: DesignSystemTokens { videoAppearance.tokens }
}
