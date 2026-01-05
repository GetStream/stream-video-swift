//
// Copyright © 2026 Stream.io Inc. All rights reserved.
//

import AVFoundation

extension AVAudioSession.RouteChangeReason {
    public var description: String {
        switch self {
        case .unknown:
            return ".unknown"
        case .newDeviceAvailable:
            return ".newDeviceAvailable"
        case .oldDeviceUnavailable:
            return ".oldDeviceUnavailable"
        case .categoryChange:
            return ".categoryChange"
        case .override:
            return ".override"
        case .wakeFromSleep:
            return ".wakeFromSleep"
        case .noSuitableRouteForCategory:
            return ".noSuitableRouteForCategory"
        case .routeConfigurationChange:
            return ".routeConfigurationChange"
        @unknown default:
            return "Unknown Reason"
        }
    }
}
