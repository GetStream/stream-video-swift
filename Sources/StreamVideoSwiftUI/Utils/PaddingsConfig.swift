//
// Copyright © 2025 Stream.io Inc. All rights reserved.
//

import Foundation

/// A configuration object that defines padding values for different edges.
///
/// `PaddingsConfig` allows you to specify custom padding values for leading,
/// trailing, top, and bottom edges, which can be reused across multiple UI components.
public struct PaddingsConfig {
    
    /// The amount of padding on the leading edge.
    public let leading: CGFloat
    
    /// The amount of padding on the trailing edge.
    public let trailing: CGFloat
    
    /// The amount of padding on the top edge.
    public let top: CGFloat
    
    /// The amount of padding on the bottom edge.
    public let bottom: CGFloat
    
    /// Creates a new `PaddingsConfig` instance with the specified edge paddings.
    ///
    /// - Parameters:
    ///   - leading: The padding for the leading edge. Defaults to `0`.
    ///   - trailing: The padding for the trailing edge. Defaults to `0`.
    ///   - top: The padding for the top edge. Defaults to `0`.
    ///   - bottom: The padding for the bottom edge. Defaults to `0`.
    public init(
        leading: CGFloat = 0,
        trailing: CGFloat = 0,
        top: CGFloat = 0,
        bottom: CGFloat = 0
    ) {
        self.leading = leading
        self.trailing = trailing
        self.top = top
        self.bottom = bottom
    }
}

extension PaddingsConfig {
    
    /// Padding configuration for the participant info view.
    ///
    /// - Leading: `6`
    /// - Trailing: `6`
    /// - Top: `2`
    /// - Bottom: `2`
    @MainActor public static let participantInfoView = PaddingsConfig(
        leading: 6,
        trailing: 6,
        top: 2,
        bottom: 2
    )
    
    /// Padding configuration for the participant info view in Picture-in-Picture mode.
    ///
    /// The leading and bottom paddings vary depending on the iOS version.
    @MainActor public static let participantInfoViewPiP = PaddingsConfig(
        leading: leadingPaddingInfoViewPiP,
        trailing: 6,
        top: 2,
        bottom: bottomPaddingInfoViewPiP
    )
    
    /// Padding configuration for the connection indicator view.
    ///
    /// The trailing and bottom paddings vary depending on the iOS version.
    @MainActor public static let connectionIndicator = PaddingsConfig(
        leading: 0,
        trailing: trailingPaddingConnectionIndicator,
        top: 0,
        bottom: bottomPaddingConnectionIndicator
    )
    
    /// Leading padding for the participant info view in PiP mode,
    /// adjusted for iOS 26 and above.
    private static var leadingPaddingInfoViewPiP: CGFloat {
        if #available(iOS 26.0, *) {
            return 16
        } else {
            return 6
        }
    }
    
    /// Bottom padding for the participant info view in PiP mode,
    /// adjusted for iOS 26 and above.
    private static var bottomPaddingInfoViewPiP: CGFloat {
        if #available(iOS 26.0, *) {
            return 4
        } else {
            return 2
        }
    }
    
    /// Trailing padding for the connection indicator,
    /// adjusted for iOS 26 and above.
    private static var trailingPaddingConnectionIndicator: CGFloat {
        if #available(iOS 26.0, *) {
            return 8
        } else {
            return 0
        }
    }
    
    /// Bottom padding for the connection indicator,
    /// adjusted for iOS 26 and above.
    private static var bottomPaddingConnectionIndicator: CGFloat {
        if #available(iOS 26.0, *) {
            return 2
        } else {
            return 0
        }
    }
}
