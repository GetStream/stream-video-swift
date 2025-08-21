//
// Copyright © 2025 Stream.io Inc. All rights reserved.
//

import Combine
import Foundation

/// Handles the microphone state during a call.
public final class MicrophoneManager: ObservableObject, CallSettingsManager, @unchecked Sendable {
    
    internal let callController: CallController
    /// The status of the microphone.
    @Published public internal(set) var status: CallSettingsStatus
    let state = CallSettingsState()
    
    /// Whether HiFi audio mode is enabled (disables audio processing)
    @Published public private(set) var isHiFiEnabled: Bool = false

    init(callController: CallController, initialStatus: CallSettingsStatus) {
        self.callController = callController
        status = initialStatus
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
    
    /// Sets HiFi audio mode which disables audio processing for better quality
    /// - Parameter enabled: Whether to enable HiFi mode
    public func setHiFiEnabled(_ enabled: Bool) async throws {
        try await callController.setHiFiAudioEnabled(enabled)
        isHiFiEnabled = enabled
    }
    
    // MARK: - private
    
    private func updateAudioStatus(_ status: CallSettingsStatus) async throws {
        try await updateState(
            newState: status.boolValue,
            current: self.status.boolValue,
            action: { [unowned self] state in
                try await callController.changeAudioState(isEnabled: state)
            },
            onUpdate: { _ in
                self.status = status
            }
        )
    }
}
