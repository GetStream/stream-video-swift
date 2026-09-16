//
// Copyright © 2026 Stream.io Inc. All rights reserved.
//

import StreamCoreUI
import StreamVideo
import SwiftUI

struct CallingIndicator: View {

    @Injected(\.videoAppearance) var videoAppearance
    
    @State var isTransparent = false
    
    var body: some View {
        HStack(alignment: .firstTextBaseline, spacing: tokens.layout.spacingXxxs) {
            Circle()
                .frame(width: tokens.layout.spacingXxs, height: tokens.layout.spacingXxs)
                .opacity(isTransparent ? 1 : 0)
                .animation(
                    .easeOut(duration: 1).delay(0.2).repeatForever(autoreverses: true),
                    value: isTransparent
                )
            Circle()
                .frame(width: tokens.layout.spacingXxs, height: tokens.layout.spacingXxs)
                .opacity(isTransparent ? 1 : 0)
                .animation(
                    .easeInOut(duration: 1).delay(0.2).repeatForever(autoreverses: true),
                    value: isTransparent
                )
            Circle()
                .frame(width: tokens.layout.spacingXxs, height: tokens.layout.spacingXxs)
                .opacity(isTransparent ? 1 : 0)
                .animation(
                    .easeIn(duration: 1).delay(0.2).repeatForever(autoreverses: true),
                    value: isTransparent
                )
        }
        .accessibility(identifier: "callingIndicator")
        .foregroundColor(
            Color(videoAppearance.tokens.colors.textSecondary)
        )
        .onAppear {
            isTransparent.toggle()
        }
    }

    private var tokens: DesignSystemTokens { videoAppearance.tokens }
}
