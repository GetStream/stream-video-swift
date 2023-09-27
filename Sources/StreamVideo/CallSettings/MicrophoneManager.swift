//
// Copyright © 2023 Stream.io Inc. All rights reserved.
//

import Foundation

/// Handles the microphone state during a call.
public final class MicrophoneManager: ObservableObject, CallSettingsManager, @unchecked Sendable {
    
    internal let callController: CallController
    /// The status of the microphone.
    @Published public internal(set) var status: CallSettingsStatus
    let state = CallSettingsState()

    init(callController: CallController, initialStatus: CallSettingsStatus) {
        self.callController = callController
        self.status = initialStatus

        MemoryLeakDetector.track(self)
    }

    /// Toggles the microphone state.
    public func toggle() async throws {
        try await updateAudioStatus(status.next)
    }

    /// Enables the microphone.
    public func enable() async throws {
        try await updateAudioStatus(.enabled)
    }

    /// Disables the microphone.
    public func disable() async throws {
        try await updateAudioStatus(.disabled)
    }
    
    // MARK: - private
    
    private func updateAudioStatus(_ status: CallSettingsStatus) async throws {
        try await updateState(
            newState: status.boolValue,
            current: self.status.boolValue,
            action: { [unowned self] state in
                try await callController.changeAudioState(isEnabled: state)
            },
            onUpdate: { value in
                self.status = status
            }
        )
    }
}
