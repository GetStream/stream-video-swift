//
// Copyright © 2026 Stream.io Inc. All rights reserved.
//

import StreamVideo
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
        let colors = InjectedValues[\.colors]
        switch self {
        case .error: return Color(colors.accentError)
        case .warning: return Color(colors.accentWarning)
        case .info: return Color(colors.accentPrimary)
        case .success: return Color(colors.accentSuccess)
        case let .custom(baseStyle, _): return baseStyle.themeColor
        }
    }
    
    var icon: Image {
        let images = InjectedValues[\.images]
        switch self {
        case .info: return images.infoCircleFill
        case .warning: return images.exclamationmarkTriangleFill
        case .success: return images.checkmarkCircleFill
        case .error: return images.exclamationmarkCircleFill
        case let .custom(baseStyle, _): return baseStyle.icon
        }
    }
}
