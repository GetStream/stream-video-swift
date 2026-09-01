//
// Copyright © 2026 Stream.io Inc. All rights reserved.
//

import Foundation

/// Applies an ``AudioBitrateProfile`` to the session, ADM, software
/// processing, and published bitrate.
///
/// Owns the live audio-filter policy so music and screenshare can
/// suppress filters without `Call` knowing about either. Default voice
/// is a no-op: join and leave do not touch session, ADM, APM, or bitrate
/// unless this session has applied music.
final class AudioBitrateProfileApplicator: @unchecked Sendable {

    private let audioSession: CallAudioSession
    private let audioProcessingModule: AudioProcessingModule
    private let audioDeviceModule: () -> AudioDeviceModule
    private let lock = NSLock()
    private var profile: AudioBitrateProfile = .voiceStandard
    /// Last filter requested by `Call.setAudioFilter`. Live output is
    /// suppressed while music or screenshare is active.
    private var intendedFilter: AudioFilter?
    private var isScreenShareActive = false
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
            applyLiveFilter()
            return consumeBitrate(
                profile: profile,
                publishOptions: publishOptions
            )
        }

        if let bitrateToApply {
            await publisher?.setAudioMaxBitrate(bitrateToApply)
        }
    }

    /// Records the requested filter and writes it unless music or
    /// screenshare is suppressing live processing.
    func setAudioFilter(_ filter: AudioFilter?) {
        withLock {
            intendedFilter = filter
            applyLiveFilter()
        }
    }

    /// Screenshare start/stop suspend the live filter without replacing
    /// the intended (or music-stashed) filter.
    func setScreenShareActive(_ isActive: Bool) {
        withLock {
            isScreenShareActive = isActive
            applyLiveFilter()
        }
    }

    /// Drops a stashed filter so leave cannot reinstall it on the shared
    /// processing module. Does not write the module; never-music calls
    /// must not clear an unrelated filter.
    func discardStashedAudioFilter() {
        withLock {
            intendedFilter = nil
            isScreenShareActive = false
        }
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

    private func applyLiveFilter() {
        if profile.isMusic || isScreenShareActive {
            if intendedFilter == nil,
               let live = audioProcessingModule.activeAudioFilter {
                intendedFilter = live
            }
            audioProcessingModule.setAudioFilter(nil)
        } else {
            audioProcessingModule.setAudioFilter(intendedFilter)
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

enum CallAudioFilterPolicyKey: InjectionKey {
    nonisolated(unsafe) static var currentValue: AudioBitrateProfileApplicator?
}

extension InjectedValues {
    var callAudioFilterPolicy: AudioBitrateProfileApplicator? {
        get { Self[CallAudioFilterPolicyKey.self] }
        set { Self[CallAudioFilterPolicyKey.self] = newValue }
    }
}
