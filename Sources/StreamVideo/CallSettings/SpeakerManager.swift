//
// Copyright © 2023 Stream.io Inc. All rights reserved.
//

import Foundation

/// Handles the speaker state during a call.
public class SpeakerManager: ObservableObject, CallSettingsManager {
        
    internal let callController: CallController
    @Published public internal(set) var status: CallSettingsStatus
    @Published public internal(set) var audioOutputStatus: CallSettingsStatus
    internal let state = CallSettingsState()
    
    init(
        callController: CallController,
        initialStatus: CallSettingsStatus,
        audioOutputStatus: CallSettingsStatus
    ) {
        self.callController = callController
        self.status = initialStatus
        self.audioOutputStatus = audioOutputStatus
    }
    
    public func toggleSpeakerPhone() async throws {
        try await updateSpeakerStatus(status.next)
    }
    
    public func enableSpeakerPhone() async throws {
        try await updateSpeakerStatus(.enabled)
    }
    
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
            newState: status.toBool,
            current: self.status.toBool,
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
            newState: status.toBool,
            current: self.audioOutputStatus.toBool,
            action: { [unowned self] state in
                try await callController.changeSoundState(isEnabled: state)
            },
            onUpdate: { value in
                self.audioOutputStatus = status
            }
        )
    }
}
