//
// Copyright © 2026 Stream.io Inc. All rights reserved.
//

import Foundation

/// Why ``AudioBitrateProfileApplicator/apply`` is running.
///
/// ``setProfile`` and ``rebind`` share one apply function so reconnect
/// cannot silently skip bitrate on a new publisher. A naive
/// `profile == previous` early-return at the top of `apply` would do
/// that: music is still on, but `maxBitrateBps` never lands on the new
/// senders. ``rebind`` still skips Voice Processing when the profile did
/// not *cross* music; it re-asserts the session (VoiceChat vs `.default`)
/// and the live bitrate.
enum AudioBitrateApplyContext: Sendable {
    /// User or API changed the profile. No-op when the stored profile
    /// already matches so a second tap does not rebuild AVAudioSession.
    case setProfile
    /// New publisher after join or reconnect. Re-assert session (if this
    /// session is in or leaving music) and bitrate even when the enum
    /// did not change.
    case rebind
}

/// Applies an ``AudioBitrateProfile`` to the session, ADM, software
/// processing, and published bitrate.
///
/// Owns the live audio-filter policy so music and screenshare can
/// suppress filters without `Call` knowing about either. Default voice
/// is a no-op: join and leave do not touch session, ADM, APM, or bitrate
/// unless this session has applied a non-default profile.
final class AudioBitrateProfileApplicator: @unchecked Sendable {

    private struct AudioProcessingState {
        let isNoiseSuppressionEnabled: Bool
        let isHighpassFilterEnabled: Bool
    }

    private let audioSession: CallAudioSession
    private let audioProcessingModule: AudioProcessingModule
    private let audioDeviceModule: AudioDeviceModuleProvider
    private let transitionQueue = OperationQueue(maxConcurrentOperationCount: 1)
    private let lock = UnfairQueue()
    private var storedProfile: AudioBitrateProfile = .voiceStandard
    /// Last filter requested by `Call.setAudioFilter`. Live output is
    /// suppressed while music or screenshare is active.
    private var intendedFilter: AudioFilter?

    /// Filter `Call.setAudioFilter` last asked for, including while live
    /// output is suppressed.
    var requestedAudioFilter: AudioFilter? {
        lock.sync { intendedFilter }
    }

    private var isScreenShareActive = false
    private var restoredAudioProcessing: AudioProcessingState?

    /// - Parameters:
    ///   - audioSession: Call session used to leave or restore VoiceChat.
    ///   - audioProcessingModule: Software NS/HPF and live filter owner.
    ///   - audioDeviceModule: Lazy ADM lookup for Voice Processing.
    init(
        audioSession: CallAudioSession,
        audioProcessingModule: AudioProcessingModule,
        audioDeviceModule: @escaping AudioDeviceModuleProvider
    ) {
        self.audioSession = audioSession
        self.audioProcessingModule = audioProcessingModule
        self.audioDeviceModule = audioDeviceModule
    }

    /// Profile last committed after a successful apply. This is the single
    /// source of truth; ``WebRTCStateAdapter`` does not keep a copy so a
    /// failed apply cannot briefly publish the new value.
    var profile: AudioBitrateProfile {
        lock.sync { storedProfile }
    }

    /// Applies `profile` to session, ADM, software processing, and bitrate.
    ///
    /// Processing order is session (leave VoiceChat) → commit profile →
    /// ADM VP disable → APM/filter/bitrate. Profile is committed before
    /// ADM so ``setAudioFilter`` during the VP rebuild already sees music
    /// and will not install a live filter onto the graph being torn down.
    /// If VP disable throws, session and `storedProfile` roll back so the
    /// call is not left in VoiceChat-off / VP-on.
    ///
    /// - Parameters:
    ///   - profile: Requested capture/publish profile.
    ///   - context: ``setProfile`` no-ops when already applied;
    ///     ``rebind`` still stamps bitrate on a new publisher.
    func apply(
        profile: AudioBitrateProfile,
        callSettings: CallSettings,
        ownCapabilities: Set<OwnCapability>,
        publisher: RTCPeerConnectionCoordinator?,
        context: AudioBitrateApplyContext
    ) async throws {
        try await transitionQueue.addSynchronousTaskOperation { [self] in
            try await applySerially(
                profile: profile,
                callSettings: callSettings,
                ownCapabilities: ownCapabilities,
                publisher: publisher,
                context: context
            )
        }
    }

    private func applySerially(
        profile: AudioBitrateProfile,
        callSettings: CallSettings,
        ownCapabilities: Set<OwnCapability>,
        publisher: RTCPeerConnectionCoordinator?,
        context: AudioBitrateApplyContext
    ) async throws {
        let previous = lock.sync { storedProfile }
        // Duplicate user/API sets must not rebuild the session. Rebind
        // of the same profile still runs so a new publisher gets bitrate.
        if context == .setProfile, profile == previous {
            return
        }

        if profile.isMusic || previous.isMusic {
            try await applyProcessing(
                profile: profile,
                previous: previous,
                callSettings: callSettings,
                ownCapabilities: ownCapabilities,
                publisher: publisher
            )
            return
        }
        guard profile != .voiceStandard || previous != .voiceStandard else {
            return
        }
        lock.sync { storedProfile = profile }
        await publisher?.setAudioMaxBitrate(for: profile)
    }

    /// Records the requested filter and writes it unless music or
    /// screenshare is suppressing live processing.
    func setAudioFilter(_ filter: AudioFilter?) {
        lock.sync {
            intendedFilter = filter
            applyLiveFilter()
        }
    }

    /// Screenshare start/stop suspend the live filter without replacing
    /// the intended (or music-stashed) filter.
    func setScreenShareActive(_ isActive: Bool) {
        lock.sync {
            isScreenShareActive = isActive
            applyLiveFilter()
        }
    }

    /// Drops a stashed filter so leave cannot reinstall it on the shared
    /// processing module. Does not write the module; never-music calls
    /// must not clear an unrelated filter.
    func discardStashedAudioFilter() {
        lock.sync {
            intendedFilter = nil
            isScreenShareActive = false
        }
    }

    /// Teardown to ``.voiceStandard`` that cannot restick music.
    ///
    /// Never-music leave is a no-op for session, ADM, and APM. After
    /// music, NS/HPF are restored even if ADM throws; the session is
    /// written with ``CallAudioSession/commitAudioBitrateProfile`` so a
    /// failed apply cannot put music back.
    func resetToVoice(
        callSettings: CallSettings,
        ownCapabilities: Set<OwnCapability>
    ) async {
        try? await transitionQueue.addSynchronousTaskOperation { [self] in
            await resetToVoiceSerially(
                callSettings: callSettings,
                ownCapabilities: ownCapabilities
            )
        }
    }

    private func resetToVoiceSerially(
        callSettings: CallSettings,
        ownCapabilities: Set<OwnCapability>
    ) async {
        let previous = lock.sync { storedProfile }
        if previous == .voiceStandard {
            return
        }

        lock.sync {
            storedProfile = .voiceStandard
            if previous.isMusic {
                restoreAudioProcessing()
                applyLiveFilter()
            }
        }

        guard previous.isMusic else { return }

        try? await audioSession.commitAudioBitrateProfile(
            .voiceStandard,
            callSettings: callSettings,
            ownCapabilities: ownCapabilities
        )
        _ = try? audioDeviceModule()
            .setMusicCaptureEnabled(false)
    }

    /// Session → commit profile → ADM VP → APM/filter/bitrate.
    /// Rolls session and stored profile back if VP disable throws.
    private func applyProcessing(
        profile: AudioBitrateProfile,
        previous: AudioBitrateProfile,
        callSettings: CallSettings,
        ownCapabilities: Set<OwnCapability>,
        publisher: RTCPeerConnectionCoordinator?
    ) async throws {
        // Session first: Apple will not actually disable VP until the
        // category/mode has left VoiceChat. Session rolls itself back if
        // this throws, so `storedProfile` stays `previous`.
        try await audioSession.setAudioBitrateProfile(
            profile,
            callSettings: callSettings,
            ownCapabilities: ownCapabilities
        )
        lock.sync { storedProfile = profile }
        do {
            try audioDeviceModule()
                .setMusicCaptureEnabled(profile.isMusic)
        } catch {
            // VP disable failed after VoiceChat was already left. Put the
            // session and stored profile back so callers see a throw, not
            // a half-applied music mode. Do not restick music if that
            // voice apply fails.
            try? await audioSession.commitAudioBitrateProfile(
                previous,
                callSettings: callSettings,
                ownCapabilities: ownCapabilities
            )
            lock.sync {
                storedProfile = previous
                // Profile is voice again; reinstall the intended filter if
                // a setAudioFilter raced during the failed VP rebuild.
                applyLiveFilter()
            }
            throw error
        }

        lock.sync {
            if profile.isMusic {
                let config = audioProcessingModule.config
                if restoredAudioProcessing == nil {
                    restoredAudioProcessing = .init(
                        isNoiseSuppressionEnabled: config.isNoiseSuppressionEnabled,
                        isHighpassFilterEnabled: config.isHighpassFilterEnabled
                    )
                }
                config.isNoiseSuppressionEnabled = false
                config.isHighpassFilterEnabled = false
                audioProcessingModule.config = config
            } else {
                restoreAudioProcessing()
            }
            applyLiveFilter()
        }
        await publisher?.setAudioMaxBitrate(for: profile)
    }

    /// Caller must already hold `lock`. Reads `storedProfile` directly so
    /// we do not re-enter ``UnfairQueue``.
    private func applyLiveFilter() {
        if storedProfile.isMusic || isScreenShareActive {
            audioProcessingModule.setAudioFilter(nil)
        } else {
            audioProcessingModule.setAudioFilter(intendedFilter)
        }
    }

    private func restoreAudioProcessing() {
        guard let restoredAudioProcessing else { return }
        let config = audioProcessingModule.config
        config.isNoiseSuppressionEnabled = restoredAudioProcessing
            .isNoiseSuppressionEnabled
        config.isHighpassFilterEnabled = restoredAudioProcessing
            .isHighpassFilterEnabled
        audioProcessingModule.config = config
        self.restoredAudioProcessing = nil
    }
}
