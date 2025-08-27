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

    /// Enables or disables High-Fidelity (HiFi) audio mode for enhanced
    /// audio quality during music streaming or high-quality voice calls.
    ///
    /// When HiFi mode is enabled, audio processing features such as echo
    /// cancellation, noise suppression, and automatic gain control are
    /// disabled to preserve the original audio quality. This mode is ideal
    /// for music streaming but may cause echo issues when using speakers.
    ///
    /// - Parameter isEnabled: A Boolean value indicating whether HiFi mode
    ///   should be enabled (`true`) or disabled (`false`).
    ///
    /// - Note: HiFi mode is opt-in only. Users should be aware that
    ///   disabling audio processing may lead to echo feedback in speaker
    ///   mode or environments with background noise.
    ///
    /// - Important: This setting affects only the audio track constraints
    ///   and does not impact video or screen sharing quality.
    public func setHiFiEnabled(_ isEnabled: Bool) async {
        await callController.setHiFiEnabled(isEnabled)
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
