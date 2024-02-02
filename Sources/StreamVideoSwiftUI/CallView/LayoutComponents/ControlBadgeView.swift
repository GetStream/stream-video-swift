//
// Copyright © 2024 Stream.io Inc. All rights reserved.
//

import Foundation
import StreamVideo
import SwiftUI

public struct ControlBadgeView: View {
    @Injected(\.colors) private var colors

    var value: String

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
