//
// Copyright © 2026 Stream.io Inc. All rights reserved.
//

import AVFoundation
import Combine
import Foundation

/// Policy that manages speaker state based on device proximity during calls.
/// Automatically disables speaker when device is near user (e.g., during phone call)
/// and restores previous speaker state when device moves away.
public final class SpeakerProximityPolicy: ProximityPolicy, @unchecked Sendable {

    @Injected(\.audioStore) private var audioStore
    /// Unique identifier for this policy implementation
    public static let identifier: ObjectIdentifier = .init("speaker-proximity-policy" as NSString)

    /// Queue for processing proximity state changes
    private let processingQueue = OperationQueue(maxConcurrentOperationCount: 1)
    /// Stores call settings before proximity change for restoration
    private var callSettingsBeforeProximityChange: CallSettings?

    public init() {}

    /// Handles proximity state changes by managing speaker settings.
    /// - When device is near: Disables speaker if enabled
    /// - When device is far: Restores previous speaker settings
    /// - Parameters:
    ///   - proximity: New proximity state of the device
    ///   - call: Call instance where the proximity change occurred
    public func didUpdateProximity(
        _ proximity: ProximityState,
        on call: Call
    ) {
        processingQueue.addTaskOperation { @MainActor [weak self, weak call] in
            guard
                let self,
                let call,
                audioStore.state.currentRoute.isExternal == false
            else {
                return
            }

            switch proximity {
            case .near:
                let callSettings = call.state.callSettings
                if callSettings.speakerOn {
                    self.callSettingsBeforeProximityChange = callSettings
                    try? await call.callController.changeSpeakerState(isEnabled: false)
                } else {
                    /* No-op */
                }
            case .far:
                guard let callSettingsBeforeProximityChange else {
                    return
                }
                self.callSettingsBeforeProximityChange = nil
                try? await call
                    .callController
                    .changeSpeakerState(isEnabled: callSettingsBeforeProximityChange.speakerOn)
            }
        }
    }
}
