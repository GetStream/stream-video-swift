//
// Copyright © 2024 Stream.io Inc. All rights reserved.
//

import Foundation

/// Handles the speaker state during a call.
public final class SpeakerManager: ObservableObject, CallSettingsManager, @unchecked Sendable {
        
    internal let callController: CallController
    @Published public internal(set) var status: CallSettingsStatus
    @Published public internal(set) var audioOutputStatus: CallSettingsStatus
    internal let state = CallSettingsState()
    
    init(
        callController: CallController,
        initialSpeakerStatus: CallSettingsStatus,
        initialAudioOutputStatus: CallSettingsStatus
    ) {
        self.callController = callController
        self.status = initialSpeakerStatus
        self.audioOutputStatus = initialAudioOutputStatus
    }
    
    /// Toggles the speaker during a call.
    public func toggleSpeakerPhone() async throws {
        try await updateSpeakerStatus(status.next)
    }
    
    /// Enables the speaker during a call.
    public func enableSpeakerPhone() async throws {
        try await updateSpeakerStatus(.enabled)
    }
    
    /// Disables the speaker during a call.
    public func disableSpeakerPhone() async throws {
        try await updateSpeakerStatus(.disabled)
    }
    
    /// Enables the sound on the device.
    public func enableAudioOutput() async throws {
        try await updateAudioOutputStatus(.enabled)
    }
    
    /// Disables the sound on the device.
    public func disableAudioOutput() async throws {
        try await updateAudioOutputStatus(.disabled)
    }
    
    // MARK: - private
    
    private func updateSpeakerStatus(_ status: CallSettingsStatus) async throws {
        try await updateState(
            newState: status.boolValue,
            current: self.status.boolValue,
            action: { [unowned self] state in
                try await callController.changeSpeakerState(isEnabled: state)
            },
            onUpdate: { value in
                self.status = status
            }
        )
    }
    
    private func updateAudioOutputStatus(_ status: CallSettingsStatus) async throws {
        try await updateState(
            newState: status.boolValue,
            current: self.audioOutputStatus.boolValue,
            action: { [unowned self] state in
                try await callController.changeSoundState(isEnabled: state)
            },
            onUpdate: { value in
                self.audioOutputStatus = status
            }
        )
    }
}
