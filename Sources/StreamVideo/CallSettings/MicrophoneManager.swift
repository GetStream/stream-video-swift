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
    private let audioBitrateProfileQueue = OperationQueue(maxConcurrentOperationCount: 1)
    
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

    /// Sets the in-call audio capture and publish profile.
    ///
    /// Allowed after join. Hi-fi profiles require dashboard
    /// `hifi_audio_enabled`; ``AudioBitrateProfile/voiceStandard`` does not.
    /// Published as ``audioBitrateProfile``. Same-profile calls are a
    /// no-op. The value survives reconnect. Leave resets it to
    /// ``AudioBitrateProfile/voiceStandard`` so a later music set on a
    /// cached `Call` is not a no-op. Reconnect re-applies bitrate on the
    /// new publisher.
    ///
    /// - Parameter profile: Voice or music capture profile.
    /// - Throws: `ClientError` when the call is missing, hi-fi is off on
    ///   the dashboard, or Voice Processing cannot be applied.
    public func setAudioBitrateProfile(_ profile: AudioBitrateProfile) async throws {
        try await audioBitrateProfileQueue.addSynchronousTaskOperation { [self] in
            let current = await MainActor.run { audioBitrateProfile }
            guard profile != current else { return }
            try await callController.setAudioBitrateProfile(profile)
            await MainActor.run { audioBitrateProfile = profile }
        }
    }

    /// Resets the published profile on leave without touching WebRTC.
    ///
    /// ``Call.microphone`` outlives the peer connection. Leave must
    /// clear the cached value so a later music set is not a no-op.
    func resetAudioBitrateProfile() async {
        try? await audioBitrateProfileQueue.addSynchronousTaskOperation { [self] in
            await MainActor.run { audioBitrateProfile = .voiceStandard }
        }
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
