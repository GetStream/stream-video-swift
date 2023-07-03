//
// Copyright © 2023 Stream.io Inc. All rights reserved.
//

import Foundation

public enum CameraStatus: String {
    case enabled
    case disabled
}

/// Handles the camera state during a call.
public class CameraManager: ObservableObject {
    
    actor State {
        var updatingState: Bool?
        func setUpdatingState(_ state: Bool?) {
            self.updatingState = state
        }
    }
    
    internal let callController: CallController
    @Published public internal(set) var callSettings: CallSettings {
        didSet {
            self.status = callSettings.videoOn ? .enabled : .disabled
            self.direction = callSettings.cameraPosition
        }
    }
    @Published public internal(set) var status: CameraStatus
    @Published public internal(set) var direction: CameraPosition
    private let state = State()
    
    init(callController: CallController, settings: CallSettings) {
        self.callController = callController
        self.callSettings = settings
        self.status = settings.videoOn ? .enabled : .disabled
        self.direction = settings.cameraPosition
    }

    /// Toggles the camera state.
    public func toggle() async throws {
        try await updateVideoState(!callSettings.videoOn)
    }
    
    /// Flips the camera (front to back and vice versa).
    public func flip() async throws {
        let next = callSettings.cameraPosition.next()
        await withCheckedContinuation { [unowned self] continuation in
            callController.changeCameraMode(position: next) {
                self.updateCallSettings(cameraPosition: next)
                continuation.resume()
            }
        }
    }

    /// Enables the camera.
    public func enable() async throws {
        try await updateVideoState(true)
    }

    /// Disables the camera.
    public func disable() async throws {
        try await updateVideoState(false)
    }
    
    // MARK: - private
    
    private func updateVideoState(_ state: Bool) async throws {
        let updatingState = await self.state.updatingState
        if state == callSettings.videoOn || updatingState == state {
            return
        }
        await self.state.setUpdatingState(state)
        try await callController.changeVideoState(isEnabled: state)
        updateCallSettings(videoOn: state)
        await self.state.setUpdatingState(nil)
    }
    
    private func updateCallSettings(videoOn: Bool) {
        callSettings = CallSettings(
            audioOn: callSettings.audioOn,
            videoOn: videoOn,
            speakerOn: callSettings.speakerOn,
            audioOutputOn: callSettings.audioOutputOn,
            cameraPosition: callSettings.cameraPosition
        )
    }
    
    private func updateCallSettings(cameraPosition: CameraPosition) {
        callSettings = CallSettings(
            audioOn: callSettings.audioOn,
            videoOn: callSettings.videoOn,
            speakerOn: callSettings.speakerOn,
            audioOutputOn: callSettings.audioOutputOn,
            cameraPosition: cameraPosition
        )
    }
}
