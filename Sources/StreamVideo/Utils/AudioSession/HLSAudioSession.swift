//
// Copyright © 2026 Stream.io Inc. All rights reserved.
//

import AVFoundation
import Foundation

/// Owns the shared audio session while a call plays HLS.
///
/// HLS playback has no WebRTC audio, so the session is configured for media
/// playback instead of a call.
actor HLSAudioSession {

    typealias Dispatch = @Sendable (
        [RTCAudioStore.Namespace.Action]
    ) async throws -> Void

    @Injected(\.audioStore) private var audioStore

    /// Stable identifier used to claim ownership of the shared audio state.
    nonisolated let identifier = String(
        UUID().uuidString.replacingOccurrences(of: "-", with: "").prefix(8)
    )

    private let dispatchOverride: Dispatch?

    /// Whether this session claimed the shared audio state and has not yet
    /// released it. Set before the first await, so a release that runs while
    /// the activation is in flight still undoes it.
    private var isActive = false

    /// - Parameter dispatch: Sends the actions to the audio store. Pass a
    ///   replacement to observe or fail the dispatches.
    init(dispatch: Dispatch? = nil) {
        dispatchOverride = dispatch
    }

    /// Configures the session for playback and activates it. A repeated
    /// call is a no-op.
    func activate() async throws {
        try Task.checkCancellation()
        guard !isActive else { return }
        isActive = true

        // The claim applies only to an unowned store, so an active call keeps
        // its session. The rest applies only while this session owns it.
        // `.playback` plays through the speaker, unlike the voice-chat mode
        // that `CallAudioSession` leaves behind when the store is unowned.
        // The options are explicit: the call ones are invalid for playback.
        let actions: [RTCAudioStore.Namespace.Action] = [
            .conditioned(
                .activeSessionIdentifier(""),
                action: .setActiveSessionIdentifier(identifier)
            ),
            .conditioned(
                owned,
                action: .avAudioSession(
                    .setCategoryAndModeAndCategoryOptions(
                        .playback,
                        mode: .moviePlayback,
                        categoryOptions: []
                    )
                )
            ),
            .conditioned(owned, action: .setActive(true))
        ]

        do {
            try await dispatch(actions)
        } catch {
            await deactivate()
            throw error
        }
    }

    /// Releases the session. A call without a matching activation is a no-op.
    ///
    /// Every step applies only while this session still owns the store, so a
    /// later owner keeps its configuration. Each step runs in its own
    /// dispatch, because a failing action stops its batch: the release must
    /// run whatever happens to the steps before it.
    func deactivate() async {
        guard isActive else { return }
        isActive = false

        await attempt(.conditioned(owned, action: .setActive(false)))
        // A call created while HLS played has no bootstrap of its own left to
        // run, so the call configuration comes back before the release.
        await attempt(.conditioned(owned, action: .callBootstrapConfiguration))
        await attempt(.conditioned(owned, action: .setActiveSessionIdentifier("")))
    }

    // MARK: - Private Helpers

    private var owned: RTCAudioStore.Namespace.Action.Condition {
        .activeSessionIdentifier(identifier)
    }

    private func dispatch(_ actions: [RTCAudioStore.Namespace.Action]) async throws {
        if let dispatchOverride {
            try await dispatchOverride(actions)
        } else {
            try await audioStore.dispatch(actions).result()
        }
    }

    private func attempt(_ action: RTCAudioStore.Namespace.Action) async {
        do {
            try await dispatch([action])
        } catch {
            log.error(
                "Failed to release the HLS audio session step \(action): \(error).",
                subsystems: .audioSession
            )
        }
    }
}
