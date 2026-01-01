//
// Copyright © 2026 Stream.io Inc. All rights reserved.
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
            return true
        case (.warning, .warning):
            return true
        case (.success, .success):
            return true
        case (.info, .info):
            return true
        case (.custom, .custom):
            return false
        default:
            return false
        }
    }
}

extension ToastStyle {
    var themeColor: Color {
        switch self {
        case .error: return Color.red
        case .warning: return Color.orange
        case .info: return Color.blue
        case .success: return Color.green
        case let .custom(baseStyle, _): return baseStyle.themeColor
        }
    }
    
    var iconFileName: String {
        switch self {
        case .info: return "info.circle.fill"
        case .warning: return "exclamationmark.triangle.fill"
        case .success: return "checkmark.circle.fill"
        case .error: return "exclamationmark.circle.fill"
        case let .custom(baseStyle, _): return baseStyle.iconFileName
        }
    }
}
