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

    /// Starts the identifier of every HLS session, so a call can tell that
    /// an HLS session owns the shared audio state.
    nonisolated static let identifierPrefix = "hls-"

    /// Stable identifier used to claim ownership of the shared audio state.
    nonisolated let identifier = identifierPrefix + String(
        UUID().uuidString.replacingOccurrences(of: "-", with: "").prefix(4)
    )

    private let dispatchOverride: Dispatch?

    /// Whether this session claimed the shared audio state and has not yet
    /// released it. Set before the first await, so a release that runs while
    /// the activation is in flight still undoes it.
    private var isActive = false

    /// - Parameter dispatch: Sends the actions to the audio store. Pass a
    ///   replacement to observe or fail the dispatches. The store has no
    ///   other way to fail a release step, as `RTCAudioSession` has no
    ///   public initializer to subclass.
    init(dispatch: Dispatch? = nil) {
        dispatchOverride = dispatch
    }

    /// Configures the session for playback and activates it. A repeated
    /// call is a no-op.
    func activate() async throws {
        try Task.checkCancellation()
        guard !isActive else { return }
        isActive = true

        // Claim unconditionally, as WebRTC calls do. The rest applies only
        // while this session owns the store. The call options do not fit
        // playback, so the options are explicit.
        let actions: [RTCAudioStore.Namespace.Action] = [
            .setActiveSessionIdentifier(identifier),
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
    /// later owner keeps its configuration. `StoreTask` stops a batch at the
    /// first thrown action, so each step is its own dispatch.
    func deactivate() async {
        guard isActive else { return }
        isActive = false

        await attempt(.conditioned(owned, action: .setActive(false)))
        // CallKit activates a call with the category it finds. A call that
        // starts after HLS needs the call configuration in place, so it
        // comes back before the release.
        await attempt(
            .conditioned(
                owned,
                action: .avAudioSession(
                    .setCategoryAndModeAndCategoryOptions(
                        .playAndRecord,
                        mode: .voiceChat,
                        categoryOptions: [.allowBluetoothHFP, .allowBluetoothA2DP]
                    )
                )
            )
        )
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
