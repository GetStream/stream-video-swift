//
// Copyright © 2023 Stream.io Inc. All rights reserved.
//

import Foundation

/// Handles the camera state during a call.
public final class CameraManager: ObservableObject, CallSettingsManager, @unchecked Sendable {
    
    internal let callController: CallController
    @Published public internal(set) var status: CallSettingsStatus
    @Published public internal(set) var direction: CameraPosition
    let state = CallSettingsState()
    
    init(
        callController: CallController,
        initialStatus: CallSettingsStatus,
        initialDirection: CameraPosition
    ) {
        self.callController = callController
        self.status = initialStatus
        self.direction = initialDirection
    }

    /// Toggles the camera state.
    public func toggle() async throws {
        try await updateVideoStatus(status.next)
    }
    
    /// Flips the camera (front to back and vice versa).
    public func flip() async throws {
        let next = direction.next()
        try await callController.changeCameraMode(position: next)
        self.direction = next
    }

    /// Enables the camera.
    public func enable() async throws {
        try await updateVideoStatus(.enabled)
    }

    /// Disables the camera.
    public func disable() async throws {
        try await updateVideoStatus(.disabled)
    }
    
    // MARK: - private
    
    private func updateVideoStatus(_ status: CallSettingsStatus) async throws {
        try await updateState(
            newState: status.boolValue,
            current: self.status.boolValue,
            action: { [unowned self] state in
                try await callController.changeVideoState(isEnabled: state)
            },
            onUpdate: { value in
                self.status = status
            }
        )
    }
}
