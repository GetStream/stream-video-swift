//
// Copyright © 2025 Stream.io Inc. All rights reserved.
//

import Foundation
import StreamCore
import StreamVideo
import SwiftUI

/// A view representing a control badge displaying a value.
public struct ControlBadgeView: View {
    @Injected(\.colors) private var colors

    /// The value to be displayed within the badge.
    var value: String

    /// Initializes a control badge view with the specified value.
    /// - Parameter value: The value to display within the badge.
    public init(_ value: String) {
        self.value = value
    }

    public var body: some View {
        TopRightView {
            Text(value)
                .minimumScaleFactor(0.3)
                .frame(width: 14, height: 14)
                .padding(2)
                .font(.system(size: 12))
                .foregroundColor(colors.textInverted)
                .background(Circle().fill(colors.onlineIndicatorColor))
        }
    }
}
