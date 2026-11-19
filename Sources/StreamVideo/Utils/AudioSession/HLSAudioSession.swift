//
// Copyright © 2026 Stream.io Inc. All rights reserved.
//

import AVFoundation
import Combine
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

    /// Becomes `true` when another session takes the shared audio state
    /// from this one, and replays its value to late subscribers.
    nonisolated var ownershipLost: AnyPublisher<Bool, Never> {
        ownershipLostSubject.eraseToAnyPublisher()
    }

    private nonisolated let ownershipLostSubject = CurrentValueSubject<Bool, Never>(false)
    private let dispatchOverride: Dispatch?

    /// Whether this session claimed the shared audio state and has not yet
    /// released it. Set before the first await, so a release that runs while
    /// the activation is in flight still undoes it.
    private var isActive = false
    private var ownershipObserver: AnyCancellable?

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
        ownershipLostSubject.send(false)

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
            // Subscribe before the claim. A loss during the claim still
            // reaches the subject. A claim that never owns the store does not.
            observeOwnership()
            try await dispatch(actions)
        } catch {
            await deactivate()
            throw error
        }
        if !ownershipLostSubject.value,
           audioStore.state.activeSessionIdentifier != identifier {
            ownershipObserver = nil
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
        ownershipObserver = nil

        await attempt(.conditioned(owned, action: .setActive(false)))
        // A call created while HLS played has no bootstrap of its own left to
        // run, so the call configuration comes back before the release.
        await attempt(.conditioned(owned, action: .callBootstrapConfiguration))
        await attempt(.conditioned(owned, action: .setActiveSessionIdentifier("")))
    }

    // MARK: - Private Helpers

    /// Reports a loss only after this session has owned the store. The
    /// current value is replayed, so a loss that lands before the claim
    /// returns is still reported.
    private func observeOwnership() {
        guard isActive, ownershipObserver == nil else { return }
        let identifier = identifier
        let subject = ownershipLostSubject
        let ownership = Ownership()
        ownershipObserver = audioStore
            .publisher(\.activeSessionIdentifier)
            .removeDuplicates()
            .sink { current in
                if current == identifier {
                    ownership.didOwn = true
                    return
                }
                if ownership.didOwn, !current.isEmpty {
                    subject.send(true)
                }
            }
    }

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

/// Records whether this session has seen its own identifier. The store
/// publisher delivers values off the actor.
private final class Ownership: @unchecked Sendable {
    var didOwn = false
}
