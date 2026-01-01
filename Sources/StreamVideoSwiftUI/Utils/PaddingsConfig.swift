//
// Copyright © 2026 Stream.io Inc. All rights reserved.
//

import SwiftUI

extension EdgeInsets {
    
    /// Padding configuration for the participant info view.
    ///
    /// - Leading: `6`
    /// - Trailing: `6`
    /// - Top: `2`
    /// - Bottom: `2`
    public static let participantInfoView = EdgeInsets(
        top: 2,
        leading: 6,
        bottom: 2,
        trailing: 6
    )
    
    /// Padding configuration for the participant info view in Picture-in-Picture mode.
    ///
    /// The leading and bottom paddings vary depending on the iOS version.
    public static let participantInfoViewPiP = EdgeInsets(
        top: 2,
        leading: leadingPaddingInfoViewPiP,
        bottom: bottomPaddingInfoViewPiP,
        trailing: 6
    )
    
    /// Padding configuration for the connection indicator view.
    ///
    /// The trailing and bottom paddings vary depending on the iOS version.
    public static let connectionIndicator = EdgeInsets(
        top: 0,
        leading: 0,
        bottom: bottomPaddingConnectionIndicator,
        trailing: trailingPaddingConnectionIndicator
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
