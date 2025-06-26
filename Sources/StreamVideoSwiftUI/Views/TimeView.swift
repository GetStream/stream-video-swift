//
// Copyright © 2025 Stream.io Inc. All rights reserved.
//

import StreamVideo
import SwiftUI

struct TimeView: View {

    @Injected(\.fonts) private var fonts: Fonts
    @Injected(\.colors) private var colors: Colors

    var value: NSMutableAttributedString

    init(_ value: String) {
        let attributed = NSMutableAttributedString(string: value)
        self.value = attributed
        self.value.addAttribute(
            .foregroundColor,
            value: colors.callDurationColor.withAlphaComponent(0.6),
            range: .init(location: 0, length: attributed.length - 3)
        )
        self.value.addAttribute(
            .foregroundColor,
            value: colors.callDurationColor,
            range: .init(location: attributed.length - 3, length: 3)
        )
    }

    var body: some View {
        Group {
            if #available(iOS 15.0, *) {
                Text(AttributedString(value))
            } else {
                Text(value.string)
                    .foregroundColor(Color.white.opacity(0.6))
            }
        }
        .font(fonts.bodyBold.monospacedDigit())
        .minimumScaleFactor(0.2)
        .lineLimit(1)
    }
}
