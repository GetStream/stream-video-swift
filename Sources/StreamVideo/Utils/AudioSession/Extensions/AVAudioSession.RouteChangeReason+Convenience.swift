//
// Copyright © 2026 Stream.io Inc. All rights reserved.
//

import AVFoundation
import Foundation

extension AVAudioSession.RouteChangeReason {

    /// Mirrors the filtering logic used by WebRTC so we ignore redundant
    /// callbacks such as `categoryChange` that would otherwise spam the store.
    var isValidRouteChange: Bool {
        switch self {
        case .categoryChange, .routeConfigurationChange:
            return false
        default:
            return true
        }
    }

    /// Flags reasons that represent real hardware transitions so we can rebuild
    /// the audio graph when necessary.
    var requiresReconfiguration: Bool {
        switch self {
        case .categoryChange, .override, .wakeFromSleep, .newDeviceAvailable, .oldDeviceUnavailable:
            return true
        default:
            return false
        }
    }
}
