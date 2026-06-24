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
    ///
    /// - Important: `.categoryChange` is intentionally excluded. It is emitted
    ///   by our own category/mode reconfiguration and momentarily reports the
    ///   default (receiver) route while a speaker override is still pending.
    ///   Treating it as a hardware transition makes the route observer clobber
    ///   the user's `speakerOn` selection, which kicks off an endless
    ///   reconfiguration loop during call join that prevents captured
    ///   microphone audio from reaching the published track.
    var requiresReconfiguration: Bool {
        switch self {
        case .override, .wakeFromSleep, .newDeviceAvailable, .oldDeviceUnavailable:
            return true
        default:
            return false
        }
    }
}
