//
// Copyright © 2026 Stream.io Inc. All rights reserved.
//

import AVFoundation
import Combine
import Foundation

/// Keeps one `AVPlayer` per call, so every renderer and control of the same
/// HLS call share it.
actor HLSPlayerStore {

    private let makePlayer: @Sendable (URL) -> AVPlayer
    private var entries: [String: Entry] = [:]

    /// - Parameter makePlayer: Builds the player for a playlist URL.
    ///   The closure runs on the main actor.
    init(
        makePlayer: @escaping @Sendable (URL) -> AVPlayer = { url in
            AVPlayer(playerItem: AVPlayerItem(url: url))
        }
    ) {
        self.makePlayer = makePlayer
    }

    // MARK: - Players

    /// The player of the call, if it has one.
    func player(for call: Call) -> AVPlayer? {
        entries[call.cId]?.player
    }

    /// Takes a claim on the player of the call. The first claim creates the
    /// player and starts it. A claim for another playlist URL replaces the
    /// player of the call.
    /// - Parameters:
    ///   - claimId: Identifies the claim. Give it back to ``release``.
    ///   - playbackType: The playback type to act on. The player is freed
    ///     again when the state of the call holds `.webRTC` after the claim.
    /// - Returns: `nil` unless `playbackType` is HLS.
    func acquire(
        for call: Call,
        claimId: UUID,
        playbackType: PlaybackType
    ) async -> AVPlayer? {
        guard case let .hls(url) = playbackType else {
            return nil
        }

        let callId = call.cId
        if let entry = entries[callId] {
            if entry.url == url {
                entry.claimIds.insert(claimId)
                return entry.player
            }
            await free(callId: callId)
        }

        // One hop creates the player and its observers.
        let (player, observer, resumeObserver, audioObserver) = await MainActor.run {
            let player = makePlayer(url)
            // A new player has rate 0. Nothing else starts it.
            player.play()
            // A change to WebRTC means the player has no use. The
            // subscription sees the value in state too.
            let observer = call.state
                .$playbackType
                .filter { $0 == .webRTC }
                .sink { [weak self] _ in
                    Task { await self?.free(callId: callId, player: player) }
                }
            return (
                player,
                observer,
                makeResumeObserver(callId: callId),
                makeAudioOutputObserver(call: call, player: player)
            )
        }
        // Another claim stored its player while this one was on the main
        // actor. Nothing suspends from this check to the insert.
        if entries[callId] != nil {
            observer.cancel()
            resumeObserver.cancel()
            audioObserver.cancel()
            await discard(player)
            return await acquire(for: call, claimId: claimId, playbackType: playbackType)
        }

        entries[callId] = Entry(
            url: url,
            player: player,
            claimIds: [claimId],
            playbackTypeObserver: observer,
            resumeObserver: resumeObserver,
            audioOutputObserver: audioObserver
        )
        // The change to WebRTC can come before the entry exists.
        if await MainActor.run(body: { call.state.playbackType }) == .webRTC {
            await free(callId: callId, player: player)
        }
        return player
    }

    /// Records that the user paused or resumed the player of the call.
    /// - Returns: The player, or `nil` when the call has none.
    func setPausedByUser(_ paused: Bool, for call: Call) -> AVPlayer? {
        let entry = entries[call.cId]
        entry?.isPausedByUser.wrappedValue = paused
        return entry?.player
    }

    /// Gives a claim back. The player stops when no claim is left.
    ///
    /// Wait for the `acquire` of the claim first. A claim that is still
    /// being acquired is not known yet, so releasing it does nothing.
    func release(claimId: UUID, for call: Call) async {
        let callId = call.cId
        guard let entry = entries[callId], entry.claimIds.remove(claimId) != nil else {
            return
        }
        if entry.claimIds.isEmpty {
            await free(callId: callId)
        }
    }

    // MARK: - Private Helpers

    /// Mutes the player while the audio output of the call is off. The
    /// subscription sees the value in state too, so a new player starts
    /// with it.
    @MainActor
    private func makeAudioOutputObserver(
        call: Call,
        player: AVPlayer
    ) -> AnyCancellable {
        call.state
            .$callSettings
            .map(\.audioOutputOn)
            .removeDuplicates()
            .sink { [weak player] in player?.isMuted = !$0 }
    }

    /// iOS can pause a player without a user action, for example when the app
    /// goes to the background. Nothing resumes it afterwards, so resume it
    /// when the app becomes active, or an audio interruption ends with
    /// `.shouldResume`.
    @MainActor
    private func makeResumeObserver(callId: String) -> AnyCancellable {
        let appBecameActive = InjectedValues[\.applicationStateAdapter]
            .statePublisher
            .removeDuplicates()
            // Skip the value already in state.
            .dropFirst()
            .filter { $0 == .foreground }
            .map { _ in () }
        let interruptionEnded = NotificationCenter.default
            .publisher(for: AVAudioSession.interruptionNotification)
            .filter {
                let userInfo = $0.userInfo
                let type = (userInfo?[AVAudioSessionInterruptionTypeKey] as? UInt)
                    .flatMap(AVAudioSession.InterruptionType.init)
                let options = (userInfo?[AVAudioSessionInterruptionOptionKey] as? UInt)
                    .map(AVAudioSession.InterruptionOptions.init)
                return type == .ended && options?.contains(.shouldResume) == true
            }
            .map { _ in () }
        return appBecameActive
            .merge(with: interruptionEnded)
            .sink { [weak self] in
                Task { await self?.resumeIfPausedBySystem(callId: callId) }
            }
    }

    private func resumeIfPausedBySystem(callId: String) async {
        guard let entry = entries[callId] else { return }
        let player = entry.player
        let isPausedByUser = entry.isPausedByUser
        await MainActor.run {
            guard !isPausedByUser.wrappedValue, player.rate == 0 else { return }
            player.resumeFromLiveEdge()
        }
    }

    /// Frees the entry of the call. With `player`, only when that player
    /// still is the entry's, so a late signal cannot free a newer player.
    private func free(callId: String, player expected: AVPlayer? = nil) async {
        guard let entry = entries[callId] else { return }
        if let expected, entry.player !== expected { return }
        entries.removeValue(forKey: callId)
        entry.resumeObserver.cancel()
        entry.audioOutputObserver.cancel()
        await discard(entry.player)
    }

    private func discard(_ player: AVPlayer) async {
        await MainActor.run {
            player.pause()
            player.replaceCurrentItem(with: nil)
        }
    }
}

extension HLSPlayerStore: InjectionKey {
    nonisolated(unsafe) static var currentValue: HLSPlayerStore = .init()
}

extension InjectedValues {
    /// The player store the HLS views use.
    var hlsPlayerStore: HLSPlayerStore {
        get { Self[HLSPlayerStore.self] }
        set { Self[HLSPlayerStore.self] = newValue }
    }
}
