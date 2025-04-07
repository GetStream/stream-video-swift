//
// Copyright © 2025 Stream.io Inc. All rights reserved.
//

import AVFoundation
import Combine
import Foundation

/// Policy that manages speaker state based on device proximity during calls.
/// Automatically disables speaker when device is near user (e.g., during phone call)
/// and restores previous speaker state when device moves away.
public final class SpeakerProximityPolicy: ProximityPolicy, @unchecked Sendable {

    @Injected(\.activeCallAudioSession) private var activeCallAudioSession
    /// Unique identifier for this policy implementation
    public static let identifier: ObjectIdentifier = .init("speaker-proximity-policy" as NSString)

    /// Queue for processing proximity state changes
    private let processingQueue = SerialActorQueue()
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
        processingQueue.async { @MainActor [weak self, weak call] in
            guard
                let self,
                let call,
                activeCallAudioSession?.currentRoute.isExternal == false
            else {
                return
            }

            switch proximity {
            case .near:
                if call.state.callSettings.speakerOn {
                    self.callSettingsBeforeProximityChange = call.state.callSettings
                    let updatedCallSettings = call
                        .state
                        .callSettings
                        .withUpdatedSpeakerState(false)

                    call.state.callSettings = updatedCallSettings

                    log.debug(
                        "Device proximity was updated to .near. Speaker was disabled.",
                        subsystems: .audioSession
                    )
                } else if !call.state.callSettings.speakerOn {
                    log.debug(
                        "Device proximity was updated to .near but speaker is already off.",
                        subsystems: .audioSession
                    )
                } else {
                    /* No-op */
                }
            case .far:
                if let callSettingsBeforeProximityChange {
                    self.callSettingsBeforeProximityChange = nil
                    call.state.callSettings = callSettingsBeforeProximityChange
                    log.debug(
                        "Device proximity was updated to .far. We restored the CallSettings.",
                        subsystems: .audioSession
                    )
                } else {
                    log.debug(
                        "Device proximity was updated to .far but no CallSettings found to restore.",
                        subsystems: .audioSession
                    )
                }
            }
        }
    }
}
