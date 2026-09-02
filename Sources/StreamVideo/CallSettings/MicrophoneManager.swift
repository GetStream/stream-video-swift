//
// Copyright © 2026 Stream.io Inc. All rights reserved.
//

import Combine
import Foundation

/// Handles the microphone state during a call.
public final class MicrophoneManager: ObservableObject, CallSettingsManager, @unchecked Sendable {
    
    internal let callController: CallController
    /// The status of the microphone.
    @Published public internal(set) var status: CallSettingsStatus
    /// The in-call audio capture/publish profile.
    @Published public internal(set) var audioBitrateProfile: AudioBitrateProfile = .voiceStandard
    let state = CallSettingsState()
    
    init(callController: CallController, initialStatus: CallSettingsStatus) {
        self.callController = callController
        status = initialStatus
    }
    
    /// Toggles the microphone state.
    public func toggle(
        file: StaticString = #file,
        function: StaticString = #function,
        line: UInt = #line
    ) async throws {
        try await updateAudioStatus(
            status.next,
            file: file,
            function: function,
            line: line
        )
    }
    
    /// Enables the microphone.
    public func enable(
        file: StaticString = #file,
        function: StaticString = #function,
        line: UInt = #line
    ) async throws {
        try await updateAudioStatus(
            .enabled,
            file: file,
            function: function,
            line: line
        )
    }
    
    /// Disables the microphone.
    public func disable(
        file: StaticString = #file,
        function: StaticString = #function,
        line: UInt = #line
    ) async throws {
        try await updateAudioStatus(
            .disabled,
            file: file,
            function: function,
            line: line
        )
    }

    /// Sets the in-call audio bitrate/processing profile.
    ///
    /// Allowed after join. Requires dashboard `hifi_audio_enabled`.
    /// Same-profile calls return here so the applicator does not rebuild
    /// the session; reconnect uses ``AudioBitrateApplyContext/rebind``
    /// instead of this API.
    public func setAudioBitrateProfile(_ profile: AudioBitrateProfile) async throws {
        guard profile != audioBitrateProfile else { return }
        try await callController.setAudioBitrateProfile(profile)
        await MainActor.run { audioBitrateProfile = profile }
    }

    /// Resets the published profile on leave without touching WebRTC.
    ///
    /// ``Call.microphone`` outlives the peer connection. Leave must
    /// clear the cached value so a later music set is not a no-op.
    func resetAudioBitrateProfile() async {
        await MainActor.run { audioBitrateProfile = .voiceStandard }
    }
    
    // MARK: - private
    
    private func updateAudioStatus(
        _ status: CallSettingsStatus,
        file: StaticString = #file,
        function: StaticString = #function,
        line: UInt = #line
    ) async throws {
        try await updateState(
            newState: status.boolValue,
            current: self.status.boolValue,
            action: { [unowned self] state in
                try await callController.changeAudioState(
                    isEnabled: state,
                    file: file,
                    function: function,
                    line: line
                )
            },
            onUpdate: { _ in
                // We don't optimistically update the status as it will be
                // updated only when the CallSettings changed based on the
                // requirements:
                // 1) System permissions granted
                // 2) OwnCapabilities support requested change
            }
        )
    }
}
