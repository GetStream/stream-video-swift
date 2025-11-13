//
// Copyright © 2025 Stream.io Inc. All rights reserved.
//

import AVFoundation
import Foundation

extension AVAudioSession.RouteChangeReason {

    /// Taken from https://chromium.googlesource.com/external/webrtc/+/34911ad55c4c4c549fe60e1b4cc127420b15666b/webrtc/modules/audio_device/ios/audio_device_ios.mm#557
    /// in the routeChange logic. Useful to ignore route changes that don't really matter for our
    /// webrtc sessions.
    var isValidRouteChange: Bool {
        switch self {
        case .categoryChange, .routeConfigurationChange:
            return false
        default:
            return true
        }
    }
}
