//
// Copyright © 2026 Stream.io Inc. All rights reserved.
//

import Foundation

/// Applies an ``AudioBitrateProfile`` to the session, ADM, software
/// processing, and published bitrate.
///
/// Owns the live audio-filter policy so music can stash filters without
/// `Call` knowing what music is. Default voice is a no-op: join and leave
/// do not touch session, ADM, APM, or bitrate unless this session has
/// applied music.
final class AudioBitrateProfileApplicator: @unchecked Sendable {

    private let audioSession: CallAudioSession
    private let audioProcessingModule: AudioProcessingModule
    private let audioDeviceModule: () -> AudioDeviceModule
    private let lock = NSLock()
    private var profile: AudioBitrateProfile = .voiceStandard
    private var restoredAudioFilter: AudioFilter?
    /// Bitrate in force before music; `0` means encodings had no cap.
    private var restoredBitrate: Int?

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
        let previous = withLock { self.profile }
        guard profile.isMusic || previous.isMusic else {
            return
        }

        try await audioSession.setAudioBitrateProfile(
            profile,
            callSettings: callSettings,
            ownCapabilities: ownCapabilities
        )

        let bitrateToApply: Int? = withLock {
            self.profile = profile
            audioDeviceModule().setAudioBitrateProfile(
                profile,
                restorePlayout: callSettings.audioOutputOn && publisher != nil
            )
            applySoftwareProcessing(enabled: !profile.isMusic)
            applyAudioFilterPolicy()
            return consumeBitrate(
                profile: profile,
                publishOptions: publishOptions
            )
        }

        if let bitrateToApply {
            await publisher?.setAudioMaxBitrate(bitrateToApply)
        }
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
    /// processing module. Does not write the module; never-music calls
    /// must not clear an unrelated filter.
    func discardStashedAudioFilter() {
        withLock { restoredAudioFilter = nil }
    }

    private func withLock<T>(_ body: () -> T) -> T {
        lock.lock()
        defer { lock.unlock() }
        return body()
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

    /// Music sets the profile bitrate. Leaving music restores the pre-music
    /// cap (`0` clears `maxBitrateBps`).
    private func consumeBitrate(
        profile: AudioBitrateProfile,
        publishOptions: PublishOptions
    ) -> Int? {
        if profile.isMusic {
            if restoredBitrate == nil {
                restoredBitrate = publishOptions.audio.first?.bitrate ?? 0
            }
            return publishOptions.audio.first?.bitrate(for: profile)
                ?? profile.defaultBitrate
        }
        if let restoredBitrate {
            self.restoredBitrate = nil
            return restoredBitrate
        }
        return nil
    }
}
