//
// Copyright © 2026 Stream.io Inc. All rights reserved.
//

import StreamVideo
import StreamVideoSwiftUI
import SwiftUI

struct CallButtonView: View {
    @Injected(\.colors) private var colors
    @Injected(\.layout) private var layout

    var title: String
    var maxWidth: CGFloat?
    var isDisabled: Bool

    var body: some View {
        Text(title)
            .bold()
            .foregroundColor(
                Color(
                    isDisabled
                        ? colors.textDisabled
                        : colors.buttonPrimaryTextOnAccent
                )
            )
            .padding(.all, layout.spacingSm)
            .frame(maxWidth: maxWidth ?? .infinity)
            .background(
                isDisabled
                    ? Color(colors.backgroundUtilityDisabled)
                    : Color(colors.buttonPrimaryBackground)
            )
            .cornerRadius(layout.radiusMd)
    }
}
