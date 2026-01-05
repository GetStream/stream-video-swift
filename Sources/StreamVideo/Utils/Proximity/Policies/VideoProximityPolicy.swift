//
// Copyright © 2026 Stream.io Inc. All rights reserved.
//

import AVFoundation
import Combine
import Foundation

/// Policy that manages video settings based on device proximity during calls.
/// Automatically disables video when device is near user and restores previous
/// video settings when device moves away.
public final class VideoProximityPolicy: ProximityPolicy, @unchecked Sendable {

    /// Stores video settings to be restored when device moves away
    private struct CachedValue {
        /// Cached incoming video quality settings
        var incomingVideoQualitySettings: IncomingVideoQualitySettings?
        /// Cached video state (enabled/disabled)
        var videoOn: Bool
    }

    /// Unique identifier for this policy implementation
    public static let identifier: ObjectIdentifier = .init("video-proximity-policy" as NSString)

    /// Queue for processing proximity state changes
    private let processingQueue = OperationQueue(maxConcurrentOperationCount: 1)
    /// Thread-safe storage for cached video settings
    @Atomic private var cachedValue: CachedValue?

    public init() {}

    /// Handles proximity state changes by managing video settings.
    /// - When device is near: Disables video and incoming video quality
    /// - When device is far: Restores previous video settings
    /// - Parameters:
    ///   - proximity: New proximity state of the device
    ///   - call: Call instance where the proximity change occurred
    public func didUpdateProximity(
        _ proximity: ProximityState,
        on call: Call
    ) {
        processingQueue.addTaskOperation { @MainActor [weak self, weak call] in
            guard let self, let call else {
                return
            }

            switch proximity {
            case .near:
                let callSettings = call.state.callSettings
                let cachedValue = CachedValue(
                    incomingVideoQualitySettings: call.state.incomingVideoQualitySettings,
                    videoOn: callSettings.videoOn
                )
                self.cachedValue = cachedValue
                await call.setIncomingVideoQualitySettings(.disabled(group: .all))
                if cachedValue.videoOn {
                    try? await call.callController.changeVideoState(isEnabled: false)
                }
            case .far:
                if let cachedValue {
                    if let incomingVideoQualitySettings = cachedValue.incomingVideoQualitySettings {
                        await call.setIncomingVideoQualitySettings(incomingVideoQualitySettings)
                    }

                    if cachedValue.videoOn {
                        try? await call.callController.changeVideoState(isEnabled: true)
                    }
                }
            }
        }
    }
}
