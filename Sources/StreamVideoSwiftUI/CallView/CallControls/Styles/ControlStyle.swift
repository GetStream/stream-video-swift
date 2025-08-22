//
// Copyright © 2025 Stream.io Inc. All rights reserved.
//

import Foundation
import SwiftUI

public struct ControlStyle {
    public var icon: Image
    public var iconStyle: CallIconStyle

    public init(icon: Image, iconStyle: CallIconStyle) {
        self.icon = icon
        self.iconStyle = iconStyle
    }
}

public struct ToggleControlStyle {
    public var enabled: ControlStyle
    public var disabled: ControlStyle

    public init(enabled: ControlStyle, disabled: ControlStyle) {
        self.enabled = enabled
        self.disabled = disabled
    }
}
