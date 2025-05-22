//
// Copyright © 2025 Stream.io Inc. All rights reserved.
//

import SwiftUI

public struct Toast: Equatable {
    /// The style of the toast.
    public var style: ToastStyle
    /// The message displayed in the toast.
    public var message: String
    /// The placement of the toast.
    /// The default placement is `.top`.
    public var placement: ToastPlacement
    /// The duration of the toast.
    public var duration: Double

    public init(
        style: ToastStyle,
        message: String,
        placement: ToastPlacement = .top,
        duration: Double = 2.5
    ) {
        self.style = style
        self.message = message
        self.placement = placement
        self.duration = duration
    }
}

public enum ToastPlacement {
    /// The toast is displayed at the top.
    case top
    /// The toast is displayed at the bottom.
    case bottom
}

public indirect enum ToastStyle: Equatable {

    /// Displays error messages.
    case error
    /// Displays warning messages.
    case warning
    /// Displays success messages.
    case success
    /// Displays info messages.
    case info

    case custom(baseStyle: ToastStyle, icon: AnyView)

    public static func == (
        lhs: ToastStyle,
        rhs: ToastStyle
    ) -> Bool {
        switch (lhs, rhs) {
        case (.error, .error):
            true
        case (.warning, .warning):
            true
        case (.success, .success):
            true
        case (.info, .info):
            true
        case (.custom, .custom):
            false
        default:
            false
        }
    }
}

extension ToastStyle {
    var themeColor: Color {
        switch self {
        case .error: Color.red
        case .warning: Color.orange
        case .info: Color.blue
        case .success: Color.green
        case let .custom(baseStyle, _): baseStyle.themeColor
        }
    }
    
    var iconFileName: String {
        switch self {
        case .info: "info.circle.fill"
        case .warning: "exclamationmark.triangle.fill"
        case .success: "checkmark.circle.fill"
        case .error: "exclamationmark.circle.fill"
        case let .custom(baseStyle, _): baseStyle.iconFileName
        }
    }
}
