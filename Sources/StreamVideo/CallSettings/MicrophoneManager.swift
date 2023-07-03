//
// Copyright © 2023 Stream.io Inc. All rights reserved.
//

import Foundation

public enum MicrophoneStatus: String {
    case enabled
    case disabled
}

/// Handles the microphone state during a call.
public class MicrophoneManager: ObservableObject, CallSettingsManager {
    
    internal let callController: CallController
    @Published public internal(set) var callSettings: CallSettings {
        didSet {
            self.status = callSettings.audioOn ? .enabled : .disabled
        }
    }
    /// The status of the microphone.
    @Published public internal(set) var status: MicrophoneStatus
    let state = CallSettingsState()

    init(callController: CallController, settings: CallSettings) {
        self.callController = callController
        self.callSettings = settings
        self.status = settings.audioOn ? .enabled : .disabled
    }

    /// Toggles the microphone state.
    public func toggle() async throws {
        try await updateAudioState(!callSettings.audioOn)
    }

    /// Enables the microphone.
    public func enable() async throws {
        try await updateAudioState(true)
    }

    /// Disables the microphone.
    public func disable() async throws {
        try await updateAudioState(false)
    }
    
    // MARK: - private
    
    private func updateAudioState(_ state: Bool) async throws {
        try await updateState(
            newState: state,
            current: callSettings.audioOn,
            action: { [unowned self] state in
                try await callController.changeAudioState(isEnabled: state)
            },
            onUpdate: { [unowned self] state in
                updateCallSettings(audioOn: state)
            }
        )
    }
    
    private func updateCallSettings(audioOn: Bool) {
        callSettings = CallSettings(
            audioOn: audioOn,
            videoOn: callSettings.videoOn,
            speakerOn: callSettings.speakerOn,
            audioOutputOn: callSettings.audioOutputOn,
            cameraPosition: callSettings.cameraPosition
        )
    }
}
