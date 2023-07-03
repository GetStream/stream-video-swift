//
// Copyright © 2023 Stream.io Inc. All rights reserved.
//

import Foundation

public enum MicrophoneStatus: String {
    case enabled
    case disabled
}

/// Handles the microphone state during a call.
public class MicrophoneManager: ObservableObject {
    
    actor State {
        var updatingState: Bool?
        func setUpdatingState(_ state: Bool?) {
            self.updatingState = state
        }
    }
    
    internal let callController: CallController
    @Published public internal(set) var callSettings: CallSettings {
        didSet {
            self.status = callSettings.audioOn ? .enabled : .disabled
        }
    }
    /// The status of the microphone.
    @Published public internal(set) var status: MicrophoneStatus
    private let state = State()

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
        let updatingState = await self.state.updatingState
        if state == callSettings.audioOn || updatingState == state {
            return
        }
        await self.state.setUpdatingState(state)
        try await callController.changeAudioState(isEnabled: state)
        updateCallSettings(audioOn: state)
        await self.state.setUpdatingState(nil)
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
