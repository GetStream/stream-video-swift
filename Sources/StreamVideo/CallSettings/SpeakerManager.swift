//
// Copyright © 2023 Stream.io Inc. All rights reserved.
//

import Foundation

/// Handles the speaker state during a call.
public class SpeakerManager: ObservableObject, CallSettingsManager {
        
    internal let callController: CallController
    @Published public internal(set) var callSettings: CallSettings
    internal let state = CallSettingsState()
    
    init(callController: CallController, settings: CallSettings) {
        self.callController = callController
        self.callSettings = settings
    }
    
    public func enableSpeakerPhone() async throws {
        try await updateSpeakerState(true)
    }
    
    public func disableSpeakerPhone() async throws {
        try await updateSpeakerState(false)
    }
    
    /// Enables the sound on the device.
    public func enableAudioOutput() async throws {
        try await updateAudioOutputState(true)
    }
    
    /// Disables the sound on the device.
    public func disableAudioOutput() async throws {
        try await updateAudioOutputState(false)
    }
    
    // MARK: - private
    
    private func updateSpeakerState(_ state: Bool) async throws {
        try await updateState(
            newState: state,
            current: callSettings.speakerOn,
            action: { [unowned self] state in
                try await callController.changeSpeakerState(isEnabled: state)
            },
            onUpdate: { [unowned self] state in
                updateCallSettings(speakerOn: state)
            }
        )
    }
    
    private func updateAudioOutputState(_ state: Bool) async throws {
        try await updateState(
            newState: state,
            current: callSettings.audioOutputOn,
            action: { [unowned self] state in
            try await callController.changeSoundState(isEnabled: state)
        }, onUpdate: { [unowned self] state in
            updateCallSettings(audioOutpuOn: state)
        })
    }

    private func updateCallSettings(audioOutpuOn: Bool) {
        callSettings = CallSettings(
            audioOn: callSettings.audioOn,
            videoOn: callSettings.videoOn,
            speakerOn: callSettings.speakerOn,
            audioOutputOn: audioOutpuOn,
            cameraPosition: callSettings.cameraPosition
        )
    }
    
    private func updateCallSettings(speakerOn: Bool) {
        callSettings = CallSettings(
            audioOn: callSettings.audioOn,
            videoOn: callSettings.videoOn,
            speakerOn: speakerOn,
            audioOutputOn: callSettings.audioOutputOn,
            cameraPosition: callSettings.cameraPosition
        )
    }
}
