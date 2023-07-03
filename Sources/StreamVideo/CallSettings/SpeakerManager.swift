//
// Copyright © 2023 Stream.io Inc. All rights reserved.
//

import Foundation

/// Handles the speaker state during a call.
public class SpeakerManager: ObservableObject {
    
    actor State {
        var updatingState: Bool?
        func setUpdatingState(_ state: Bool?) {
            self.updatingState = state
        }
    }
    
    internal let callController: CallController
    @Published public internal(set) var callSettings: CallSettings
    private let state = State()
    
    init(callController: CallController, settings: CallSettings) {
        self.callController = callController
        self.callSettings = settings
    }
    
    /// Enables the speaker.
    public func enable() async throws {
        try await updateAudioOutputState(true)
    }
    
    /// Disables the speaker.
    public func disable() async throws {
        try await updateAudioOutputState(false)
    }
    
    // MARK: - private
    
    private func updateAudioOutputState(_ state: Bool) async throws {
        let updatingState = await self.state.updatingState
        if state == callSettings.audioOutputOn || updatingState == state {
            return
        }
        await self.state.setUpdatingState(state)
        try await callController.changeSoundState(isEnabled: state)
        updateCallSettings(audioOutpuOn: state)
        await self.state.setUpdatingState(nil)
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
}
