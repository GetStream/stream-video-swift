//
// Copyright © 2026 Stream.io Inc. All rights reserved.
//

import StreamCoreUI
import StreamVideo
import SwiftUI

struct CallingIndicator: View {

    @Injected(\.colors) private var colors
    @Injected(\.layout) private var layout
    
    @State var isTransparent = false
    
    var body: some View {
        HStack(alignment: .firstTextBaseline, spacing: layout.spacingXxxs) {
            Circle()
                .frame(width: layout.spacingXxs, height: layout.spacingXxs)
                .opacity(isTransparent ? 1 : 0)
                .animation(
                    .easeOut(duration: 1).delay(0.2).repeatForever(autoreverses: true),
                    value: isTransparent
                )
            Circle()
                .frame(width: layout.spacingXxs, height: layout.spacingXxs)
                .opacity(isTransparent ? 1 : 0)
                .animation(
                    .easeInOut(duration: 1).delay(0.2).repeatForever(autoreverses: true),
                    value: isTransparent
                )
            Circle()
                .frame(width: layout.spacingXxs, height: layout.spacingXxs)
                .opacity(isTransparent ? 1 : 0)
                .animation(
                    .easeIn(duration: 1).delay(0.2).repeatForever(autoreverses: true),
                    value: isTransparent
                )
        }
        .accessibility(identifier: "callingIndicator")
        .foregroundColor(
            Color(colors.textSecondary)
        )
        .onAppear {
            isTransparent.toggle()
        }
    }
}
