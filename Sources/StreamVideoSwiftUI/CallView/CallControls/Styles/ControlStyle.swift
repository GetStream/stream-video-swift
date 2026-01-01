//
// Copyright © 2026 Stream.io Inc. All rights reserved.
//

import Foundation
import SwiftUI

/// Defines the visual style for a control element including its icon and
/// styling properties.
public struct ControlStyle {
    /// The icon image to display.
    public var icon: Image
    /// The styling properties for the icon.
    public var iconStyle: CallIconStyle

    public init(icon: Image, iconStyle: CallIconStyle) {
        self.icon = icon
        self.iconStyle = iconStyle
    }
}

/// Defines the visual style for a toggleable control with distinct styles
/// for enabled and disabled states.
public struct ToggleControlStyle {
    /// The style when the control is enabled.
    public var enabled: ControlStyle
    /// The style when the control is disabled.
    public var disabled: ControlStyle

    public init(enabled: ControlStyle, disabled: ControlStyle) {
        self.enabled = enabled
        self.disabled = disabled
    }
}
