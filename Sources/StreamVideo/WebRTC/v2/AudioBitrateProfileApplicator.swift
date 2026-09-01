//
// Copyright © 2026 Stream.io Inc. All rights reserved.
//

import Foundation

/// Applies an ``AudioBitrateProfile`` to the session, ADM, software
/// processing, and published bitrate.
///
/// Owns the live audio-filter policy so music can stash filters without
/// `Call` knowing what music is.
final class AudioBitrateProfileApplicator: @unchecked Sendable {

    private let audioSession: CallAudioSession
    private let audioProcessingModule: AudioProcessingModule
    private let audioDeviceModule: () -> AudioDeviceModule
    private let lock = NSLock()
    private var profile: AudioBitrateProfile = .voiceStandard
    private var restoredAudioFilter: AudioFilter?

    init(
        audioSession: CallAudioSession,
        audioProcessingModule: AudioProcessingModule,
        audioDeviceModule: @escaping () -> AudioDeviceModule
    ) {
        self.audioSession = audioSession
        self.audioProcessingModule = audioProcessingModule
        self.audioDeviceModule = audioDeviceModule
    }

    func apply(
        profile: AudioBitrateProfile,
        callSettings: CallSettings,
        ownCapabilities: Set<OwnCapability>,
        publishOptions: PublishOptions,
        publisher: RTCPeerConnectionCoordinator?
    ) async throws {
        withLock { self.profile = profile }

        try await audioSession.setAudioBitrateProfile(
            profile,
            callSettings: callSettings,
            ownCapabilities: ownCapabilities
        )

        withLock {
            audioDeviceModule().setAudioBitrateProfile(
                profile,
                restorePlayout: callSettings.audioOutputOn && publisher != nil
            )
            applySoftwareProcessing(enabled: !profile.isMusic)
            applyAudioFilterPolicy()
        }

        let bitrate = publishOptions.audio.first?.bitrate(for: profile)
            ?? profile.defaultBitrate
        await publisher?.setAudioMaxBitrate(bitrate)
    }

    /// Writes the filter unless music is on, in which case it is stashed
    /// and applied when the profile returns to voice.
    func setAudioFilter(_ filter: AudioFilter?) {
        withLock {
            if profile.isMusic {
                restoredAudioFilter = filter
                return
            }
            restoredAudioFilter = nil
            audioProcessingModule.setAudioFilter(filter)
        }
    }

    /// Drops a stashed filter so leave cannot reinstall it on the shared
    /// processing module.
    func discardStashedAudioFilter() {
        withLock { restoredAudioFilter = nil }
        audioProcessingModule.setAudioFilter(nil)
    }

    private func withLock(_ body: () -> Void) {
        lock.lock()
        defer { lock.unlock() }
        body()
    }

    private func applySoftwareProcessing(enabled: Bool) {
        let config = audioProcessingModule.config
        config.isNoiseSuppressionEnabled = enabled
        config.isHighpassFilterEnabled = enabled
        audioProcessingModule.config = config
    }

    private func applyAudioFilterPolicy() {
        if profile.isMusic {
            if restoredAudioFilter == nil {
                restoredAudioFilter = audioProcessingModule.activeAudioFilter
            }
            audioProcessingModule.setAudioFilter(nil)
        } else if let restoredAudioFilter {
            audioProcessingModule.setAudioFilter(restoredAudioFilter)
            self.restoredAudioFilter = nil
        }
    }
}
